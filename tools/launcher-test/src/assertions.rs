use crate::schema::*;

pub fn assert_expectation(state: &LauncherVisualState, expect: &Expectation, last_interaction: Option<&LastInteraction>) -> Vec<String> {
    let mut failures: Vec<String> = Vec::new();

    if let Some(ref expected_query) = expect.query {
        if state.query != *expected_query {
            failures.push(format!(
                "query mismatch: expected '{}', got '{}'",
                expected_query, state.query
            ));
        }
    }

    if let Some(true) = expect.exactly_one_selected {
        let selected_count = state.rows.iter().filter(|r| r.selected).count();
        if selected_count != 1 {
            failures.push(format!(
                "exactlyOneSelected: expected 1 selected row, found {}",
                selected_count
            ));
        }
    }

    if let Some(ref matcher) = expect.selected {
        let selected_rows: Vec<&VisualRow> = state.rows.iter().filter(|r| r.selected).collect();
        match selected_rows.len() {
            0 => failures.push("selected: no row is currently selected".to_string()),
            1 => {
                let row = selected_rows[0];
                row_match_failures(row, matcher, "selected", &mut failures);
            }
            n => {
                failures.push(format!("selected: {} rows are selected, expected exactly 1", n));
            }
        }
    }

    if let Some(ref matchers) = expect.expanded {
        for matcher in matchers {
            let matched: Vec<&VisualRow> = state.rows.iter()
                .filter(|r| r.expanded && row_matches_logical(r, matcher))
                .collect();
            if matched.is_empty() {
                failures.push(format!(
                    "expanded: no expanded row matched {:?}",
                    matcher
                ));
            }
        }
    }

    if let Some(ref matchers) = expect.absent {
        for matcher in matchers {
            let matched: Vec<&VisualRow> = state.rows.iter()
                .filter(|r| row_matches_logical(r, matcher))
                .collect();
            if !matched.is_empty() {
                failures.push(format!(
                    "absent: found row matching {:?} (should be absent)",
                    matcher
                ));
            }
        }
    }

    if let Some(ref invariants) = expect.invariants {
        for invariant in invariants {
            match invariant.as_str() {
                "exactly-one-selected" => {
                    let count = state.rows.iter().filter(|r| r.selected).count();
                    if count != 1 {
                        failures.push(format!(
                            "invariant 'exactly-one-selected': expected 1, found {}",
                            count
                        ));
                    }
                }
                "non-selectable-groups-not-selected" => {
                    for row in &state.rows {
                        if !row.selectable && row.selected {
                            failures.push(format!(
                                "invariant 'non-selectable-groups-not-selected': row '{}' is selected but not selectable",
                                row.title
                            ));
                        }
                    }
                }
                "children-can-be-selected-even-if-parent-cannot" => {
                    // This invariant is informational and doesn't fail
                }
                "no-hidden-selected-node" => {
                    for row in &state.rows {
                        if !row.visible && row.selected {
                            failures.push(format!(
                                "invariant 'no-hidden-selected-node': row '{}' is selected but not visible",
                                row.title
                            ));
                        }
                    }
                }
                other => {
                    failures.push(format!("unknown invariant: '{}'", other));
                }
            }
        }
    }

    if let Some(ref matcher) = expect.last_executed_action {
        match state.last_executed_action {
            Some(ref action) => {
                if let Some(ref title) = matcher.title {
                    if action.title.as_deref() != Some(title.as_str()) {
                        failures.push(format!(
                            "lastExecutedAction.title: expected '{}', got '{}'",
                            title,
                            action.title.as_deref().unwrap_or("")
                        ));
                    }
                }
                if let Some(ref key) = matcher.key {
                    if action.key.as_deref() != Some(key.as_str()) {
                        failures.push(format!(
                            "lastExecutedAction.key: expected '{}', got '{}'",
                            key,
                            action.key.as_deref().unwrap_or("")
                        ));
                    }
                }
            }
            None => {
                failures.push("lastExecutedAction: expected an executed action but none recorded".to_string());
            }
        }
    }

    if let Some(ref expected) = expect.last_interaction {
        match last_interaction {
            Some(actual) => {
                if actual.ok != expected.ok {
                    failures.push(format!(
                        "lastInteraction.ok: expected {}, got {}",
                        expected.ok, actual.ok
                    ));
                }
                if let Some(ref mode) = expected.mode {
                    if actual.mode.as_deref() != Some(mode.as_str()) {
                        failures.push(format!(
                            "lastInteraction.mode: expected '{}', got '{}'",
                            mode,
                            actual.mode.as_deref().unwrap_or("")
                        ));
                    }
                }
                if let Some(success) = expected.success {
                    if actual.success.unwrap_or(false) != success {
                        failures.push(format!(
                            "lastInteraction.success: expected {}, got {}",
                            success,
                            actual.success.unwrap_or(false)
                        ));
                    }
                }
                if let Some(ref reason) = expected.reason {
                    if actual.reason.as_deref() != Some(reason.as_str()) {
                        failures.push(format!(
                            "lastInteraction.reason: expected '{}', got '{}'",
                            reason,
                            actual.reason.as_deref().unwrap_or("")
                        ));
                    }
                }
            }
            None => {
                failures.push("lastInteraction: expected interaction data but none recorded".to_string());
            }
        }
    }

    if let Some(ref rows_expect) = expect.rows {
        if let Some(expected_count) = rows_expect.count {
            if state.rows.len() != expected_count {
                failures.push(format!(
                    "rows.count: expected {}, got {}",
                    expected_count,
                    state.rows.len()
                ));
            }
        }

        if let Some(ref contains) = rows_expect.contains {
            for matcher in contains {
                let matched = state.rows.iter().any(|r| row_matches_logical(r, matcher));
                if !matched {
                    failures.push(format!(
                        "rows.contains: no row matched {:?}",
                        matcher
                    ));
                }
            }
        }

        if let Some(ref not_contains) = rows_expect.not_contains {
            for matcher in not_contains {
                let matched = state.rows.iter().any(|r| row_matches_logical(r, matcher));
                if matched {
                    failures.push(format!(
                        "rows.notContains: found row matching {:?}",
                        matcher
                    ));
                }
            }
        }

        if let Some(ref titles) = rows_expect.contains_title {
            for title in titles {
                let found = state.rows.iter().any(|r| r.title == *title);
                if !found {
                    failures.push(format!(
                        "rows.containsTitle: '{}' not found in rows",
                        title
                    ));
                }
            }
        }

        if let Some(ref titles) = rows_expect.not_contains_title {
            for title in titles {
                let found = state.rows.iter().any(|r| r.title == *title);
                if found {
                    failures.push(format!(
                        "rows.notContainsTitle: '{}' found in rows",
                        title
                    ));
                }
            }
        }

        if let Some(ref ordered) = rows_expect.contains_in_order {
            let row_titles: Vec<&str> = state.rows.iter().map(|r| r.title.as_str()).collect();
            let mut pos = 0;
            for title in ordered {
                let mut found = false;
                for j in pos..row_titles.len() {
                    if row_titles[j] == title.as_str() {
                        pos = j + 1;
                        found = true;
                        break;
                    }
                }
                if !found {
                    failures.push(format!(
                        "rows.containsInOrder: '{}' not found in order (after position {})",
                        title, pos
                    ));
                }
            }
        }

        if let Some(ref first_matcher) = rows_expect.first {
            if let Some(first) = state.rows.first() {
                row_match_failures(first, first_matcher, "rows.first", &mut failures);
            } else {
                failures.push("rows.first: expected a row but no rows found".to_string());
            }
        }

        if rows_expect.none_highlighted_except_selected.unwrap_or(false) {
            let selected_keys: Vec<&str> = state.rows.iter()
                .filter(|r| r.selected)
                .map(|r| r.key.as_str())
                .collect();
            for row in &state.rows {
                if row.highlighted && !selected_keys.contains(&row.key.as_str()) {
                    failures.push(format!(
                        "rows.noneHighlightedExceptSelected: row '{}' is highlighted but not selected",
                        row.title
                    ));
                }
            }
        }
    }

    failures
}

fn row_match_failures(row: &VisualRow, matcher: &RowMatcher, label: &str, failures: &mut Vec<String>) {
    if let Some(ref title) = matcher.title {
        if row.title != *title {
            failures.push(format!(
                "{}.title: expected '{}', got '{}'",
                label, title, row.title
            ));
        }
    }
    if let Some(ref backend) = matcher.backend {
        if row.backend.as_deref() != Some(backend.as_str()) {
            failures.push(format!(
                "{}.backend: expected '{}', got '{}'",
                label, backend,
                row.backend.as_deref().unwrap_or("")
            ));
        }
    }
    if let Some(ref placement) = matcher.placement {
        if row.placement.as_deref() != Some(placement.as_str()) {
            failures.push(format!(
                "{}.placement: expected '{}', got '{}'",
                label, placement,
                row.placement.as_deref().unwrap_or("")
            ));
        }
    }
    if let Some(val) = matcher.executable {
        if row.executable != val {
            failures.push(format!(
                "{}.executable: expected {}, got {}",
                label, val, row.executable
            ));
        }
    }
    if let Some(val) = matcher.selectable {
        if row.selectable != val {
            failures.push(format!(
                "{}.selectable: expected {}, got {}",
                label, val, row.selectable
            ));
        }
    }
    if let Some(val) = matcher.selected {
        if row.selected != val {
            failures.push(format!(
                "{}.selected: expected {}, got {}",
                label, val, row.selected
            ));
        }
    }
    if let Some(val) = matcher.highlighted {
        if row.highlighted != val {
            failures.push(format!(
                "{}.highlighted: expected {}, got {}",
                label, val, row.highlighted
            ));
        }
    }
    if let Some(val) = matcher.expanded {
        if row.expanded != val {
            failures.push(format!(
                "{}.expanded: expected {}, got {}",
                label, val, row.expanded
            ));
        }
    }
    if let Some(ref bc) = matcher.breadcrumb_text {
        let actual = row.breadcrumb_text.as_deref().unwrap_or("");
        if actual != bc.as_str() {
            failures.push(format!(
                "{}.breadcrumbText: expected '{}', got '{}'",
                label, bc, actual
            ));
        }
    }
    if let Some(ref expected_path) = matcher.path {
        if row.path.as_slice() != expected_path.as_slice() {
            failures.push(format!(
                "{}.path: expected {:?}, got {:?}",
                label, expected_path, row.path
            ));
        }
    }
}

fn row_matches_logical(row: &VisualRow, matcher: &RowMatcher) -> bool {
    if let Some(ref key) = matcher.key {
        if row.key != *key { return false; }
    }
    if let Some(ref title) = matcher.title {
        if row.title != *title { return false; }
    }
    if let Some(ref backend) = matcher.backend {
        if row.backend.as_deref() != Some(backend.as_str()) { return false; }
    }
    if let Some(ref placement) = matcher.placement {
        if row.placement.as_deref() != Some(placement.as_str()) { return false; }
    }
    if let Some(val) = matcher.executable {
        if row.executable != val { return false; }
    }
    if let Some(val) = matcher.selectable {
        if row.selectable != val { return false; }
    }
    if let Some(val) = matcher.selected {
        if row.selected != val { return false; }
    }
    if let Some(val) = matcher.highlighted {
        if row.highlighted != val { return false; }
    }
    if let Some(val) = matcher.expanded {
        if row.expanded != val { return false; }
    }
    if let Some(ref bc) = matcher.breadcrumb_text {
        if row.breadcrumb_text.as_deref() != Some(bc.as_str()) { return false; }
    }
    if let Some(ref expected_path) = matcher.path {
        if row.path.as_slice() != expected_path.as_slice() { return false; }
    }
    true
}

#[allow(dead_code)]
pub fn format_rows_table(rows: &[VisualRow]) -> String {
    let mut out = String::new();
    out.push_str(&format!("  {:<4} {:<5} {:<5} {:<10} {:<10} {:<12} {:<16} {:<30} {}\n",
        "Idx", "Sel", "Hl", "Selectable", "Exec", "Placement", "Backend", "Title", "Path"));
    out.push_str("  ");
    out.push_str(&"─".repeat(110));
    out.push('\n');
    for (i, row) in rows.iter().enumerate() {
        let sel = if row.selected { "✓" } else { "" };
        let hl = if row.highlighted { "✓" } else { "" };
        let sel_able = if row.selectable { "✓" } else { "" };
        let exec = if row.executable { "✓" } else { "" };
        let placement = row.placement.as_deref().unwrap_or("");
        let backend = row.backend.as_deref().unwrap_or("");
        let title: String = row.title.chars().take(28).collect();
        let path = row.path.join(" > ");
        out.push_str(&format!("  {:<4} {:<5} {:<5} {:<10} {:<10} {:<12} {:<16} {:<30} {}\n",
            i, sel, hl, sel_able, exec, placement, backend, title, path));
    }
    out
}

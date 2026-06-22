use colored::Colorize;
use similar::{ChangeTag, TextDiff};

use crate::schema::*;

pub fn assert_expectation(state: &LauncherState, rows: &[PipelineRow], expect: &Expectation) -> Vec<String> {
    let mut failures = Vec::new();

    // Check query
    if let Some(ref expected_query) = expect.query {
        if state.query != *expected_query {
            failures.push(format!(
                "query mismatch: expected '{}', got '{}'",
                expected_query, state.query
            ));
        }
    }

    // Check exactlyOneSelected
    let exactly_one = expect.exactly_one_selected.unwrap_or(false)
        || expect.exactly_one_selected_alias.unwrap_or(false);
    if exactly_one {
        let selected_count = rows.iter().filter(|r| r.executable.unwrap_or(false)).count();
        // Actually we need the selected field from visual state
        // For now, check if exactly one row has own_visible and is top
        if selected_count != 1 {
            failures.push(format!(
                "exactlyOneSelected: expected 1 selected row, found {}",
                selected_count
            ));
        }
    }

    // Check selected row matcher
    if let Some(ref matcher) = expect.selected {
        let top_row = rows.first();
        match top_row {
            Some(row) => {
                let mut row_ok = true;
                if let Some(ref title) = matcher.title {
                    if row.title.as_deref() != Some(title.as_str()) {
                        failures.push(format!(
                            "selected.title: expected '{}', got '{}'",
                            title,
                            row.title.as_deref().unwrap_or("")
                        ));
                        row_ok = false;
                    }
                }
                if let Some(ref backend) = matcher.backend {
                    if row.source.as_deref() != Some(backend.as_str()) {
                        failures.push(format!(
                            "selected.backend: expected '{}', got '{}'",
                            backend,
                            row.source.as_deref().unwrap_or("")
                        ));
                        row_ok = false;
                    }
                }
                if let Some(ref placement) = matcher.placement {
                    if row.placement.as_deref() != Some(placement.as_str()) {
                        failures.push(format!(
                            "selected.placement: expected '{}', got '{}'",
                            placement,
                            row.placement.as_deref().unwrap_or("")
                        ));
                        row_ok = false;
                    }
                }
                if let Some(exec) = matcher.executable {
                    if row.executable.unwrap_or(false) != exec {
                        failures.push(format!(
                            "selected.executable: expected {}, got {}",
                            exec,
                            row.executable.unwrap_or(false)
                        ));
                        row_ok = false;
                    }
                }
                if let Some(ref bc) = matcher.breadcrumb_text {
                    let actual = row.breadcrumb_text.as_deref().unwrap_or("");
                    if actual != bc.as_str() {
                        failures.push(format!(
                            "selected.breadcrumbText: expected '{}', got '{}'",
                            bc, actual
                        ));
                        row_ok = false;
                    }
                }
                if row_ok {
                    // Path check
                    if let Some(ref expected_path) = matcher.path {
                        let actual_bc = row.breadcrumb_text.as_deref().unwrap_or("");
                        let actual_crumbs = row.breadcrumbs.as_deref().unwrap_or(&[]);
                        let mut matched = false;
                        if !actual_crumbs.is_empty() && actual_crumbs.len() == expected_path.len() {
                            matched = actual_crumbs.iter().zip(expected_path.iter()).all(|(a, e)| a == e);
                        }
                        if !matched && actual_bc == expected_path.join(" > ") {
                            matched = true;
                        }
                        if !matched {
                            failures.push(format!(
                                "selected.path: expected {:?}, got breadcrumbs={:?} breadcrumbText='{}'",
                                expected_path, actual_crumbs, actual_bc
                            ));
                        }
                    }
                }
            }
            None => {
                failures.push("selected: expected a selected row but no rows found".to_string());
            }
        }
    }

    // Check rows expectations
    if let Some(ref rows_expect) = expect.rows {
        // Count
        if let Some(expected_count) = rows_expect.count {
            if rows.len() != expected_count {
                failures.push(format!(
                    "rows.count: expected {}, got {}",
                    expected_count,
                    rows.len()
                ));
            }
        }

        // Contains (at least one row matches each matcher)
        if let Some(ref contains) = rows_expect.contains {
            for matcher in contains {
                let matched = rows.iter().any(|r| row_matches(r, matcher));
                if !matched {
                    failures.push(format!(
                        "rows.contains: no row matched matcher {:?}",
                        matcher
                    ));
                }
            }
        }

        // Not contains (no row matches)
        if let Some(ref not_contains) = rows_expect.not_contains {
            for matcher in not_contains {
                let matched = rows.iter().any(|r| row_matches(r, matcher));
                if matched {
                    failures.push(format!(
                        "rows.notContains: found row matching {:?}",
                        matcher
                    ));
                }
            }
        }

        // Contains title
        if let Some(ref titles) = rows_expect.contains_title {
            for title in titles {
                let found = rows.iter().any(|r| r.title.as_deref() == Some(title.as_str()));
                if !found {
                    failures.push(format!(
                        "rows.containsTitle: '{}' not found in rows",
                        title
                    ));
                }
            }
        }

        // Not contains title
        if let Some(ref titles) = rows_expect.not_contains_title {
            for title in titles {
                let found = rows.iter().any(|r| r.title.as_deref() == Some(title.as_str()));
                if found {
                    failures.push(format!(
                        "rows.notContainsTitle: '{}' found in rows",
                        title
                    ));
                }
            }
        }

        // Contains in order
        if let Some(ref ordered) = rows_expect.contains_in_order {
            let row_titles: Vec<&str> = rows.iter()
                .filter_map(|r| r.title.as_deref())
                .collect();
            let mut pos = 0;
            for title in ordered {
                let found = row_titles[pos..].iter().position(|&t| t == title.as_str());
                match found {
                    Some(idx) => pos += idx + 1,
                    None => {
                        failures.push(format!(
                            "rows.containsInOrder: '{}' not found in order (after position {})",
                            title, pos
                        ));
                    }
                }
            }
        }

        // None highlighted except selected
        if rows_expect.none_highlighted_except_selected.unwrap_or(false) {
            // This requires visual state with highlighted field
            // For now, check if any non-first row has own_visible when only first should be highlighted
            let any_non_first_visible = rows.iter().skip(1).any(|r| r.own_visible.unwrap_or(false));
            if any_non_first_visible {
                failures.push("rows.noneHighlightedExceptSelected: expected only first row highlighted".to_string());
            }
        }
    }

    failures
}

fn row_matches(row: &PipelineRow, matcher: &RowMatcher) -> bool {
    if let Some(ref title) = matcher.title {
        if row.title.as_deref() != Some(title.as_str()) {
            return false;
        }
    }
    if let Some(ref backend) = matcher.backend {
        if row.source.as_deref() != Some(backend.as_str()) {
            return false;
        }
    }
    if let Some(ref placement) = matcher.placement {
        if row.placement.as_deref() != Some(placement.as_str()) {
            return false;
        }
    }
    if let Some(exec) = matcher.executable {
        if row.executable.unwrap_or(false) != exec {
            return false;
        }
    }
    if let Some(ref bc) = matcher.breadcrumb_text {
        if row.breadcrumb_text.as_deref() != Some(bc.as_str()) {
            return false;
        }
    }
    true
}

pub fn format_diff(actual: &str, expected: &str) -> String {
    let diff = TextDiff::from_lines(expected, actual);
    let mut out = String::new();
    for change in diff.iter_all_changes() {
        let sign = match change.tag() {
            ChangeTag::Delete => "-",
            ChangeTag::Insert => "+",
            ChangeTag::Equal => " ",
        };
        let line = format!("{} {}", sign, change.value());
        match change.tag() {
            ChangeTag::Delete => out.push_str(&line.red().to_string()),
            ChangeTag::Insert => out.push_str(&line.green().to_string()),
            ChangeTag::Equal => out.push_str(&line.normal().to_string()),
        }
    }
    out
}

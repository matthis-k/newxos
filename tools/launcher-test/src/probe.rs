use std::path::Path;

use crate::runner;
use crate::schema::*;

pub struct ProbeInfo {
    pub case_name: String,
    pub command: String,
    pub jq_filter: String,
    pub description: String,
}

pub fn generate_probes(path: &Path, filter: Option<&str>) -> Vec<ProbeInfo> {
    let cases = match runner::load_cases(path) {
        Ok(c) => c,
        Err(_) => return vec![],
    };

    let filtered: Vec<TestCase> = cases.into_iter()
        .filter(|c| {
            if let Some(f) = filter {
                let f_lower = f.to_lowercase();
                c.name.to_lowercase().contains(&f_lower)
                    || c.tags.iter().any(|t| t.to_lowercase().contains(&f_lower))
            } else {
                true
            }
        })
        .collect();

    filtered.into_iter().map(|case| derive_probe(&case)).collect()
}

fn derive_probe(case: &TestCase) -> ProbeInfo {
    if let Some(ref query) = case.query {
        derive_query_probe(case, query)
    } else if case.steps.is_some() {
        derive_step_probe(case)
    } else {
        ProbeInfo {
            case_name: case.name.clone(),
            command: String::new(),
            jq_filter: String::new(),
            description: "No query or steps to probe".to_string(),
        }
    }
}

fn escape_query(query: &str) -> String {
    query.replace('"', "\\\"")
}

fn derive_query_probe(case: &TestCase, query: &str) -> ProbeInfo {
    let escaped = escape_query(query);
    let base_cmd = format!("newshell ipc call query pipeline \"{}\"", escaped);

    let jq = derive_jq_from_expect(case.expect.as_ref());

    ProbeInfo {
        case_name: case.name.clone(),
        command: base_cmd,
        jq_filter: jq,
        description: format!(
            "Query-based case. Run pipeline and inspect rows.\n  Command: newshell ipc call query pipeline \"{}\"\n  Filter: {}", escaped, derive_jq_from_expect(case.expect.as_ref())),
    }
}

fn derive_step_probe(case: &TestCase) -> ProbeInfo {
    let steps = case.normalized_steps();
    let mut interact_calls = Vec::new();
    let mut final_expect: Option<Expectation> = None;

    for step in &steps {
        match step {
            NormalizedStep::Do(action) => {
                let json = step_action_to_json(action);
                interact_calls.push(format!(
                    "newshell ipc call launcher interactJson '{}'",
                    json
                ));
            }
            NormalizedStep::Expect(expect) => {
                final_expect = Some(expect.clone());
            }
        }
    }

    let first = interact_calls.first().cloned().unwrap_or_default();
    let state_cmd = "newshell ipc call launcher state".to_string();
    let jq = if let Some(ref expect) = final_expect {
        derive_jq_from_expect(Some(expect))
    } else {
        ".rows[] | {title, key: .key, backend: .backend, placement: .placement, selected: .selected, executable: .executable, path: .path}"
            .to_string()
    };

    let desc = format!(
        "Step-based case. Reproduce actions then inspect state.\n  First action: {}\n  Inspect: {} | jq '{}'",
        first, state_cmd, jq
    );

    ProbeInfo {
        case_name: case.name.clone(),
        command: state_cmd,
        jq_filter: jq,
        description: desc,
    }
}

fn step_action_to_json(action: &StepAction) -> String {
    match action {
        StepAction::Reset => r#"{"action":"reset"}"#.to_string(),
        StepAction::Open { visible } => {
            let vis = visible.unwrap_or(false);
            let arg = if vis { "visible" } else { "headless" };
            format!(r#"{{"action":"open","openArg":"{}"}}"#, arg)
        }
        StepAction::Close => r#"{"action":"close"}"#.to_string(),
        StepAction::SetQuery { query } => {
            format!(r#"{{"action":"setQuery","query":"{}"}}"#, query.replace('"', "\\\""))
        }
        StepAction::TypeText { text } => {
            format!(r#"{{"action":"typeText","text":"{}"}}"#, text.replace('"', "\\\""))
        }
        StepAction::Backspace { count } => {
            format!(r#"{{"action":"backspace","count":{}}}"#, count.unwrap_or(1))
        }
        StepAction::MoveSelection { direction } => {
            let delta = match direction.as_str() {
                "up" => -1,
                "down" => 1,
                "left" => -1,
                "right" => 1,
                _ => 0,
            };
            format!(r#"{{"action":"moveSelection","delta":{}}}"#, delta)
        }
        StepAction::Expand { selector: _ } => {
            r#"{"action":"expandSelected"}"#.to_string()
        }
        StepAction::Collapse { selector: _ } => {
            r#"{"action":"collapseSelected"}"#.to_string()
        }
        StepAction::Execute { selector: _ } => {
            r#"{"action":"activateSelected"}"#.to_string()
        }
    }
}

fn derive_jq_from_expect(expect: Option<&Expectation>) -> String {
    let expect = match expect {
        Some(e) => e,
        None => {
            return ".rows[] | {title, key: .key, backend: .backend, placement: .placement, selected: .selected, executable: .executable, path: .path}"
                .to_string();
        }
    };

    let mut filters: Vec<String> = Vec::new();

    if expect.exactly_one_selected == Some(true) {
        filters.push("[.rows[] | select(.selected)] | length == 1".to_string());
    }

    if let Some(ref selected) = expect.selected {
        if let Some(ref title) = selected.title {
            filters.push(format!(
                ".rows[] | select(.selected) | .title == \"{}\"",
                title
            ));
        }
        if let Some(ref backend) = selected.backend {
            filters.push(format!(
                ".rows[] | select(.selected) | .backend == \"{}\"",
                backend
            ));
        }
    }

    if let Some(ref rows_expect) = expect.rows {
        if let Some(ref contains) = rows_expect.contains {
            for matcher in contains {
                if let Some(ref title) = matcher.title {
                    filters.push(format!("any(.rows[]; .title == \"{}\")", title));
                }
                if let Some(ref backend) = matcher.backend {
                    filters.push(format!("any(.rows[]; .backend == \"{}\")", backend));
                }
            }
        }

        if let Some(ref not_contains) = rows_expect.not_contains {
            for matcher in not_contains {
                if let Some(ref title) = matcher.title {
                    filters.push(format!("all(.rows[]; .title != \"{}\")", title));
                }
                if let Some(ref backend) = matcher.backend {
                    filters.push(format!("all(.rows[]; .backend != \"{}\")", backend));
                }
            }
        }

        if let Some(ref titles) = rows_expect.contains_title {
            for title in titles {
                filters.push(format!("any(.rows[]; .title == \"{}\")", title));
            }
        }

        if let Some(ref titles) = rows_expect.not_contains_title {
            for title in titles {
                filters.push(format!("all(.rows[]; .title != \"{}\")", title));
            }
        }

        if let Some(ref first_matcher) = rows_expect.first {
            if let Some(ref title) = first_matcher.title {
                filters.push(format!(".rows[0].title == \"{}\"", title));
            }
        }
    }

    if filters.is_empty() {
        ".rows[] | {title, key, backend, placement, selected, executable, path}".to_string()
    } else {
        format!("{}", filters.join(" and "))
    }
}

pub fn print_probe(probe: &ProbeInfo, show_jq: bool) {
    if show_jq {
        println!("{}", probe.jq_filter);
    } else {
        println!("=== Probe: {} ===", probe.case_name);
        println!("{}", probe.description);
        if !probe.jq_filter.is_empty() {
            println!("\nDerived jq filter:");
            println!("  {}", probe.jq_filter);
        }
    }
}

pub fn run_probe(probe: &ProbeInfo, verbose: bool) -> Result<(), String> {
    let newshell_bin = std::env::var("NEWSHELL_BIN").unwrap_or_else(|_| "newshell".to_string());

    let ipc_cmd = if probe.command.contains("$NEWSHELL_IPC_NAMESPACE") {
        let ns = std::env::var("NEWSHELL_IPC_NAMESPACE").unwrap_or_default();
        probe.command.replace("$NEWSHELL_IPC_NAMESPACE", &ns)
    } else {
        probe.command.clone()
    };

    let ipc_parts: Vec<&str> = ipc_cmd.split_whitespace().collect();
    if ipc_parts.is_empty() {
        return Err("Invalid IPC command".to_string());
    }

    let mut cmd = std::process::Command::new(&newshell_bin);
    if ipc_parts[0] == "newshell" && ipc_parts.len() > 1 {
        cmd.args(&ipc_parts[1..]);
    } else {
        cmd.args(&ipc_parts);
    }

    let output = cmd.output()
        .map_err(|e| format!("Failed to execute probe: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("IPC call failed: {}", stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let data: serde_json::Value = serde_json::from_str(stdout.trim())
        .map_err(|e| format!("Failed to parse IPC response: {}", e))?;

    if verbose {
        println!("{}", serde_json::to_string_pretty(&data).unwrap_or_default());
    } else {
        if let Some(rows) = data.get("rows").and_then(|v| v.as_array()) {
            println!("{} rows returned", rows.len());
            for (i, row) in rows.iter().enumerate() {
                let title = row.get("title").and_then(|v| v.as_str()).unwrap_or("");
                let backend = row.get("backend").and_then(|v| v.as_str()).unwrap_or("");
                let placement = row.get("placement").and_then(|v| v.as_str()).unwrap_or("");
                let selected = row.get("selected").and_then(|v| v.as_bool()).unwrap_or(false);
                let sel_mark = if selected { " [SELECTED]" } else { "" };
                println!("  [{}] {} (backend={}, placement={}){}", i, title, backend, placement, sel_mark);
            }
        } else if let Some(state_rows) = data.pointer("/rows").and_then(|v| v.as_array()) {
            println!("{} rows in visual state", state_rows.len());
            for (i, row) in state_rows.iter().enumerate() {
                let title = row.get("title").and_then(|v| v.as_str()).unwrap_or("");
                let backend = row.get("backend").and_then(|v| v.as_str()).unwrap_or("");
                let placement = row.get("placement").and_then(|v| v.as_str()).unwrap_or("");
                let selected = row.get("selected").and_then(|v| v.as_bool()).unwrap_or(false);
                let sel_mark = if selected { " [SELECTED]" } else { "" };
                println!("  [{}] {} (backend={}, placement={}){}", i, title, backend, placement, sel_mark);
            }
        } else {
            println!("Response: {}", serde_json::to_string_pretty(&data).unwrap_or_default());
        }
    }

    Ok(())
}

use std::path::Path;
use std::time::Instant;

use anyhow::{Context, Result};

use crate::assertions;
use crate::ipc::LauncherIpc;
use crate::pretty;
use crate::schema::*;

pub fn load_cases(path: &Path) -> Result<Vec<TestCase>> {
    let mut cases = Vec::new();
    if path.is_dir() {
        let mut entries: Vec<_> = std::fs::read_dir(path)
            .context("Failed to read test cases directory")?
            .filter_map(|e| e.ok())
            .filter(|e| e.path().extension().map_or(false, |ext| ext == "json"))
            .collect();
        entries.sort_by_key(|e| e.file_name());
        for entry in entries {
            let content = std::fs::read_to_string(entry.path())
                .context(format!("Failed to read {}", entry.path().display()))?;
            let suite: TestSuite = serde_json::from_str(&content)
                .context(format!("Failed to parse {}", entry.path().display()))?;
            cases.extend(suite.cases);
        }
    } else if path.is_file() {
        let content = std::fs::read_to_string(path)
            .context(format!("Failed to read {}", path.display()))?;
        let suite: TestSuite = serde_json::from_str(&content)
            .context(format!("Failed to parse {}", path.display()))?;
        cases.extend(suite.cases);
    } else {
        anyhow::bail!("Path does not exist: {}", path.display());
    }
    Ok(cases)
}

pub fn validate_cases(path: &Path, schema_path: Option<&Path>) -> Result<Vec<String>> {
    let cases = load_cases(path)?;
    let mut errors = Vec::new();

    if let Some(schema_path) = schema_path {
        let schema_content = std::fs::read_to_string(schema_path)
            .context("Failed to read schema file")?;
        let _schema: serde_json::Value = serde_json::from_str(&schema_content)
            .context("Failed to parse schema JSON")?;
    }

    for (i, case) in cases.iter().enumerate() {
        if case.name.is_empty() {
            errors.push(format!("Case #{}: missing name", i));
        }
        if case.query.is_none() && case.steps.is_none() {
            errors.push(format!("Case '{}': must have either 'query' or 'steps'", case.name));
        }
        if let Some(ref _expect) = case.expect {
            if case.steps.is_some() {
                errors.push(format!(
                    "Case '{}': 'expect' at top level is ignored when 'steps' are defined",
                    case.name
                ));
            }
        }
    }

    if errors.is_empty() {
        println!("✓ All {} cases valid", cases.len());
    }
    Ok(errors)
}

pub fn list_cases(path: &Path, filter: Option<&str>) -> Result<Vec<TestCase>> {
    let cases = load_cases(path)?;
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

    println!("Available cases ({}):", filtered.len());
    for case in &filtered {
        let tags = if case.tags.is_empty() {
            String::new()
        } else {
            format!(" [{}]", case.tags.join(", "))
        };
        println!("  {} - {}{}", case.name, case.query.as_deref().unwrap_or("<step-based>"), tags);
    }
    Ok(filtered)
}

pub fn run_cases(
    path: &Path,
    filter: Option<&str>,
    mode: &crate::cli::RunMode,
    socket: Option<&std::path::Path>,
) -> Result<RunSummary> {
    let ipc = if let Some(sock) = socket {
        LauncherIpc::with_socket(Some(sock.to_path_buf()))?
    } else {
        LauncherIpc::new()?
    };
    let cases = load_cases(path)?;

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

    if filtered.is_empty() {
        anyhow::bail!("No test cases matched the filter");
    }

    println!("Running {} case(s) in {:?} mode", filtered.len(), mode);
    if matches!(mode, crate::cli::RunMode::Headless) {
        pretty::print_fixtures_intro();
    }

    let start = Instant::now();
    let mut results = Vec::new();

    for (i, case) in filtered.iter().enumerate() {
        pretty::print_case_header(&case.name, i, filtered.len());
        let case_start = Instant::now();

        match run_single_case(case, &ipc, mode) {
            Ok(failures) => {
                let duration = case_start.elapsed().as_millis() as u64;
                if failures.is_empty() {
                    pretty::print_pass(&case.name, duration);
                    results.push(TestResult {
                        name: case.name.clone(),
                        passed: true,
                        failures: vec![],
                        duration_ms: duration,
                    });
                } else {
                    pretty::print_fail(&case.name, &failures, duration);
                    results.push(TestResult {
                        name: case.name.clone(),
                        passed: false,
                        failures,
                        duration_ms: duration,
                    });
                }
            }
            Err(e) => {
                let duration = case_start.elapsed().as_millis() as u64;
                let msg = format!("Error: {}", e);
                pretty::print_fail(&case.name, &[msg.clone()], duration);
                results.push(TestResult {
                    name: case.name.clone(),
                    passed: false,
                    failures: vec![msg],
                    duration_ms: duration,
                });
            }
        }
    }

    let total_duration = start.elapsed().as_millis() as u64;
    let passed = results.iter().filter(|r| r.passed).count();
    let failed = results.iter().filter(|r| !r.passed).count();

    let summary = RunSummary {
        total: results.len(),
        passed,
        failed,
        skipped: 0,
        duration_ms: total_duration,
        results,
    };

    pretty::print_summary(&summary);
    Ok(summary)
}

fn run_single_case(case: &TestCase, ipc: &LauncherIpc, mode: &crate::cli::RunMode) -> Result<Vec<String>> {
    let steps = case.normalized_steps();
    let mut all_failures = Vec::new();

    for step in &steps {
        match step {
            NormalizedStep::Do(action) => {
                let resp = match action {
                    StepAction::Reset => ipc.reset()?,
                    StepAction::Open { visible } => {
                        let vis = visible.unwrap_or_else(|| matches!(mode, crate::cli::RunMode::Visible));
                        ipc.open(vis)?
                    }
                    StepAction::Close => ipc.close()?,
                    StepAction::SetQuery { query } => ipc.set_query(query)?,
                    StepAction::TypeText { text } => ipc.type_text(text)?,
                    StepAction::Backspace { count } => ipc.backspace(count.unwrap_or(1))?,
                    StepAction::MoveSelection { direction } => ipc.move_selection(direction)?,
                    StepAction::Expand { .. } => ipc.expand_selected()?,
                    StepAction::Collapse { .. } => ipc.collapse_selected()?,
                    StepAction::Execute { .. } => ipc.activate_selected()?,
                };
                let _ = ipc.wait_for_settled(2000)
                    .context("State did not settle after action")?;
                std::mem::drop(resp);
            }
            NormalizedStep::Expect(expect) => {
                let state = ipc.visual_state()
                    .context("Failed to get visual state for assertion")?;

                let failures = assertions::assert_expectation(&state, expect);
                if !failures.is_empty() {
                    pretty::print_visual_state(&state);
                }
                all_failures.extend(failures);
            }
        }
    }

    let _ = ipc.close();
    Ok(all_failures)
}

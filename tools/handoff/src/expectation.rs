use std::path::Path;

use crate::config::{Expectation, ExitExpectation, VerifyStdin, VerifySpec};
use crate::runner::CommandResult;

#[derive(Debug, Clone)]
pub struct ExpectationResult {
    pub passed: bool,
    pub failures: Vec<String>,
}

/// Check a command result against an expectation.
pub fn check_expectation(
    result: &CommandResult,
    expect: &Expectation,
    target_id: &str,
    step_id: Option<&str>,
    config_file: &Path,
    cwd: &Path,
) -> ExpectationResult {
    let mut failures = Vec::new();

    // Check exit code
    match &expect.exit {
        Some(ExitExpectation::Success) => {
            if result.exit_code != 0 {
                failures.push(format!(
                    "expected success, got exit code {}",
                    result.exit_code
                ));
            }
        }
        Some(ExitExpectation::Failure) => {
            if result.exit_code == 0 {
                failures.push(format!(
                    "expected failure, got exit code {}",
                    result.exit_code
                ));
            }
        }
        None => {}
    }

    if let Some(expected_code) = &expect.exit_code {
        if result.exit_code != *expected_code {
            failures.push(format!(
                "expected exit code {}, got {}",
                expected_code, result.exit_code
            ));
        }
    }

    // Check stdout contains
    for s in &expect.stdout_contains {
        if !result.stdout.contains(s) {
            failures.push(format!("stdout did not contain: {:?}", s));
        }
    }

    // Check stderr contains
    for s in &expect.stderr_contains {
        if !result.stderr.contains(s) {
            failures.push(format!("stderr did not contain: {:?}", s));
        }
    }

    // Check stdout not contains
    for s in &expect.stdout_not_contains {
        if result.stdout.contains(s) {
            failures.push(format!("stdout unexpectedly contained: {:?}", s));
        }
    }

    // Check stderr not contains
    for s in &expect.stderr_not_contains {
        if result.stderr.contains(s) {
            failures.push(format!("stderr unexpectedly contained: {:?}", s));
        }
    }

    // Check stdout regex
    for pattern in &expect.stdout_regex {
        match regex::Regex::new(pattern) {
            Ok(re) => {
                if !re.is_match(&result.stdout) {
                    failures.push(format!("stdout did not match regex: {:?}", pattern));
                }
            }
            Err(e) => {
                failures.push(format!("invalid stdout regex {:?}: {}", pattern, e));
            }
        }
    }

    // Check stderr regex
    for pattern in &expect.stderr_regex {
        match regex::Regex::new(pattern) {
            Ok(re) => {
                if !re.is_match(&result.stderr) {
                    failures.push(format!("stderr did not match regex: {:?}", pattern));
                }
            }
            Err(e) => {
                failures.push(format!("invalid stderr regex {:?}: {}", pattern, e));
            }
        }
    }

    // Check stdout not regex
    for pattern in &expect.stdout_not_regex {
        match regex::Regex::new(pattern) {
            Ok(re) => {
                if re.is_match(&result.stdout) {
                    failures.push(format!("stdout unexpectedly matched regex: {:?}", pattern));
                }
            }
            Err(e) => {
                failures.push(format!("invalid stdout not-regex {:?}: {}", pattern, e));
            }
        }
    }

    // Check stderr not regex
    for pattern in &expect.stderr_not_regex {
        match regex::Regex::new(pattern) {
            Ok(re) => {
                if re.is_match(&result.stderr) {
                    failures.push(format!("stderr unexpectedly matched regex: {:?}", pattern));
                }
            }
            Err(e) => {
                failures.push(format!("invalid stderr not-regex {:?}: {}", pattern, e));
            }
        }
    }

    // Run verification command
    if let Some(verify) = &expect.verify {
        let vr = run_verifier(verify, result, target_id, step_id, config_file, cwd);
        if !vr.passed {
            failures.extend(vr.failures);
        }
    }

    ExpectationResult {
        passed: failures.is_empty(),
        failures,
    }
}

fn run_verifier(
    verify: &VerifySpec,
    result: &CommandResult,
    target_id: &str,
    step_id: Option<&str>,
    config_file: &Path,
    cwd: &Path,
) -> ExpectationResult {
    // Write stdout/stderr/result JSON to temp files
    let tmp_dir = std::env::temp_dir().join(format!("repo-handoff-{}", std::process::id()));
    let _ = std::fs::create_dir_all(&tmp_dir);

    let stdout_file = tmp_dir.join("stdout");
    let stderr_file = tmp_dir.join("stderr");
    let result_json_file = tmp_dir.join("result.json");

    let _ = std::fs::write(&stdout_file, &result.stdout);
    let _ = std::fs::write(&stderr_file, &result.stderr);

    let result_json = serde_json::json!({
        "targetId": target_id,
        "stepId": step_id,
        "command": {
            "program": result.command_program,
            "args": result.command_args,
        },
        "cwd": cwd.to_string_lossy(),
        "exitCode": result.exit_code,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "durationMs": result.duration.as_millis() as u64,
        "timedOut": result.timed_out,
    });

    let _ = std::fs::write(
        &result_json_file,
        serde_json::to_string_pretty(&result_json).unwrap(),
    );

    // Build verifier command
    let mut cmd = std::process::Command::new(&verify.program);
    cmd.args(&verify.args)
        .env("HANDOFF_TARGET_ID", target_id)
        .env("HANDOFF_STEP_ID", step_id.unwrap_or(""))
        .env("HANDOFF_EXIT_CODE", result.exit_code.to_string())
        .env("HANDOFF_STDOUT_FILE", stdout_file.to_string_lossy().as_ref())
        .env("HANDOFF_STDERR_FILE", stderr_file.to_string_lossy().as_ref())
        .env("HANDOFF_RESULT_JSON_FILE", result_json_file.to_string_lossy().as_ref())
        .env("HANDOFF_CONFIG_FILE", config_file.to_string_lossy().as_ref())
        .env("HANDOFF_CWD", cwd.to_string_lossy().as_ref())
        .current_dir(cwd);

    // Set stdin
    match &verify.stdin {
        VerifyStdin::Stdout => {
            cmd.stdin(std::process::Stdio::piped());
        }
        VerifyStdin::Stderr => {
            cmd.stdin(std::process::Stdio::piped());
        }
        VerifyStdin::ResultJson => {
            cmd.stdin(std::process::Stdio::piped());
        }
        VerifyStdin::None => {
            cmd.stdin(std::process::Stdio::null());
        }
    }

    let mut child = match cmd.stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            return ExpectationResult {
                passed: false,
                failures: vec![format!("verifier failed to start: {}", e)],
            };
        }
    };

    // Feed stdin
    if let VerifyStdin::Stdout = &verify.stdin {
        let _ = std::io::Write::write_all(
            &mut child.stdin.take().unwrap(),
            result.stdout.as_bytes(),
        );
    } else if let VerifyStdin::Stderr = &verify.stdin {
        let _ = std::io::Write::write_all(
            &mut child.stdin.take().unwrap(),
            result.stderr.as_bytes(),
        );
    } else if let VerifyStdin::ResultJson = &verify.stdin {
        let json_str = serde_json::to_string(&result_json).unwrap();
        let _ = std::io::Write::write_all(
            &mut child.stdin.take().unwrap(),
            json_str.as_bytes(),
        );
    }

    let output = match child.wait_with_output() {
        Ok(o) => o,
        Err(e) => {
            return ExpectationResult {
                passed: false,
                failures: vec![format!("verifier failed: {}", e)],
            };
        }
    };

    let mut failures = Vec::new();
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        failures.push(format!(
            "verifier exited with code {}: {}",
            output.status.code().unwrap_or(-1),
            stderr.trim()
        ));
    }

    ExpectationResult {
        passed: failures.is_empty(),
        failures,
    }
}

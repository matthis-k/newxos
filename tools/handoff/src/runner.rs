use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

use crate::config::{CommandSpec, CwdMode, Step};

#[derive(Debug, Clone)]
pub struct CommandResult {
    pub exit_code: i32,
    pub stdout: String,
    pub stderr: String,
    pub duration: Duration,
    pub timed_out: bool,
    pub command_program: String,
    pub command_args: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct RunTarget {
    pub id: String,
    pub source_file: PathBuf,
}

#[derive(Debug, Clone)]
pub enum RunOutcome {
    Passed {
        target_id: String,
        source_file: PathBuf,
        duration: Duration,
    },
    Failed {
        target_id: String,
        source_file: PathBuf,
        duration: Duration,
        failures: Vec<String>,
        result: CommandResult,
    },
    Skipped {
        target_id: String,
        source_file: PathBuf,
        reason: String,
    },
}

/// Resolve the working directory for a command.
pub fn resolve_cwd(
    cwd_mode: Option<CwdMode>,
    config_dir: &Path,
    repo_root: &Path,
    invocation_cwd: &Path,
    defaults_cwd: Option<CwdMode>,
) -> PathBuf {
    let mode = cwd_mode
        .or(defaults_cwd)
        .unwrap_or(CwdMode::Repo);

    match mode {
        CwdMode::Repo => repo_root.to_path_buf(),
        CwdMode::Config => config_dir.to_path_buf(),
        CwdMode::Invocation => invocation_cwd.to_path_buf(),
    }
}

/// Resolve the timeout in seconds.
pub fn resolve_timeout(
    step_timeout: Option<u64>,
    target_timeout: Option<u64>,
    default_timeout: Option<u64>,
) -> Duration {
    let secs = step_timeout
        .or(target_timeout)
        .or(default_timeout)
        .unwrap_or(120);
    Duration::from_secs(secs)
}

/// Run a single command and capture output.
pub fn run_command(
    spec: &CommandSpec,
    _cwd: &Path,
    resolve_cwd: &Path,
    timeout: Duration,
    extra_env: &[(String, String)],
) -> CommandResult {
    let start = Instant::now();

    let program = if spec.shell {
        "sh".to_string()
    } else {
        spec.program.clone().unwrap_or_else(|| {
            // infer from line
            if let Some(line) = &spec.line {
                line.split_whitespace().next().unwrap_or("").to_string()
            } else {
                String::new()
            }
        })
    };

    let args: Vec<String> = if spec.shell {
        vec!["-c".to_string(), spec.line.clone().unwrap_or_default()]
    } else {
        spec.args.clone()
    };

    let mut cmd = Command::new(&program);
    cmd.args(&args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .stdin(Stdio::null())
        .current_dir(resolve_cwd);

    // Inherit process env, merge configured env
    for (k, v) in &spec.env {
        cmd.env(k, v);
    }
    for (k, v) in extra_env {
        cmd.env(k, v);
    }

    let mut child = match cmd.spawn() {
        Ok(c) => c,
        Err(e) => {
            let elapsed = start.elapsed();
            return CommandResult {
                exit_code: -1,
                stdout: String::new(),
                stderr: format!("failed to spawn command: {}", e),
                duration: elapsed,
                timed_out: false,
                command_program: program,
                command_args: args,
            };
        }
    };

    // Wait with timeout using try_wait polling
    let poll_interval = Duration::from_millis(50);
    let timed_out = loop {
        match child.try_wait() {
            Ok(Some(_status)) => {
                break false; // completed
            }
            Ok(None) => {
                // still running
                if start.elapsed() >= timeout {
                    let _ = child.kill();
                    // Wait for kill to take effect
                    let _ = child.wait();
                    break true; // timed out
                }
                std::thread::sleep(poll_interval);
            }
            Err(e) => {
                let elapsed = start.elapsed();
                return CommandResult {
                    exit_code: -1,
                    stdout: String::new(),
                    stderr: format!("error waiting for command: {}", e),
                    duration: elapsed,
                    timed_out: false,
                    command_program: program,
                    command_args: args,
                };
            }
        }
    };

    let output = child.wait_with_output().ok();
    let elapsed = start.elapsed();

    let (exit_code, stdout, stderr) = match output {
        Some(o) => (
            o.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&o.stdout).to_string(),
            String::from_utf8_lossy(&o.stderr).to_string(),
        ),
        None => (-1, String::new(), "failed to collect output".to_string()),
    };

    CommandResult {
        exit_code,
        stdout,
        stderr,
        duration: elapsed,
        timed_out,
        command_program: program,
        command_args: args,
    }
}

/// Run a sequence step.
pub fn run_step(
    step: &Step,
    cwd: &Path,
    timeout: Duration,
    extra_env: &[(String, String)],
) -> CommandResult {
    run_command(&step.command, cwd, cwd, timeout, extra_env)
}

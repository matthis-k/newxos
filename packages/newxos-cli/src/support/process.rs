use std::ffi::OsStr;
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

use crate::error::{CliError, Result};

pub fn exec_replace<S: AsRef<OsStr>>(program: &str, args: &[S]) -> Result<()> {
    let err = Command::new(program).args(args).exec();
    Err(CliError::Message(format!("failed to exec {}: {}", program, err)))
}

pub fn run_status<S: AsRef<OsStr>>(program: &str, args: &[S]) -> Result<i32> {
    let status = Command::new(program)
        .args(args)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()?;

    Ok(status.code().unwrap_or(1))
}

#[allow(dead_code)]
pub fn run_output<S: AsRef<OsStr>>(program: &str, args: &[S]) -> Result<String> {
    let output = Command::new(program)
        .args(args)
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .output()?;

    if !output.status.success() {
        return Err(CliError::Message(format!(
            "{} exited with code {}",
            program,
            output.status.code().unwrap_or(1)
        )));
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

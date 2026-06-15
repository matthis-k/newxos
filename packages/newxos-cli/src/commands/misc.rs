use std::env;
use std::process::Command;

use crate::error::{CliError, Result};
use crate::support::process::{exec_replace, run_status};
use crate::support::repo::repo_root;

pub fn ai() -> Result<i32> {
    let root = repo_root()?;

    if which("opencode").is_err() {
        return Err(CliError::Message(
            "opencode not available (build this system with the opencode module)".to_string(),
        ));
    }

    env::set_current_dir(&root)?;
    exec_replace("opencode", &[] as &[&str])?;
    Ok(0)
}

pub fn git() -> Result<i32> {
    let root = repo_root()?;
    env::set_current_dir(&root)?;

    let has_lg = Command::new("git")
        .args(["lg"])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false);

    if has_lg {
        exec_replace("git", &["lg"])?;
    } else {
        exec_replace(
            "git",
            &["log", "--graph", "--decorate", "--oneline", "--all"],
        )?;
    }
    Ok(0)
}

pub fn reload_shell() -> Result<i32> {
    run_status("systemctl", &["--user", "restart", "newshell"])
}

pub fn dev_mode() -> Result<i32> {
    let value = env::var("NEWXOS_DEV")
        .or_else(|_| env::var("DEVMODE"))
        .unwrap_or_else(|_| "0".to_string());
    println!("{}", value);
    Ok(0)
}

fn which(program: &str) -> Result<()> {
    let status = Command::new("command")
        .args(["-v", program])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()?;

    if status.success() {
        Ok(())
    } else {
        Err(CliError::Message(format!("{} not found in PATH", program)))
    }
}

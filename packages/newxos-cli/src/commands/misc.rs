use std::env;
use std::os::unix::fs::PermissionsExt;
use std::path::Path;
use std::process::Command;

use crate::error::{CliError, Result};
use crate::support::process::{exec_replace, run_status};
use crate::support::repo::repo_root;

pub fn ai() -> Result<i32> {
    let root = repo_root()?;

    which("opencode").map_err(|e| {
        CliError::Message(format!(
            "opencode not available: {} (build this system with the opencode module, or add packages.opencode to the wrapper PATH)",
            e,
        ))
    })?;

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
    let path =
        env::var_os("PATH").ok_or_else(|| CliError::Message("PATH is not set".to_string()))?;

    let count = env::split_paths(&path).count();

    for dir in env::split_paths(&path) {
        let candidate = dir.join(program);
        if candidate.is_file() && is_executable(&candidate) {
            return Ok(());
        }
    }

    Err(CliError::Message(format!(
        "{program} not found in PATH (checked {count} directories)",
    )))
}

#[cfg(unix)]
fn is_executable(path: &Path) -> bool {
    path.metadata()
        .ok()
        .map(|m| m.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

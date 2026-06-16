use std::path::Path;
use std::process::{Command, Stdio};

use crate::error::{CliError, Result};

pub fn nixos_hosts(root: &Path) -> Result<Vec<String>> {
    let modules_dir = root.join("modules");
    let output = Command::new("rg")
        .args([
            "--no-filename",
            "--only-matching",
            "--replace",
            "$1",
            r"flake\.nixosConfigurations\.([[:alnum:]_.+-]+)",
        ])
        .arg(&modules_dir)
        .args(["-g", "*.nix"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()?;

    let mut hosts: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    hosts.sort();
    hosts.dedup();
    Ok(hosts)
}

pub fn home_configs(root: &Path) -> Result<Vec<String>> {
    let modules_dir = root.join("modules");
    let output = Command::new("rg")
        .args([
            "--no-filename",
            "--only-matching",
            "--replace",
            "$1",
            r"flake\.homeConfigurations\.([[:alnum:]_.+-]+)",
        ])
        .arg(&modules_dir)
        .args(["-g", "*.nix"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()?;

    let mut configs: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    configs.sort();
    configs.dedup();
    Ok(configs)
}

pub fn run_targets(root: &Path) -> Result<Vec<String>> {
    let modules_dir = root.join("modules");
    let output = Command::new("rg")
        .args([
            "--no-filename",
            "--only-matching",
            "--replace",
            "$1",
            r"^\s*packages\.([a-zA-Z0-9_.-]+)\s*=",
        ])
        .arg(&modules_dir)
        .args(["-g", "*.nix"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()?;

    let mut targets: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    targets.sort();
    targets.dedup();
    Ok(targets)
}

pub fn require_nixos_host(root: &Path, host: &str) -> Result<()> {
    let hosts = nixos_hosts(root)?;
    if hosts.iter().any(|h| h == host) {
        Ok(())
    } else {
        Err(CliError::Message(format!("unknown nixos host: {}", host)))
    }
}

pub fn require_home_config(root: &Path, config: &str) -> Result<()> {
    let configs = home_configs(root)?;
    if configs.iter().any(|c| c == config) {
        Ok(())
    } else {
        Err(CliError::Message(format!("unknown home config: {}", config)))
    }
}

pub fn default_nixos_host(root: &Path) -> Result<String> {
    let host = std::env::var("NEWXOS_HOST")
        .map_err(|_| CliError::Message("missing host arg and NEWXOS_HOST is unset".to_string()))?;

    if host.is_empty() {
        return Err(CliError::Message(
            "missing host arg and NEWXOS_HOST is unset".to_string(),
        ));
    }

    require_nixos_host(root, &host)?;
    Ok(host)
}

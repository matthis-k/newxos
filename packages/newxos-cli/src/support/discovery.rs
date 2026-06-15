use std::path::Path;
use std::process::{Command, Stdio};

use crate::error::{CliError, Result};
use crate::support::repo;

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
    let system_output = Command::new("nix")
        .args(["eval", "--impure", "--raw", "--expr", "builtins.currentSystem"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()?;

    let system = String::from_utf8_lossy(&system_output.stdout).trim().to_string();

    let flake_ref = repo::FlakeMode::Path.flake_ref(root);
    let show_output = Command::new("nix")
        .args(["flake", "show", "--json", &flake_ref])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()?;

    let json: serde_json::Value =
        serde_json::from_slice(&show_output.stdout).map_err(|e| {
            CliError::Message(format!("failed to parse nix flake show output: {}", e))
        })?;

    let mut targets = Vec::new();

    if let Some(packages) = json
        .get("packages")
        .and_then(|p| p.get(&system))
        .and_then(|p| p.as_object())
    {
        targets.extend(packages.keys().cloned());
    }

    if let Some(apps) = json
        .get("apps")
        .and_then(|a| a.get(&system))
        .and_then(|a| a.as_object())
    {
        targets.extend(apps.keys().cloned());
    }

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

use std::path::Path;
use std::process::{Command, Stdio};

use crate::error::{CliError, Result};

fn current_system() -> String {
    let arch = std::env::consts::ARCH;
    let os = std::env::consts::OS;
    let os = match os {
        "linux" => "linux",
        "macos" => "darwin",
        other => other,
    };
    format!("{}-{}", arch, os)
}

fn flake_show_json(root: &Path) -> Result<serde_json::Value> {
    let output = Command::new("nix")
        .args([
            "flake",
            "show",
            "--json",
            &format!("path:{}", root.display()),
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()?;

    if !output.status.success() {
        return Err(CliError::Message(format!(
            "nix flake show failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    Ok(serde_json::from_slice(&output.stdout)?)
}

fn attr_names_at(json: &serde_json::Value, path: &[&str]) -> Vec<String> {
    let mut current = json;
    for key in path {
        match current.get(*key) {
            Some(val) => current = val,
            None => return vec![],
        }
    }

    match current {
        serde_json::Value::Object(map) => {
            let mut names: Vec<String> = map.keys().cloned().collect();
            names.sort();
            names
        }
        _ => vec![],
    }
}

pub fn nixos_hosts(root: &Path) -> Result<Vec<String>> {
    let json = flake_show_json(root)?;
    Ok(attr_names_at(&json, &["nixosConfigurations"]))
}

pub fn home_configs(root: &Path) -> Result<Vec<String>> {
    let json = flake_show_json(root)?;
    Ok(attr_names_at(&json, &["homeConfigurations"]))
}

pub fn run_targets(root: &Path) -> Result<Vec<String>> {
    let json = flake_show_json(root)?;
    let system = current_system();
    Ok(attr_names_at(&json, &["packages", &system]))
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

#[cfg(test)]
mod tests {
    use super::*;

    fn make_json_with(packages: &[&str], nixos: &[&str], home: &[&str]) -> serde_json::Value {
        let mut pkgs = serde_json::Map::new();
        for p in packages {
            pkgs.insert(p.to_string(), serde_json::json!("N"));
        }
        let mut nixos_map = serde_json::Map::new();
        for h in nixos {
            nixos_map.insert(h.to_string(), serde_json::json!("N"));
        }
        let mut home_map = serde_json::Map::new();
        for h in home {
            home_map.insert(h.to_string(), serde_json::json!("N"));
        }

        let mut root = serde_json::Map::new();
        let mut packages_obj = serde_json::Map::new();
        packages_obj.insert(current_system(), serde_json::Value::Object(pkgs));
        root.insert("packages".to_string(), serde_json::Value::Object(packages_obj));
        root.insert("nixosConfigurations".to_string(), serde_json::Value::Object(nixos_map));
        root.insert("homeConfigurations".to_string(), serde_json::Value::Object(home_map));
        serde_json::Value::Object(root)
    }

    #[test]
    fn extracts_nixos_hosts() {
        let json = make_json_with(&[], &["host-a", "host-b"], &[]);
        let names = attr_names_at(&json, &["nixosConfigurations"]);
        assert_eq!(names, vec!["host-a", "host-b"]);
    }

    #[test]
    fn extracts_home_configs() {
        let json = make_json_with(&[], &[], &["user@host"]);
        let names = attr_names_at(&json, &["homeConfigurations"]);
        assert_eq!(names, vec!["user@host"]);
    }

    #[test]
    fn extracts_run_targets() {
        let json = make_json_with(&["write-flake", "fmt"], &[], &[]);
        let system = current_system();
        let names = attr_names_at(&json, &["packages", &system]);
        assert_eq!(names, vec!["fmt", "write-flake"]);
    }

    #[test]
    fn missing_section_returns_empty() {
        let json = serde_json::json!({});
        assert!(attr_names_at(&json, &["nixosConfigurations"]).is_empty());
    }

    #[test]
    fn host_validation_passes() {
        let json = make_json_with(&[], &["myhost"], &[]);
        let names = attr_names_at(&json, &["nixosConfigurations"]);
        assert!(names.contains(&"myhost".to_string()));
    }
}

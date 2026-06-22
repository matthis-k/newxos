use std::path::Path;

use crate::error::Result;
use crate::support::repo;
use crate::support::process::run_status;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommandPlan {
    pub program: String,
    pub args: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyAccess {
    Unreadable,
    User,
    Sudo,
}

fn build_iso_attr(root: &Path) -> String {
    format!(
        "path:{}#nixosConfigurations.newxos-live-usb.config.system.build.isoImage",
        root.display()
    )
}

pub fn build_iso_plan(root: &Path, key: Option<&str>, key_access: KeyAccess) -> Result<CommandPlan> {
    let attr = build_iso_attr(root);

    let Some(key_path) = key else {
        return Ok(CommandPlan {
            program: "nix".to_string(),
            args: vec!["build".to_string(), attr],
        });
    };

    let key_path_str = key_path.to_string();

    match key_access {
        KeyAccess::Unreadable => {
            return Err(format!("missing key: {}", key_path).into());
        }
        KeyAccess::User => {
            let env_var = format!("NEWXOS_INSTALLER_SOPS_KEY={}", key_path_str);
            Ok(CommandPlan {
                program: "env".to_string(),
                args: vec![
                    env_var.clone(),
                    "nix".to_string(),
                    "build".to_string(),
                    "--impure".to_string(),
                    attr,
                ],
            })
        }
        KeyAccess::Sudo => Ok(CommandPlan {
            program: "sudo".to_string(),
            args: vec![
                "env".to_string(),
                format!("NEWXOS_INSTALLER_SOPS_KEY={}", key_path_str),
                "nix".to_string(),
                "build".to_string(),
                "--impure".to_string(),
                attr,
            ],
        }),
    }
}

pub fn run(key: Option<String>) -> Result<i32> {
    let root = repo::repo_root()?;

    let Some(key_path) = key else {
        let attr = build_iso_attr(&root);
        return run_status("nix", &["build", &attr]);
    };

    let user_can_see_key = std::path::Path::new(&key_path).exists();
    let root_can_see_key = run_status("sudo", &["test", "-e", &key_path]).unwrap_or(1) == 0;

    let key_access = if user_can_see_key {
        KeyAccess::User
    } else if root_can_see_key {
        KeyAccess::Sudo
    } else {
        KeyAccess::Unreadable
    };

    let plan = build_iso_plan(&root, Some(&key_path), key_access)?;

    run_status(&plan.program, &plan.args.iter().map(|s| s.as_str()).collect::<Vec<_>>())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    #[test]
    fn no_key_produces_nix_build_without_impure() {
        let root = Path::new("/home/user/newxos");
        let plan = build_iso_plan(root, None, KeyAccess::Unreadable).unwrap();
        assert_eq!(plan.program, "nix");
        assert!(plan.args.iter().any(|a| a == "build"));
        assert!(!plan.args.iter().any(|a| a == "--impure"));
        assert!(plan.args.iter().any(|a| a.contains("nixosConfigurations.newxos-live-usb")));
    }

    #[test]
    fn user_readable_key_passes_env_var() {
        let root = Path::new("/home/user/newxos");
        let plan = build_iso_plan(root, Some("/home/user/key.txt"), KeyAccess::User).unwrap();
        assert_eq!(plan.program, "env");
        assert!(plan.args.iter().any(|a| a.starts_with("NEWXOS_INSTALLER_SOPS_KEY=")));
        assert!(plan.args.iter().any(|a| a == "--impure"));
    }

    #[test]
    fn sudo_key_passes_env_var_via_sudo() {
        let root = Path::new("/home/user/newxos");
        let plan = build_iso_plan(root, Some("/root/key.txt"), KeyAccess::Sudo).unwrap();
        assert_eq!(plan.program, "sudo");
        assert_eq!(plan.args[0], "env");
        assert!(plan.args[1].starts_with("NEWXOS_INSTALLER_SOPS_KEY="));
        assert!(plan.args.iter().any(|a| a == "--impure"));
    }

    #[test]
    fn missing_key_returns_error() {
        let root = Path::new("/home/user/newxos");
        let result = build_iso_plan(root, Some("/nonexistent/key.txt"), KeyAccess::Unreadable);
        assert!(result.is_err());
    }


}

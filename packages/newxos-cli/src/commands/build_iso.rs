use crate::error::Result;
use crate::support::repo;
use crate::support::process::run_status;

pub fn run(key: Option<String>) -> Result<i32> {
    let root = repo::repo_root()?;
    let iso_attr = format!(
        "path:{}#nixosConfigurations.newxos-live-usb.config.system.build.isoImage",
        root.display()
    );

    match key {
        Some(key_path) => {
            let key_exists = std::path::Path::new(&key_path).exists()
                || run_status("sudo", &["test", "-e", &key_path]).unwrap_or(1) == 0;

            if !key_exists {
                return Err(format!("missing key: {}", key_path).into());
            }

            if std::path::Path::new(&key_path).exists() {
                run_status(
                    "nix",
                    &["build", "--impure", &iso_attr],
                )
                .map(|_| 0)
            } else {
                run_status(
                    "sudo",
                    &[
                        "env",
                        &format!("NEWXOS_INSTALLER_SOPS_KEY={}", key_path),
                        "nix",
                        "build",
                        "--impure",
                        &iso_attr,
                    ],
                )
            }
        }
        None => run_status("nix", &["build", &iso_attr]),
    }
}

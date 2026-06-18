use crate::cli::FlakeAction;
use crate::error::Result;
use crate::support::discovery;
use crate::support::repo;
use crate::support::process::run_status;

pub fn run(action: FlakeAction) -> Result<i32> {
    let root = repo::repo_root()?;

    match action {
        FlakeAction::Build { host, git_only } => {
            let mode = repo::FlakeMode::from_git_only(git_only);
            let flake_ref = mode.flake_ref(&root);

            let host = match host {
                Some(h) => {
                    discovery::require_nixos_host(&root, &h)?;
                    h
                }
                None => discovery::default_nixos_host(&root)?,
            };

            let attr = format!(
                "{}#nixosConfigurations.{}.config.system.build.toplevel",
                flake_ref, host
            );
            run_status("nom", &["build", &attr])
        }

        FlakeAction::Check { host, git_only } => {
            let mode = repo::FlakeMode::from_git_only(git_only);
            let flake_ref = mode.flake_ref(&root);

            if let Some(h) = &host {
                discovery::require_nixos_host(&root, h)?;
            }

            run_status(
                "bash",
                &[
                    "-c",
                    &format!(
                        "nix --log-format internal-json -v flake check \"{}\" |& nom --json",
                        flake_ref
                    ),
                ],
            )
        }

        FlakeAction::Show { git_only } => {
            let mode = repo::FlakeMode::from_git_only(git_only);
            let flake_ref = mode.flake_ref(&root);

            run_status("nix", &["flake", "show", &flake_ref])
        }

        FlakeAction::Run { attr, git_only } => {
            let mode = repo::FlakeMode::from_git_only(git_only);
            let flake_ref = mode.flake_ref(&root);

            let targets = discovery::run_targets(&root)?;
            if !targets.iter().any(|t| t == &attr) {
                return Err(format!("unknown run target: {}", attr).into());
            }

            let build_attr = format!("{}#{}", flake_ref, attr);
            run_status("nom", &["build", &build_attr])?;
            run_status("nix", &["run", &build_attr])
        }
    }
}

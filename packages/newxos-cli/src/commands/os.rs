use crate::cli::OsAction;
use crate::error::Result;
use crate::support::discovery;
use crate::support::repo;
use crate::support::process::run_status;

pub fn run(action: OsAction) -> Result<i32> {
    let root = repo::repo_root()?;

    let (action_name, host, git_only) = match &action {
        OsAction::Switch { host, git_only } => ("switch", host, git_only),
        OsAction::Boot { host, git_only } => ("boot", host, git_only),
        OsAction::Build { host, git_only } => ("build", host, git_only),
    };

    let mode = repo::FlakeMode::from_git_only(*git_only);
    let flake_ref = mode.flake_ref(&root);

    let host = match host {
        Some(h) => {
            discovery::require_nixos_host(&root, h)?;
            h.clone()
        }
        None => discovery::default_nixos_host(&root)?,
    };

    run_status("nh", &["os", action_name, &flake_ref, "-H", &host])
}

use crate::error::Result;
use crate::support::discovery;
use crate::support::repo;
use crate::support::process::run_status;

pub fn run(action: &str, config: &str, git_only: bool) -> Result<i32> {
    let root = repo::repo_root()?;
    let mode = repo::FlakeMode::from_git_only(git_only);
    let flake_ref = mode.flake_ref(&root);

    discovery::require_home_config(&root, config)?;

    run_status("nh", &["home", action, &flake_ref, "-c", config])
}

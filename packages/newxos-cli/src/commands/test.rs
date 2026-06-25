use crate::error::Result;
use crate::support::process::run_status;
use crate::support::repo;

pub fn run(git_only: bool) -> Result<i32> {
    let root = repo::repo_root()?;
    let mode = repo::FlakeMode::from_git_only(git_only);
    let flake_ref = mode.flake_ref(&root);
    let attr = format!("{}#test", flake_ref);

    run_status("nom", &["build", &attr])
}

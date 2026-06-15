use std::env;
use std::path::PathBuf;

use crate::error::{CliError, Result};

pub fn repo_root() -> Result<PathBuf> {
    let root = env::var_os("NEWXOS_FLAKE")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            let home = env::var("HOME").expect("HOME not set");
            PathBuf::from(home).join("newxos")
        });

    if !root.is_dir() {
        return Err(CliError::Message(format!("missing repo at {}", root.display())));
    }
    if !root.join("flake.nix").exists() {
        return Err(CliError::Message(format!("missing flake at {}", root.display())));
    }

    Ok(root)
}

pub fn install_repo_root() -> Result<PathBuf> {
    if let Some(root) = env::var_os("NEWXOS_FLAKE") {
        let root = PathBuf::from(root);
        if !root.is_dir() {
            return Err(CliError::Message(format!("missing repo at {}", root.display())));
        }
        if !root.join("flake.nix").exists() {
            return Err(CliError::Message(format!("missing flake at {}", root.display())));
        }
        return Ok(root);
    }

    let etc_root = PathBuf::from("/etc/newxos");
    if etc_root.join("flake.nix").exists() {
        return Ok(etc_root);
    }

    let home = env::var("HOME").expect("HOME not set");
    let root = PathBuf::from(home).join("newxos");
    if !root.is_dir() {
        return Err(CliError::Message(format!("missing repo at {}", root.display())));
    }
    if !root.join("flake.nix").exists() {
        return Err(CliError::Message(format!("missing flake at {}", root.display())));
    }

    Ok(root)
}

#[derive(Clone, Copy)]
pub enum FlakeMode {
    Path,
    Git,
}

impl FlakeMode {
    pub fn from_git_only(git_only: bool) -> Self {
        if git_only {
            FlakeMode::Git
        } else {
            FlakeMode::Path
        }
    }

    pub fn flake_ref(&self, root: &std::path::Path) -> String {
        match self {
            FlakeMode::Path => format!("path:{}", root.display()),
            FlakeMode::Git => format!("git+file://{}", root.display()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    #[test]
    fn flake_ref_path_mode() {
        let mode = FlakeMode::Path;
        let root = Path::new("/home/user/newxos");
        assert_eq!(mode.flake_ref(root), "path:/home/user/newxos");
    }

    #[test]
    fn flake_ref_git_mode() {
        let mode = FlakeMode::Git;
        let root = Path::new("/home/user/newxos");
        assert_eq!(mode.flake_ref(root), "git+file:///home/user/newxos");
    }

    #[test]
    fn from_git_only_true() {
        match FlakeMode::from_git_only(true) {
            FlakeMode::Git => {}
            _ => panic!("expected Git mode"),
        }
    }

    #[test]
    fn from_git_only_false() {
        match FlakeMode::from_git_only(false) {
            FlakeMode::Path => {}
            _ => panic!("expected Path mode"),
        }
    }
}

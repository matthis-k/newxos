use std::path::{Path, PathBuf};

use crate::config::{ConfigFragment, Result};
use crate::error::HandoffError;

pub fn discover_configs(repo_root: &Path) -> Result<Vec<(PathBuf, ConfigFragment)>> {
    // Try rg first
    let output = std::process::Command::new("rg")
        .args(["--files", "-g", ".handoff.json", "-g", "*.handoff.json"])
        .arg(repo_root)
        .output();

    let paths = match output {
        Ok(out) if out.status.success() => {
            let stdout = String::from_utf8_lossy(&out.stdout);
            let mut paths: Vec<PathBuf> = stdout
                .lines()
                .map(|l| PathBuf::from(l.trim()))
                .filter(|p| !p.as_os_str().is_empty())
                .collect();

            // Sort deterministically: root first, shallower before deeper, then lexicographic
            paths.sort_by(|a, b| {
                let depth_a = a.components().count();
                let depth_b = b.components().count();
                depth_a.cmp(&depth_b).then(a.cmp(b))
            });

            paths
        }
        Ok(_) => Vec::new(),
        Err(_) => return Err(HandoffError::NoRipgrep),
    };

    let mut fragments = Vec::new();
    for p in &paths {
        match crate::config::load_fragment(p) {
            Ok(f) => fragments.push((p.clone(), f)),
            Err(e) => {
                eprintln!("warning: failed to load {}: {}", p.display(), e);
                continue;
            }
        }
    }

    Ok(fragments)
}

pub fn load_explicit_configs(paths: &[PathBuf]) -> Result<Vec<(PathBuf, ConfigFragment)>> {
    let mut fragments = Vec::new();
    for p in paths {
        let canonical = if p.is_absolute() {
            p.clone()
        } else {
            std::env::current_dir()
                .map(|cwd| cwd.join(p))
                .unwrap_or_else(|_| p.clone())
        };
        let fragment = crate::config::load_fragment(&canonical)?;
        fragments.push((canonical, fragment));
    }
    Ok(fragments)
}

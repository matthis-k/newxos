use std::path::Path;

use globset::{Glob, GlobSetBuilder};

fn build_glob_set(patterns: &[String], base_dir: &Path, repo_root: &Path) -> Option<globset::GlobSet> {
    if patterns.is_empty() {
        return None;
    }

    let mut builder = GlobSetBuilder::new();
    for pattern in patterns {
        if !Path::new(pattern).is_relative() {
            if let Ok(glob) = Glob::new(pattern) {
                builder.add(glob);
            }
            continue;
        }

        let full_pattern = if base_dir == repo_root {
            // base: "repo" — patterns are already repo-relative
            pattern.clone()
        } else {
            // base: "config" — prefix with config dir relative to repo
            let rel = base_dir.strip_prefix(repo_root)
                .unwrap_or(base_dir);
            let rel_str = rel.to_string_lossy().replace('\\', "/");
            let rel_trimmed = rel_str.trim_end_matches('/');
            format!("{}/{}", rel_trimmed, pattern)
        };

        if let Ok(glob) = Glob::new(&full_pattern) {
            builder.add(glob);
        }
    }

    builder.build().ok()
}

fn normalize_path(path: &str) -> String {
    path.replace('\\', "/")
}

/// Check if a path matches any of the given glob patterns.
/// When `base_dir == repo_root`, patterns are repo-relative.
/// Otherwise patterns are relative to `base_dir` (config-relative).
pub fn matches_any(path: &str, patterns: &[String], base_dir: &Path, repo_root: &Path) -> bool {
    let Some(glob_set) = build_glob_set(patterns, base_dir, repo_root) else {
        return false;
    };
    let norm_path = normalize_path(path);
    glob_set.is_match(&norm_path)
}

/// Check if ALL paths match at least one pattern in the set.
pub fn matches_all(paths: &[String], patterns: &[String], base_dir: &Path, repo_root: &Path) -> bool {
    let Some(glob_set) = build_glob_set(patterns, base_dir, repo_root) else {
        return false;
    };
    paths.iter().all(|p| glob_set.is_match(normalize_path(p)))
}

/// Check that NONE of the paths match any pattern in the set.
pub fn matches_none(paths: &[String], patterns: &[String], base_dir: &Path, repo_root: &Path) -> bool {
    let Some(glob_set) = build_glob_set(patterns, base_dir, repo_root) else {
        return true;
    };
    !paths.iter().any(|p| glob_set.is_match(normalize_path(p)))
}

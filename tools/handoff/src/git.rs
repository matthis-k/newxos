use std::collections::HashSet;
use std::path::PathBuf;

use crate::error::HandoffError;

pub type Result<T> = std::result::Result<T, HandoffError>;

/// Detect the repo root by running `git rev-parse --show-toplevel`.
pub fn detect_repo_root() -> Result<PathBuf> {
    let output = std::process::Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output()
        .map_err(|_| HandoffError::Other("failed to run git rev-parse".to_string()))?;

    if !output.status.success() {
        return Err(HandoffError::Other(
            "not inside a git repository".to_string(),
        ));
    }

    let root = String::from_utf8_lossy(&output.stdout)
        .trim()
        .to_string();
    Ok(PathBuf::from(root))
}

/// Get changed files from the working tree (unstaged + staged + untracked).
pub fn working_tree_changed(repo_root: &std::path::Path) -> Result<Vec<String>> {
    let mut files = Vec::new();

    // Unstaged modified
    let out = run_git(repo_root, &["diff", "--name-only"])?;
    files.extend(out.lines().map(|l| l.to_string()));

    // Staged
    let out = run_git(repo_root, &["diff", "--cached", "--name-only"])?;
    files.extend(out.lines().map(|l| l.to_string()));

    // Untracked
    let out = run_git(repo_root, &["ls-files", "--others", "--exclude-standard"])?;
    files.extend(out.lines().map(|l| l.to_string()));

    // Deduplicate preserving order
    let mut seen = HashSet::new();
    files.retain(|f| seen.insert(f.clone()));

    Ok(files)
}

/// Get changed files for staged changes only (for commit hooks).
pub fn staged_changed(repo_root: &std::path::Path) -> Result<Vec<String>> {
    let out = run_git(repo_root, &[
        "diff",
        "--cached",
        "--name-only",
        "--diff-filter=ACMRTD",
    ])?;
    let files: Vec<String> = out.lines().map(|l| l.to_string()).collect();
    Ok(files)
}

/// Get changed files between refs.
pub fn ref_changed(repo_root: &std::path::Path, from: &str, to: Option<&str>) -> Result<Vec<String>> {
    let mut args: Vec<String> = vec!["diff".to_string(), "--name-only".to_string()];
    match to {
        Some(t) => {
            args.push(from.to_string());
            args.push(t.to_string());
        }
        None => {
            args.push(format!("{}..HEAD", from));
        }
    }
    args.push("--".to_string());
    args.push(".".to_string());
    let str_refs: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
    let out = run_git(repo_root, &str_refs)?;
    let files: Vec<String> = out.lines().map(|l| l.to_string()).collect();
    Ok(files)
}

fn run_git(repo_root: &std::path::Path, args: &[&str]) -> Result<String> {
    let output = std::process::Command::new("git")
        .args(args)
        .current_dir(repo_root)
        .output()
        .map_err(|e| HandoffError::Other(format!("git command failed: {}", e)))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(HandoffError::Other(format!("git error: {}", stderr)));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

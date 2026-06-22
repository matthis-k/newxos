use std::io::Write;
use std::path::Path;
use std::process::{Command, Stdio};

use crate::cli::MemoryAction;
use crate::error::Result;
use crate::support::repo::repo_root;

pub fn basic_memory_config(memory_root: &Path) -> String {
    format!(
        r#"{{
  "default_project": "newxos",
  "projects": {{
    "newxos": {{
      "path": "{}",
      "mode": "local"
    }}
  }},
  "semantic_search_enabled": true,
  "semantic_embedding_provider": "fastembed",
  "cloud_mode": false
}}
"#,
        memory_root.display()
    )
}

pub fn run(action: MemoryAction) -> Result<i32> {
    let root = repo_root()?;
    let memory_root = root.join("docs");
    let state_root = root.join(".cache/basic-memory");

    std::fs::create_dir_all(&memory_root)?;
    std::fs::create_dir_all(&state_root)?;

    let config = basic_memory_config(&memory_root);
    std::fs::write(state_root.join("config.json"), config)?;

    let state_root_str = state_root.to_string_lossy().to_string();

    let mut cmd = Command::new("basic-memory");
    match action {
        MemoryAction::Reindex => {
            cmd.args(["reindex", "--project", "newxos"]);
            cmd.stdin(Stdio::inherit());
        }
        MemoryAction::Reset => {
            cmd.args(["reset", "--reindex"]);
            cmd.stdin(Stdio::piped());
        }
    }

    cmd.env("BASIC_MEMORY_CONFIG_DIR", &state_root_str)
        .env("BASIC_MEMORY_MCP_PROJECT", "newxos")
        .env("BASIC_MEMORY_SEMANTIC_SEARCH_ENABLED", "true")
        .env("BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER", "fastembed")
        .env("BASIC_MEMORY_NO_PROMOS", "1")
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit());

    match action {
        MemoryAction::Reset => {
            let mut child = cmd.spawn()?;
            let stdin = child.stdin.as_mut()
                .ok_or_else(|| "failed to open basic-memory reset stdin".to_string())?;
            stdin.write_all(b"y\n")?;
            let status = child.wait()?;
            Ok(status.code().unwrap_or(1))
        }
        MemoryAction::Reindex => {
            let status = cmd.status()?;
            Ok(status.code().unwrap_or(1))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    #[test]
    fn config_contains_docs_path() {
        let config = basic_memory_config(Path::new("/repo/docs"));
        assert!(config.contains("/repo/docs"));
        assert!(!config.contains("knowledge"));
    }

    #[test]
    fn config_is_valid_json() {
        let config = basic_memory_config(Path::new("/repo/docs"));
        let parsed: serde_json::Value = serde_json::from_str(&config)
            .expect("config should be valid JSON");
        assert_eq!(parsed["default_project"], "newxos");
        assert_eq!(parsed["projects"]["newxos"]["path"], "/repo/docs");
        assert_eq!(parsed["projects"]["newxos"]["mode"], "local");
        assert_eq!(parsed["semantic_search_enabled"], true);
    }
}

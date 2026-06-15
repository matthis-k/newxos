use std::io::Write;
use std::process::{Command, Stdio};

use crate::cli::MemoryAction;
use crate::error::Result;
use crate::support::repo::repo_root;

pub fn run(action: MemoryAction) -> Result<i32> {
    let root = repo_root()?;
    let memory_root = root.join("knowledge");
    let state_root = root.join(".cache/basic-memory");

    std::fs::create_dir_all(&memory_root)?;
    std::fs::create_dir_all(&state_root)?;

    let config = format!(
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
    );

    std::fs::write(state_root.join("config.json"), config)?;

    let state_root_str = state_root.to_string_lossy().to_string();

    let mut cmd = match action {
        MemoryAction::Reindex => {
            let mut cmd = Command::new("basic-memory");
            cmd.args(["reindex", "--project", "newxos"]);
            cmd
        }
        MemoryAction::Reset => {
            let mut cmd = Command::new("basic-memory");
            cmd.args(["reset", "--reindex"]);
            cmd.stdin(Stdio::piped());
            cmd
        }
    };

    cmd.env("BASIC_MEMORY_CONFIG_DIR", &state_root_str)
        .env("BASIC_MEMORY_MCP_PROJECT", "newxos")
        .env("BASIC_MEMORY_SEMANTIC_SEARCH_ENABLED", "true")
        .env("BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER", "fastembed")
        .env("BASIC_MEMORY_NO_PROMOS", "1")
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit());

    if matches!(action, MemoryAction::Reset) {
        let mut child = cmd.spawn()?;
        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(b"y\n")?;
        }
        let status = child.wait()?;
        Ok(status.code().unwrap_or(1))
    } else {
        let status = cmd.status()?;
        Ok(status.code().unwrap_or(1))
    }
}

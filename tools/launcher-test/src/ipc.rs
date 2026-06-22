use anyhow::{Context, Result};
use std::process::Command;
use std::time::Duration;

use crate::schema::LauncherState;

pub struct LauncherIpc {
    newshell_bin: String,
}

impl LauncherIpc {
    pub fn new() -> Result<Self> {
        // Try to find the newshell binary
        let newshell_bin = which_newshell()?;
        Ok(Self { newshell_bin })
    }

    /// Send a generic IPC call and return the raw JSON string
    pub fn call(&self, target: &str, method: &str, arg: &str) -> Result<String> {
        let output = Command::new(&self.newshell_bin)
            .args(["ipc", "call", target, method, arg])
            .output()
            .context("Failed to execute newshell ipc call")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("newshell ipc call failed: {}", stderr);
        }

        let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
        Ok(stdout)
    }

    /// Send a launcher IPC command via interactJson
    pub fn interact(&self, action: &str, payload: &str) -> Result<String> {
        // Build JSON payload matching what interactJson expects
        let json = if payload.is_empty() {
            format!(r#"{{"action":"{}"}}"#, action)
        } else {
            // Re-wrap to merge action into payload
            let mut v: serde_json::Value =
                serde_json::from_str(payload).unwrap_or(serde_json::Value::Object(Default::default()));
            if let serde_json::Value::Object(ref mut map) = v {
                map.insert("action".to_string(), serde_json::json!(action));
            }
            serde_json::to_string(&v)?
        };
        self.call("launcher", "interactJson", &json)
    }

    /// Reset the launcher state
    pub fn reset(&self) -> Result<String> {
        self.interact("reset", "{}")
    }

    /// Open the launcher
    pub fn open(&self, visible: bool) -> Result<String> {
        self.interact("open", &format!(r#"{{"openArg":{}}}"#, if visible { r#""visible""# } else { r#""headless""# }))
    }

    /// Close the launcher
    pub fn close(&self) -> Result<String> {
        self.interact("close", "{}")
    }

    /// Set the query text
    pub fn set_query(&self, query: &str) -> Result<String> {
        let payload = serde_json::json!({"query": query});
        self.interact("setQuery", &serde_json::to_string(&payload)?)
    }

    /// Type text (append)
    pub fn type_text(&self, text: &str) -> Result<String> {
        let payload = serde_json::json!({"text": text});
        self.interact("typeText", &serde_json::to_string(&payload)?)
    }

    /// Backspace
    pub fn backspace(&self, count: u32) -> Result<String> {
        let payload = serde_json::json!({"count": count});
        self.interact("backspace", &serde_json::to_string(&payload)?)
    }

    /// Move selection
    pub fn move_selection(&self, direction: &str) -> Result<String> {
        let delta = match direction {
            "up" => -1,
            "down" => 1,
            "left" => -1,
            "right" => 1,
            _ => 0,
        };
        let payload = serde_json::json!({"delta": delta});
        self.interact("moveSelection", &serde_json::to_string(&payload)?)
    }

    /// Get the current state via the IPC `state` method (without visual)
    pub fn state(&self) -> Result<LauncherState> {
        let resp = self.call("launcher", "state", "false")?;
        let state: LauncherState = serde_json::from_str(&resp)
            .context("Failed to parse launcher state")?;
        Ok(state)
    }

    /// Get the visual state via the IPC `visualState` method
    pub fn visual_state(&self) -> Result<String> {
        self.call("launcher", "visualState", "")
    }

    /// Wait for model to settle (modelBusy becomes false, generation stable)
    pub fn wait_for_settled(&self, timeout_ms: u64) -> Result<LauncherState> {
        let deadline = std::time::Instant::now() + Duration::from_millis(timeout_ms);
        let mut last_state = self.state()?;

        loop {
            if !last_state.model_busy {
                return Ok(last_state);
            }
            if std::time::Instant::now() > deadline {
                anyhow::bail!(
                    "Launcher state did not settle before timeout ({}ms). \
                     last generation={} query_revision={} model_busy={}",
                    timeout_ms,
                    last_state.generation,
                    last_state.query_revision,
                    last_state.model_busy,
                );
            }
            std::thread::sleep(Duration::from_millis(16));
            last_state = self.state()?;
        }
    }
}

fn which_newshell() -> Result<String> {
    // First check if newshell is in PATH
    if let Ok(path) = std::env::var("PATH") {
        for dir in path.split(':') {
            let candidate = format!("{}/newshell", dir);
            if std::path::Path::new(&candidate).exists() {
                return Ok(candidate);
            }
        }
    }

    // Fall back to checking common locations
    let candidates = vec![
        "newshell".to_string(),
        format!("{}/newshell", std::env::var("HOME").unwrap_or_default()),
        "/run/current-system/sw/bin/newshell".to_string(),
    ];
    for candidate in &candidates {
        if std::path::Path::new(candidate).exists() {
            return Ok(candidate.clone());
        }
    }

    anyhow::bail!(
        "Could not find 'newshell' binary in PATH. \
         Make sure newshell is installed and running."
    );
}

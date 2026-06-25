use std::path::{Path, PathBuf};

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};

use crate::error::HandoffError;

#[derive(Debug, Clone)]
pub struct SourceInfo {
    pub file: PathBuf,
    pub dir: PathBuf,
}

pub type Result<T> = std::result::Result<T, HandoffError>;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum CwdMode {
    Repo,
    Config,
    Invocation,
}

impl Default for CwdMode {
    fn default() -> Self {
        CwdMode::Repo
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum BaseMode {
    Repo,
    Config,
}

impl Default for BaseMode {
    fn default() -> Self {
        BaseMode::Repo
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigFragment {
    pub version: u32,
    #[serde(default)]
    pub base: BaseMode,
    #[serde(default)]
    pub defaults: Defaults,
    #[serde(default)]
    pub groups: IndexMap<String, Group>,
    #[serde(default)]
    pub targets: IndexMap<String, Target>,
    #[serde(default)]
    pub rules: Vec<Rule>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Defaults {
    #[serde(default)]
    pub cwd: Option<CwdMode>,
    #[serde(default, rename = "timeoutSeconds")]
    pub timeout_seconds: Option<u64>,
    #[serde(default)]
    pub expect: Option<Expectation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Group {
    pub description: Option<String>,
    #[serde(default, rename = "beforeAll")]
    pub before_all: Vec<String>,
    #[serde(default, rename = "afterAll")]
    pub after_all: Vec<String>,
    #[serde(default)]
    pub children: Vec<String>,
    #[serde(default)]
    pub r#override: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum Target {
    #[serde(rename = "command")]
    Command(CommandTarget),
    #[serde(rename = "sequence")]
    Sequence(SequenceTarget),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommandTarget {
    pub description: Option<String>,
    #[serde(default)]
    pub cwd: Option<CwdMode>,
    #[serde(default)]
    pub manual: bool,
    pub command: CommandSpec,
    #[serde(default)]
    pub expect: Option<Expectation>,
    #[serde(default, rename = "timeoutSeconds")]
    pub timeout_seconds: Option<u64>,
    #[serde(default)]
    pub tags: Vec<String>,
    #[serde(default)]
    pub r#override: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SequenceTarget {
    pub description: Option<String>,
    #[serde(default)]
    pub cwd: Option<CwdMode>,
    #[serde(default)]
    pub manual: bool,
    pub steps: Vec<Step>,
    #[serde(default)]
    pub r#override: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Step {
    pub id: Option<String>,
    pub command: CommandSpec,
    #[serde(default)]
    pub expect: Option<Expectation>,
    #[serde(default)]
    pub cwd: Option<CwdMode>,
    #[serde(default, rename = "timeoutSeconds")]
    pub timeout_seconds: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommandSpec {
    pub program: Option<String>,
    #[serde(default)]
    pub args: Vec<String>,
    #[serde(default)]
    pub shell: bool,
    pub line: Option<String>,
    #[serde(default)]
    pub env: IndexMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Expectation {
    pub exit: Option<ExitExpectation>,
    #[serde(rename = "exitCode")]
    pub exit_code: Option<i32>,
    #[serde(default, rename = "stdoutContains")]
    pub stdout_contains: Vec<String>,
    #[serde(default, rename = "stderrContains")]
    pub stderr_contains: Vec<String>,
    #[serde(default, rename = "stdoutNotContains")]
    pub stdout_not_contains: Vec<String>,
    #[serde(default, rename = "stderrNotContains")]
    pub stderr_not_contains: Vec<String>,
    #[serde(default, rename = "stdoutRegex")]
    pub stdout_regex: Vec<String>,
    #[serde(default, rename = "stderrRegex")]
    pub stderr_regex: Vec<String>,
    #[serde(default, rename = "stdoutNotRegex")]
    pub stdout_not_regex: Vec<String>,
    #[serde(default, rename = "stderrNotRegex")]
    pub stderr_not_regex: Vec<String>,
    pub verify: Option<VerifySpec>,
}

impl Default for Expectation {
    fn default() -> Self {
        Expectation {
            exit: Some(ExitExpectation::Success),
            exit_code: None,
            stdout_contains: Vec::new(),
            stderr_contains: Vec::new(),
            stdout_not_contains: Vec::new(),
            stderr_not_contains: Vec::new(),
            stdout_regex: Vec::new(),
            stderr_regex: Vec::new(),
            stdout_not_regex: Vec::new(),
            stderr_not_regex: Vec::new(),
            verify: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ExitExpectation {
    Success,
    Failure,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifySpec {
    pub program: String,
    #[serde(default)]
    pub args: Vec<String>,
    #[serde(default)]
    pub stdin: VerifyStdin,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum VerifyStdin {
    Stdout,
    Stderr,
    #[serde(rename = "resultJson")]
    ResultJson,
    None,
}

impl Default for VerifyStdin {
    fn default() -> Self {
        VerifyStdin::ResultJson
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Rule {
    pub id: Option<String>,
    pub description: Option<String>,
    pub when: WhenClause,
    #[serde(default)]
    pub run: Vec<String>,
    #[serde(default)]
    pub r#override: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WhenClause {
    #[serde(default)]
    pub anyChanged: Vec<String>,
    #[serde(default)]
    pub noneChanged: Vec<String>,
    #[serde(default)]
    pub allChanged: Vec<String>,
}

/// Sourced config with source tracking merged.
#[derive(Debug, Clone)]
pub struct Sourced<T> {
    pub source: SourceInfo,
    pub value: T,
}

#[derive(Debug, Clone)]
pub struct MergedConfig {
    pub config_files: Vec<PathBuf>,
    pub defaults: Defaults,
    pub groups: IndexMap<String, Sourced<Group>>,
    pub targets: IndexMap<String, Sourced<Target>>,
    pub rules: Vec<Sourced<Rule>>,
}

impl Default for MergedConfig {
    fn default() -> Self {
        MergedConfig {
            config_files: Vec::new(),
            defaults: Defaults::default(),
            groups: IndexMap::new(),
            targets: IndexMap::new(),
            rules: Vec::new(),
        }
    }
}

pub fn load_fragment(path: &Path) -> Result<ConfigFragment> {
    let content = std::fs::read_to_string(path)
        .map_err(|_| HandoffError::ConfigNotFound(path.to_path_buf()))?;
    let fragment: ConfigFragment = serde_json::from_str(&content)
        .map_err(|e| HandoffError::Other(format!("failed to parse {}: {}", path.display(), e)))?;
    if fragment.version != 1 {
        return Err(HandoffError::UnsupportedVersion(fragment.version, path.to_path_buf()));
    }
    Ok(fragment)
}

pub fn merge_configs(fragments: Vec<(PathBuf, ConfigFragment)>) -> Result<MergedConfig> {
    let mut merged = MergedConfig::default();

    for (path, fragment) in fragments {
        let dir = path.parent().unwrap_or(Path::new(".")).to_path_buf();
        let source = SourceInfo {
            file: path.clone(),
            dir,
        };

        merged.config_files.push(path.clone());

        // Merge defaults
        if let Some(cwd) = fragment.defaults.cwd {
            merged.defaults.cwd = Some(cwd);
        }
        if let Some(timeout) = fragment.defaults.timeout_seconds {
            merged.defaults.timeout_seconds = Some(timeout);
        }
        if fragment.defaults.expect.is_some() {
            merged.defaults.expect = fragment.defaults.expect.clone();
        }

        // Merge groups
        for (id, group) in fragment.groups {
            if let Some(existing) = merged.groups.get(&id) {
                if !group.r#override {
                    let first = existing.source.file.clone();
                    return Err(HandoffError::DuplicateId {
                        kind: "group".to_string(),
                        id: id.clone(),
                        first,
                        second: path.clone(),
                    });
                }
            }
            merged.groups.insert(id, Sourced { source: source.clone(), value: group });
        }

        // Merge targets
        for (id, target) in fragment.targets {
            if let Some(existing) = merged.targets.get(&id) {
                let has_override = match &target {
                    Target::Command(c) => c.r#override,
                    Target::Sequence(s) => s.r#override,
                };
                if !has_override {
                    let first = existing.source.file.clone();
                    return Err(HandoffError::DuplicateId {
                        kind: "target".to_string(),
                        id: id.clone(),
                        first,
                        second: path.clone(),
                    });
                }
            }
            merged.targets.insert(id, Sourced { source: source.clone(), value: target });
        }

        // Merge rules (append)
        for rule in fragment.rules {
            merged.rules.push(Sourced { source: source.clone(), value: rule });
        }
    }

    // Validate for cycles
    validate_cycles(&merged)?;

    Ok(merged)
}

fn validate_cycles(config: &MergedConfig) -> Result<()> {
    // DFS cycle detection on group DAG
    fn has_cycle(
        group_id: &str,
        groups: &IndexMap<String, Sourced<Group>>,
        visited: &mut IndexMap<String, bool>,
        stack: &mut Vec<String>,
    ) -> bool {
        if stack.contains(&group_id.to_string()) {
            return true;
        }
        if let Some(&true) = visited.get(group_id) {
            return false;
        }
        visited.insert(group_id.to_string(), true);
        stack.push(group_id.to_string());

        if let Some(sourced) = groups.get(group_id) {
            for child in &sourced.value.children {
                if groups.contains_key(child) {
                    if has_cycle(child, groups, visited, stack) {
                        return true;
                    }
                }
            }
        }

        stack.pop();
        false
    }

    let group_ids: Vec<String> = config.groups.keys().cloned().collect();
    let mut visited = IndexMap::new();
    let mut stack = Vec::new();

    for gid in &group_ids {
        if has_cycle(gid, &config.groups, &mut visited, &mut stack) {
            return Err(HandoffError::CycleDetected { group: gid.clone() });
        }
    }

    Ok(())
}

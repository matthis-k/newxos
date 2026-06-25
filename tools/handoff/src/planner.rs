
use indexmap::IndexSet;

use crate::config::{MergedConfig, Target};
use crate::error::HandoffError;
use crate::matcher;

pub type Result<T> = std::result::Result<T, HandoffError>;

#[derive(Debug, Clone)]
pub struct SelectionReason {
    pub rule: String,
    pub rule_source: std::path::PathBuf,
    pub path: String,
    pub pattern: String,
}

#[derive(Debug, Clone)]
pub struct PlanTarget {
    pub id: String,
    pub source: std::path::PathBuf,
    pub reasons: Vec<SelectionReason>,
}

#[derive(Debug, Clone)]
pub struct Plan {
    pub targets: Vec<PlanTarget>,
}

/// Build a plan from changed files, explicit targets, and CLI flags.
pub fn build_plan(
    config: &MergedConfig,
    changed_files: &[String],
    explicit_targets: &[String],
    all_mode: bool,
    excludes: &[String],
    allow_manual: bool,
    repo_root: &std::path::Path,
) -> Result<Plan> {
    let mut selected: IndexSet<String> = IndexSet::new();
    let mut reasons: Vec<(String, Vec<SelectionReason>)> = Vec::new();

    // 1. Explicit CLI targets/groups
    for id in explicit_targets {
        // Expand groups into leaves
        expand_target(config, id, &mut selected, &mut reasons, &[])?;
    }

    // 2. --all selects group "test"
    if all_mode && explicit_targets.is_empty() {
        expand_target(config, "test", &mut selected, &mut reasons, &[])?;
    }

    // 3. Changed-file rules
    if !changed_files.is_empty() {
        for sourced_rule in &config.rules {
            let rule = &sourced_rule.value;
            let rule_source = &sourced_rule.source;
            let rule_dir = &rule_source.dir;

            let any_matches: Vec<String> = changed_files
                .iter()
                .filter(|f| matcher::matches_any(f, &rule.when.anyChanged, rule_dir, repo_root))
                .cloned()
                .collect();

            let none_pass = matcher::matches_none(changed_files, &rule.when.noneChanged, rule_dir, repo_root);
            let all_pass = if rule.when.allChanged.is_empty() {
                true
            } else {
                matcher::matches_all(changed_files, &rule.when.allChanged, rule_dir, repo_root)
            };

            let actived = if !rule.when.anyChanged.is_empty() {
                !any_matches.is_empty()
            } else {
                true
            };

            if actived && none_pass && all_pass {
                let rule_id = rule.id.clone().unwrap_or_else(|| "unnamed".to_string());
                for run_id in &rule.run {
                    let file_reasons: Vec<SelectionReason> = any_matches
                        .iter()
                        .map(|p| SelectionReason {
                            rule: rule_id.clone(),
                            rule_source: rule_source.file.clone(),
                            path: p.clone(),
                            pattern: rule.when.anyChanged.first().cloned().unwrap_or_default(),
                        })
                        .collect();

                    expand_target(config, run_id, &mut selected, &mut reasons, &file_reasons)?;
                }
            }
        }
    }

    // 4. Apply excludes
    for exclude in excludes {
        selected.shift_remove(exclude);
    }

    // 5. Remove manual targets unless explicitly allowed
    if !allow_manual {
        selected.retain(|id| {
            if let Some(sourced) = config.targets.get(id) {
                let is_manual = match &sourced.value {
                    Target::Command(c) => c.manual,
                    Target::Sequence(s) => s.manual,
                };
                if is_manual {
                    return false;
                }
            }
            true
        });
    }

    // 6. Build plan
    let targets: Vec<PlanTarget> = selected
        .iter()
        .map(|id| {
            let source = config
                .targets
                .get(id)
                .map(|s| s.source.file.clone())
                .or_else(|| {
                    config.groups.get(id).map(|s| s.source.file.clone())
                })
                .unwrap_or_else(|| std::path::PathBuf::from("unknown"));

            let target_reasons: Vec<SelectionReason> = reasons
                .iter()
                .filter(|(tid, _)| tid == id)
                .flat_map(|(_, rs)| rs.clone())
                .collect();

            PlanTarget {
                id: id.clone(),
                source,
                reasons: target_reasons,
            }
        })
        .collect();

    if targets.is_empty() && changed_files.is_empty() && explicit_targets.is_empty() && !all_mode {
        println!("No changed files; no handoff checks selected.");
    }

    Ok(Plan { targets })
}

fn expand_target(
    config: &MergedConfig,
    id: &str,
    selected: &mut IndexSet<String>,
    reasons: &mut Vec<(String, Vec<SelectionReason>)>,
    file_reasons: &[SelectionReason],
) -> Result<()> {
    if config.groups.contains_key(id) {
        if let Some(sourced) = config.groups.get(id) {
            // beforeAll: expand into the plan before children
            for before in &sourced.value.before_all {
                expand_target(config, before, selected, reasons, file_reasons)?;
            }
            // Children
            for child in &sourced.value.children {
                expand_target(config, child, selected, reasons, file_reasons)?;
            }
            // afterAll: expand into the plan after children
            for after in &sourced.value.after_all {
                expand_target(config, after, selected, reasons, file_reasons)?;
            }
        }
    } else if config.targets.contains_key(id) {
        selected.insert(id.to_string());
        if !file_reasons.is_empty() {
            reasons.push((id.to_string(), file_reasons.to_vec()));
        }
    } else {
        return Err(HandoffError::NoSuchTarget(id.to_string()));
    }

    Ok(())
}

/// Get leaf targets for a subtree (for `run` subcommand).
pub fn leaf_targets(config: &MergedConfig, root: &str) -> Result<Vec<String>> {
    let mut targets = IndexSet::new();
    let mut _reasons = Vec::new();
    expand_target(config, root, &mut targets, &mut _reasons, &[])?;
    Ok(targets.into_iter().collect())
}

/// List all group and target IDs.
pub fn list_all(config: &MergedConfig) -> (Vec<String>, Vec<(String, std::path::PathBuf)>) {
    let groups: Vec<String> = config.groups.keys().cloned().collect();
    let targets: Vec<(String, std::path::PathBuf)> = config
        .targets
        .iter()
        .map(|(id, s)| (id.clone(), s.source.file.clone()))
        .collect();
    (groups, targets)
}

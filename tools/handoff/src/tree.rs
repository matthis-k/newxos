use std::collections::{HashMap, HashSet};

use crate::config::{MergedConfig, Sourced, Target};

pub fn print_tree(config: &MergedConfig, root: Option<&str>) {
    let root_id = root.unwrap_or("__all__");

    if root_id == "__all__" {
        // Print all top-level groups and standalone targets
        let mut printed = HashSet::new();
        let top_level = find_top_level_groups(config);
        for gid in &top_level {
            print_group(config, gid, 0, &mut printed);
        }
        // Print targets that are not in any group
        for (tid, _) in &config.targets {
            if !printed.contains(tid.as_str()) {
                println!("{}", tid);
            }
        }
    } else if config.groups.contains_key(root_id) {
        let mut printed = HashSet::new();
        print_group(config, root_id, 0, &mut printed);
    } else if config.targets.contains_key(root_id) {
        println!("{} (target)", root_id);
    } else {
        eprintln!("error: no such group or target: {}", root_id);
    }
}

fn find_top_level_groups(config: &MergedConfig) -> Vec<String> {
    let all_groups: HashSet<&str> = config.groups.keys().map(|s| s.as_str()).collect();
    let mut child_set: HashSet<&str> = HashSet::new();
    for (_, sourced) in &config.groups {
        for child in &sourced.value.children {
            if all_groups.contains(child.as_str()) {
                child_set.insert(child.as_str());
            }
        }
    }

    let mut top: Vec<String> = config
        .groups
        .keys()
        .filter(|id| !child_set.contains(id.as_str()))
        .cloned()
        .collect();
    top.sort();
    top
}

fn print_group(config: &MergedConfig, id: &str, depth: usize, printed: &mut HashSet<String>) {
    if !printed.insert(id.to_string()) {
        return;
    }

    let prefix = if depth == 0 {
        String::new()
    } else {
        "│   ".repeat(depth - 1) + "├── "
    };

    println!("{}{}", prefix, id);

    if let Some(sourced) = config.groups.get(id) {
        let children = &sourced.value.children;
        let count = children.len();
        for (i, child) in children.iter().enumerate() {
            let is_last = i == count - 1;
            if config.groups.contains_key(child) {
                if depth == 0 {
                    if is_last {
                        println!("└── {}", child);
                    } else {
                        println!("├── {}", child);
                    }
                } else {
                    let line_prefix = "│   ".repeat(depth - 1);
                    if is_last {
                        println!("{}└── {}", line_prefix, child);
                    } else {
                        println!("{}├── {}", line_prefix, child);
                    }
                }
            } else if config.targets.contains_key(child) {
                if depth == 0 {
                    if is_last {
                        println!("└── {}", child);
                    } else {
                        println!("├── {}", child);
                    }
                } else {
                    let line_prefix = "│   ".repeat(depth - 1);
                    if is_last {
                        println!("{}└── {}", line_prefix, child);
                    } else {
                        println!("{}├── {}", line_prefix, child);
                    }
                }
            }
        }
    }
}

pub fn print_tree_simple(config: &MergedConfig, root: Option<&str>) {
    let root_id = root.unwrap_or("__all__");

    enum Node<'a> {
        Group(&'a str, &'a Sourced<crate::config::Group>),
        Target(&'a str, &'a Sourced<Target>),
    }

    fn print_nodes(
        config: &MergedConfig,
        ids: &[String],
        prefix: &str,
        _is_last: bool,
        depth: usize,
        printed: &mut HashSet<String>,
    ) {
        for (i, id) in ids.iter().enumerate() {
            let last = i == ids.len() - 1;
            let connector = if last { "└── " } else { "├── " };
            let next_prefix = if last { "    " } else { "│   " };

            if config.groups.contains_key(id) {
                if printed.insert(id.clone()) {
                    println!("{}{}{}", prefix, connector, id);
                    let group = &config.groups[id];
                    let group_prefix = format!("{}{}", prefix, next_prefix);

                    // Build child list: beforeAll + children + afterAll
                    let mut children: Vec<String> = Vec::new();

                    for b in &group.value.before_all {
                        if config.groups.contains_key(b) || config.targets.contains_key(b) {
                            children.push(format!("[beforeAll] {}", b));
                        }
                    }
                    for c in &group.value.children {
                        if config.groups.contains_key(c) || config.targets.contains_key(c) {
                            children.push(c.clone());
                        }
                    }
                    for a in &group.value.after_all {
                        if config.groups.contains_key(a) || config.targets.contains_key(a) {
                            children.push(format!("[afterAll] {}", a));
                        }
                    }

                    if !children.is_empty() {
                        print_nodes(config, &children, &group_prefix, last, depth + 1, printed);
                    }
                }
            } else if config.targets.contains_key(id) {
                if printed.insert(id.clone()) {
                    println!("{}{}{} (target)", prefix, connector, id);
                }
            }
        }
    }

    let mut printed = HashSet::new();

    if root_id == "__all__" {
        let top_groups = find_top_level_groups(config);
        let all_targets: Vec<String> = config.targets.keys().cloned().collect();
        let top_targets: Vec<String> = all_targets
            .into_iter()
            .filter(|t| {
                !config.groups.iter().any(|(_, g)| g.value.children.contains(t))
            })
            .collect();

        let mut all_top = Vec::new();
        all_top.extend(top_groups);
        all_top.extend(top_targets);
        all_top.sort();

        print_nodes(config, &all_top, "", true, 0, &mut printed);

    } else if config.groups.contains_key(root_id) {
        let group = &config.groups[root_id];
        let children: Vec<String> = group
            .value
            .children
            .iter()
            .filter(|c| config.groups.contains_key(c.as_str()) || config.targets.contains_key(c.as_str()))
            .cloned()
            .collect();
        println!("{}", root_id);
        print_nodes(config, &children, "", true, 0, &mut printed);

    } else if config.targets.contains_key(root_id) {
        println!("{} (target)", root_id);
    } else {
        eprintln!("error: no such group or target: {}", root_id);
    }
}

// ── Health tree ─────────────────────────────────────────────

const GREEN: &str = "\x1b[32m";
const YELLOW: &str = "\x1b[33m";
const RED: &str = "\x1b[31m";
const RESET: &str = "\x1b[0m";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Health {
    Pass,
    Fail,
    Mixed,
}

/// Aggregate health for a group from its children.
pub fn group_health(children: &[Health]) -> Health {
    let mut has_pass = false;
    let mut has_fail = false;
    for h in children {
        match h {
            Health::Pass => has_pass = true,
            Health::Fail => has_fail = true,
            Health::Mixed => { has_pass = true; has_fail = true; }
        }
    }
    match (has_pass, has_fail) {
        (true, false) => Health::Pass,
        (false, true) => Health::Fail,
        _ => Health::Mixed,
    }
}

/// Print a color-coded health tree.
/// First computes health for all groups recursively, then prints.
pub fn print_health_tree(
    config: &MergedConfig,
    root_id: &str,
    leaf_results: &HashMap<String, Health>,
    color: bool,
) {
    // ── First pass: compute health for all groups ──
    fn compute_group_health(
        config: &MergedConfig,
        id: &str,
        leaf_results: &HashMap<String, Health>,
        health_cache: &mut HashMap<String, Health>,
    ) -> Health {
        if health_cache.contains_key(id) {
            return *health_cache.get(id).unwrap();
        }

        if let Some(sourced) = config.groups.get(id) {
            let mut child_healths = Vec::new();
            let all_child_ids: Vec<&str> = sourced.value.before_all.iter()
                .chain(sourced.value.children.iter())
                .chain(sourced.value.after_all.iter())
                .map(|s| s.as_str())
                .collect();

            for child in all_child_ids {
                if config.groups.contains_key(child) {
                    let h = compute_group_health(config, child, leaf_results, health_cache);
                    child_healths.push(h);
                } else if leaf_results.contains_key(child) {
                    child_healths.push(*leaf_results.get(child).unwrap());
                }
            }

            let h = if child_healths.is_empty() {
                Health::Pass
            } else {
                group_health(&child_healths)
            };
            health_cache.insert(id.to_string(), h);
            h
        } else {
            let h = leaf_results.get(id).copied().unwrap_or(Health::Fail);
            health_cache.insert(id.to_string(), h);
            h
        }
    }

    let mut health_cache = leaf_results.clone();
    for gid in config.groups.keys() {
        compute_group_health(config, gid, leaf_results, &mut health_cache);
    }

    // ── Second pass: print tree ──
    fn colorize(s: &str, health: Health, color: bool) -> String {
        if !color {
            let label = match health {
                Health::Pass => " ✔",
                Health::Fail => " ✘",
                Health::Mixed => " ⚠",
            };
            return format!("{}{}", s, label);
        }
        let (code, label) = match health {
            Health::Pass => (GREEN, " ✔"),
            Health::Fail => (RED, " ✘"),
            Health::Mixed => (YELLOW, " ⚠"),
        };
        format!("{}{}{}{}", code, s, label, RESET)
    }

    fn print_health_node(
        config: &MergedConfig,
        id: &str,
        health_cache: &HashMap<String, Health>,
        prefix: &str,
        is_last: bool,
        color: bool,
        printed: &mut HashSet<String>,
    ) {
        let connector = if is_last { "└── " } else { "├── " };
        let next_prefix = if is_last { "    " } else { "│   " };

        if config.groups.contains_key(id) {
            if !printed.insert(id.to_string()) {
                return;
            }
            let health = health_cache.get(id).copied().unwrap_or(Health::Fail);
            let line = colorize(id, health, color);
            println!("{}{}{}", prefix, connector, line);

            let group = &config.groups[id];
            let mut child_ids: Vec<String> = Vec::new();
            for b in &group.value.before_all {
                if config.groups.contains_key(b) || config.targets.contains_key(b) {
                    child_ids.push(format!("[beforeAll] {}", b));
                }
            }
            for c in &group.value.children {
                if config.groups.contains_key(c) || config.targets.contains_key(c) {
                    child_ids.push(c.clone());
                }
            }
            for a in &group.value.after_all {
                if config.groups.contains_key(a) || config.targets.contains_key(a) {
                    child_ids.push(format!("[afterAll] {}", a));
                }
            }

            for (i, child_id) in child_ids.iter().enumerate() {
                let last = i == child_ids.len() - 1;
                print_health_node(config, child_id, health_cache,
                    &format!("{}{}", prefix, next_prefix), last, color, printed);
            }
        } else {
            let raw = id.to_string();
            let lookup = raw.strip_prefix("[beforeAll] ")
                .or_else(|| raw.strip_prefix("[afterAll] "))
                .unwrap_or(&raw);
            let health = health_cache.get(lookup).copied().unwrap_or(Health::Fail);
            let line = colorize(&raw, health, color);
            println!("{}{}{}", prefix, connector, line);
        }
    }

    let mut printed = HashSet::new();

    if root_id == "__all__" {
        let top_groups = find_top_level_groups(config);
        let all_targets: Vec<String> = config.targets.keys().cloned().collect();
        let top_targets: Vec<String> = all_targets
            .into_iter()
            .filter(|t| !config.groups.iter().any(|(_, g)| g.value.children.contains(t)))
            .collect();
        let mut all_top = Vec::new();
        all_top.extend(top_groups);
        all_top.extend(top_targets);
        all_top.sort();

        for (i, id) in all_top.iter().enumerate() {
            let last = i == all_top.len() - 1;
            print_health_node(config, id, &health_cache, "", last, color, &mut printed);
        }
    } else if config.groups.contains_key(root_id) {
        print_health_node(config, root_id, &health_cache, "", true, color, &mut printed);
    } else {
        let health = health_cache.get(root_id).copied().unwrap_or(Health::Fail);
        let line = colorize(root_id, health, color);
        println!("{}", line);
    }
}

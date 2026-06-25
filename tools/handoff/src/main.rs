mod cli;
mod config;
mod discovery;
mod error;
mod expectation;
mod git;
mod matcher;
mod planner;
mod report;
mod runner;
mod tree;

use std::path::{Path, PathBuf};
use std::time::Duration;

use clap::Parser;

use cli::{Cli, Command};
use config::{CwdMode, MergedConfig, Sourced, Target};
use error::HandoffError;
use planner::PlanTarget;
use report::{ReportBuilder, ReportConfig};
use runner::RunOutcome;

fn main() {
    let cli = Cli::parse();
    let invocation_cwd = std::env::current_dir().expect("failed to get current directory");

    // Handle print-config early
    if cli.print_config {
        match print_config(&cli, &invocation_cwd) {
            Ok(()) => {}
            Err(e) => {
                eprintln!("error: {}", e);
                std::process::exit(1);
            }
        }
        return;
    }

    let result = run(cli, invocation_cwd);
    match result {
        Ok(exit_code) => std::process::exit(exit_code),
        Err(e) => {
            eprintln!("error: {}", e);
            std::process::exit(1);
        }
    }
}

fn run(cli: Cli, invocation_cwd: PathBuf) -> Result<i32, anyhow::Error> {
    // Detect repo root
    let repo_root = if let Some(root) = cli.repo_root.as_ref() {
        root.clone()
    } else {
        git::detect_repo_root()?
    };

    // Load config
    let config = load_config(&cli, &repo_root)?;

    // Handle -v / --health flag
    if cli.health {
        let leaf_ids: Vec<String> = config.targets.keys().cloned().collect();
        let mut results = std::collections::HashMap::new();
        for tid in &leaf_ids {
            if let Some(sourced) = config.targets.get(tid) {
                let outcome = run_target(
                    &config, tid, sourced,
                    &sourced.source.file,
                    &repo_root, &invocation_cwd,
                    &config.defaults,
                );
                let health = match outcome {
                    runner::RunOutcome::Passed { .. } => tree::Health::Pass,
                    _ => tree::Health::Fail,
                };
                results.insert(tid.clone(), health);
                match &outcome {
                    runner::RunOutcome::Passed { target_id, .. } => {
                        println!("  {}: passed", target_id);
                    }
                    runner::RunOutcome::Failed { target_id, failures, .. } => {
                        println!("  {}: FAILED", target_id);
                        for f in failures { println!("    {}", f); }
                    }
                    runner::RunOutcome::Skipped { target_id, reason, .. } => {
                        println!("  {}: skipped ({})", target_id, reason);
                    }
                }
            }
        }
        let use_color = !cli.no_color;
        println!("\n── Health tree ──\n");
        tree::print_health_tree(&config, "__all__", &results, use_color);
        return Ok(0);
    }

    // Handle subcommands that don't need changed files or planning
    match &cli.command {
        Some(Command::ValidateConfig) => {
            println!("config valid: {} file(s)", config.config_files.len());
            for f in &config.config_files {
                println!("  {}", f.display());
            }
            println!("groups: {}", config.groups.len());
            println!("targets: {}", config.targets.len());
            println!("rules: {}", config.rules.len());
            return Ok(0);
        }
        Some(Command::Tree { id }) => {
            crate::tree::print_tree_simple(&config, id.as_deref());
            return Ok(0);
        }
        Some(Command::List) => {
            let (groups, targets) = planner::list_all(&config);
            println!("Groups:");
            for g in &groups {
                println!("  {}", g);
            }
            println!("\nTargets:");
            for (id, source) in &targets {
                println!("  {} (defined in: {})", id, source.display());
            }
            return Ok(0);
        }
        _ => {}
    }

    // Get changed files
    let changed_files = get_changed_files(&cli, &repo_root)?;

    // Collect explicit targets from --target and --group
    let mut explicit_targets: Vec<String> = Vec::new();
    explicit_targets.extend(cli.target.clone());
    explicit_targets.extend(cli.group.clone());

    // Handle `run` subcommand
    if let Some(Command::Run { id }) = &cli.command {
        // Validate id exists
        if !config.groups.contains_key(id) && !config.targets.contains_key(id) {
            return Err(HandoffError::NoSuchTarget(id.clone()).into());
        }

        // Check if manual
        if let Some(sourced) = config.targets.get(id) {
            let is_manual = match &sourced.value {
                Target::Command(c) => c.manual,
                Target::Sequence(s) => s.manual,
            };
            if is_manual && !cli.allow_manual {
                return Err(HandoffError::ManualTarget(id.clone()).into());
            }
        }

        let leaf_ids = planner::leaf_targets(&config, id)?;

        let selected: Vec<PlanTarget> = leaf_ids
            .iter()
            .map(|tid| {
                let source = config
                    .targets
                    .get(tid)
                    .map(|s| s.source.file.clone())
                    .unwrap_or_else(|| PathBuf::from("unknown"));
                PlanTarget {
                    id: tid.clone(),
                    source,
                    reasons: Vec::new(),
                }
            })
            .collect();

        if cli.dry_run {
            println!("Dry-run: would run {} target(s)", selected.len());
            for pt in &selected {
                println!("  {}", pt.id);
            }
            return Ok(0);
        }

        return execute_plan(
            &config,
            &selected,
            &changed_files,
            &cli,
            &repo_root,
            &invocation_cwd,
        );
    }

    // Handle explain subcommand
    if let Some(Command::Explain) = &cli.command {
        println!("Changed files:");
        for f in &changed_files {
            println!("  {}", f);
        }
        println!("\nConfig files:");
        for f in &config.config_files {
            println!("  {}", f.display());
        }

        // Build plan and show reasons
        let plan = planner::build_plan(
            &config,
            &changed_files,
            &explicit_targets,
            cli.all,
            &cli.exclude,
            cli.allow_manual,
            &repo_root,
        )?;

        println!("\nSelected targets:");
        for pt in &plan.targets {
            println!("  {} (defined in: {})", pt.id, pt.source.display());
            for reason in &pt.reasons {
                println!("    rule: {} (from {})", reason.rule, reason.rule_source.display());
                println!("    path: {} matched pattern: {}", reason.path, reason.pattern);
            }
        }

        if plan.targets.is_empty() {
            println!("  (none)");
        }

        return Ok(0);
    }

    // Default: `check` subcommand (no subcommand also defaults to check)
    let is_check = matches!(&cli.command, Some(Command::Check { .. }) | None);

    if is_check {
        if cli.dry_run {
            let plan = planner::build_plan(
                &config,
                &changed_files,
                &explicit_targets,
                cli.all,
                &cli.exclude,
cli.allow_manual,
            &repo_root,
        )?;
        println!("Dry-run: would run {} target(s)", plan.targets.len());
            for pt in &plan.targets {
                println!("  {}", pt.id);
                for reason in &pt.reasons {
                    println!("    selected by rule {}: path {} matched {}",
                        reason.rule, reason.path, reason.pattern);
                }
            }
            if plan.targets.is_empty() {
                println!("  (none)");
            }
            return Ok(0);
        }

        let plan = planner::build_plan(
            &config,
            &changed_files,
            &explicit_targets,
            cli.all,
            &cli.exclude,
            cli.allow_manual,
            &repo_root,
        )?;

        if plan.targets.is_empty() {
            // If no files changed and no explicit targets, exit success
            if changed_files.is_empty() && explicit_targets.is_empty() && !cli.all {
                return Ok(0);
            }
            return Ok(0);
        }

        return execute_plan(
            &config,
            &plan.targets,
            &changed_files,
            &cli,
            &repo_root,
            &invocation_cwd,
        );
    }

    Ok(0)
}

fn load_config(cli: &Cli, repo_root: &Path) -> Result<MergedConfig, anyhow::Error> {
    let fragments = if !cli.config.is_empty() {
        discovery::load_explicit_configs(&cli.config)?
    } else if cli.no_discover {
        return Err(HandoffError::NoDiscoverWithoutConfig.into());
    } else {
        let found = discovery::discover_configs(repo_root)?;
        if found.is_empty() {
            return Err(HandoffError::NoConfigFound.into());
        }
        found
    };

    let merged = config::merge_configs(fragments)?;
    Ok(merged)
}

fn get_changed_files(cli: &Cli, repo_root: &Path) -> Result<Vec<String>, anyhow::Error> {
    if let Some(from) = &cli.changed_from {
        return Ok(git::ref_changed(repo_root, from, cli.changed_to.as_deref())?);
    }

    if cli.staged {
        return Ok(git::staged_changed(repo_root)?);
    }

    Ok(git::working_tree_changed(repo_root)?)
}

fn execute_plan(
    config: &MergedConfig,
    selected: &[PlanTarget],
    changed_files: &[String],
    cli: &Cli,
    repo_root: &Path,
    invocation_cwd: &Path,
) -> Result<i32, anyhow::Error> {
    let report_config = ReportConfig {
        verbose: cli.verbose,
        quiet: cli.quiet,
        show_passed: cli.show_passed,
        json_output: cli.json,
        report_path: cli.report.clone(),
        no_color: cli.no_color,
        config_files: config.config_files.clone(),
        changed_files: changed_files.to_vec(),
        selected: selected.to_vec(),
    };

    let mut report_builder = ReportBuilder::new(report_config, repo_root.to_path_buf(), invocation_cwd.to_path_buf());

    for pt in selected {
        if cli.fail_fast && report_builder.any_failed() {
            report_builder.add_outcome(RunOutcome::Skipped {
                target_id: pt.id.clone(),
                source_file: pt.source.clone(),
                reason: "previous failure (fail-fast)".to_string(),
            });
            continue;
        }

        let sourced = match config.targets.get(&pt.id) {
            Some(s) => s,
            None => {
                report_builder.add_outcome(RunOutcome::Skipped {
                    target_id: pt.id.clone(),
                    source_file: pt.source.clone(),
                    reason: "not found in config".to_string(),
                });
                continue;
            }
        };

        let outcome = run_target(
            config,
            &pt.id,
            sourced,
            &pt.source,
            repo_root,
            invocation_cwd,
            &config.defaults,
        );

        report_builder.add_outcome(outcome);
    }

    report_builder.finish();

    if report_builder.any_failed() {
        Ok(1)
    } else {
        Ok(0)
    }
}

fn run_target(
    _config: &MergedConfig,
    id: &str,
    sourced: &Sourced<Target>,
    source_file: &Path,
    repo_root: &Path,
    invocation_cwd: &Path,
    defaults: &config::Defaults,
) -> RunOutcome {
    match &sourced.value {
        Target::Command(cmd_target) => {
            run_command_target(id, cmd_target, sourced, source_file, repo_root, invocation_cwd, defaults)
        }
        Target::Sequence(seq_target) => {
            run_sequence_target(id, seq_target, sourced, source_file, repo_root, invocation_cwd, defaults)
        }
    }
}

fn run_command_target(
    id: &str,
    cmd_target: &config::CommandTarget,
    sourced: &Sourced<Target>,
    source_file: &Path,
    repo_root: &Path,
    invocation_cwd: &Path,
    defaults: &config::Defaults,
) -> RunOutcome {
    let config_dir = &sourced.source.dir;
    let cwd = runner::resolve_cwd(
        cmd_target.cwd,
        config_dir,
        repo_root,
        invocation_cwd,
        defaults.cwd,
    );

    let timeout = runner::resolve_timeout(
        cmd_target.timeout_seconds,
        None,
        defaults.timeout_seconds,
    );

    let result = runner::run_command(
        &cmd_target.command,
        &cwd,
        &cwd,
        timeout,
        &[],
    );

    // Check expectation
    let expect = cmd_target.expect.as_ref()
        .or(defaults.expect.as_ref())
        .cloned()
        .unwrap_or_default();

    let er = expectation::check_expectation(
        &result,
        &expect,
        id,
        None,
        source_file,
        &cwd,
    );

    let duration = result.duration;

    if result.timed_out {
        return RunOutcome::Failed {
            target_id: id.to_string(),
            source_file: source_file.to_path_buf(),
            duration,
            failures: vec!["timed out".to_string()],
            result,
        };
    }

    if er.passed {
        RunOutcome::Passed {
            target_id: id.to_string(),
            source_file: source_file.to_path_buf(),
            duration,
        }
    } else {
        RunOutcome::Failed {
            target_id: id.to_string(),
            source_file: source_file.to_path_buf(),
            duration,
            failures: er.failures,
            result,
        }
    }
}

fn run_sequence_target(
    id: &str,
    seq_target: &config::SequenceTarget,
    sourced: &Sourced<Target>,
    source_file: &Path,
    repo_root: &Path,
    invocation_cwd: &Path,
    defaults: &config::Defaults,
) -> RunOutcome {
    let config_dir = &sourced.source.dir;
    let _cwd = runner::resolve_cwd(
        seq_target.cwd,
        config_dir,
        repo_root,
        invocation_cwd,
        defaults.cwd,
    );

    let mut all_failures = Vec::new();
    let mut last_result = None;

    for (i, step) in seq_target.steps.iter().enumerate() {
        let step_id = step.id.clone().unwrap_or_else(|| format!("step-{}", i + 1));

        let step_cwd = runner::resolve_cwd(
            step.cwd,
            config_dir,
            repo_root,
            invocation_cwd,
            Some(
                seq_target.cwd
                    .or(defaults.cwd)
                    .unwrap_or(CwdMode::Repo)
            ),
        );

        let timeout = runner::resolve_timeout(
            step.timeout_seconds,
            None,
            defaults.timeout_seconds,
        );

        let result = runner::run_command(
            &step.command,
            &step_cwd,
            &step_cwd,
            timeout,
            &[],
        );

        let expect = step.expect.as_ref()
            .or(defaults.expect.as_ref())
            .cloned()
            .unwrap_or_default();

        let timed_out = result.timed_out;

        let er = expectation::check_expectation(
            &result,
            &expect,
            id,
            Some(&step_id),
            source_file,
            &step_cwd,
        );

        last_result = Some(result);

        if timed_out {
            all_failures.push(format!("step {}: timed out", step_id));
            break;
        }

        if !er.passed {
            all_failures.push(format!("step {}: {}", step_id, er.failures.join("; ")));
            break; // stop on first failure
        }
    }

    let duration = last_result.as_ref().map(|r| r.duration).unwrap_or_default();

    if all_failures.is_empty() {
        RunOutcome::Passed {
            target_id: id.to_string(),
            source_file: source_file.to_path_buf(),
            duration,
        }
    } else {
        let result = last_result.unwrap_or_else(|| runner::CommandResult {
            exit_code: -1,
            stdout: String::new(),
            stderr: String::new(),
            duration: Duration::ZERO,
            timed_out: false,
            command_program: String::new(),
            command_args: Vec::new(),
        });

        RunOutcome::Failed {
            target_id: id.to_string(),
            source_file: source_file.to_path_buf(),
            duration,
            failures: all_failures,
            result,
        }
    }
}

fn print_config(cli: &Cli, _invocation_cwd: &Path) -> Result<(), anyhow::Error> {
    let repo_root = if let Some(root) = cli.repo_root.as_ref() {
        root.clone()
    } else {
        git::detect_repo_root()?
    };

    let config = load_config(cli, &repo_root)?;

    let json = serde_json::to_string_pretty(&serde_json::json!({
        "version": 1,
        "configFiles": config.config_files.iter().map(|p| p.to_string_lossy().to_string()).collect::<Vec<_>>(),
        "defaults": {
            "cwd": config.defaults.cwd.map(|c| format!("{:?}", c)),
            "timeoutSeconds": config.defaults.timeout_seconds,
        },
        "groups": config.groups.iter().map(|(id, s)| {
            (id, serde_json::json!({
                "description": s.value.description,
                "children": s.value.children,
                "source": s.source.file.to_string_lossy().to_string(),
            }))
        }).collect::<serde_json::Value>(),
        "targets": config.targets.iter().map(|(id, s)| {
            (id, serde_json::json!({
                "source": s.source.file.to_string_lossy().to_string(),
            }))
        }).collect::<serde_json::Value>(),
        "rules": config.rules.iter().map(|s| {
            serde_json::json!({
                "id": s.value.id,
                "source": s.source.file.to_string_lossy().to_string(),
                "anyChanged": s.value.when.anyChanged,
                "run": s.value.run,
            })
        }).collect::<Vec<_>>(),
    }))?;

    println!("{}", json);
    Ok(())
}

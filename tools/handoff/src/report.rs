use std::path::PathBuf;

use serde::Serialize;

use crate::runner::RunOutcome;
use crate::planner::PlanTarget;

#[derive(Debug, Clone, Serialize)]
pub struct JsonReport {
    pub mode: String,
    pub repo_root: String,
    pub invocation_cwd: String,
    pub config_files: Vec<String>,
    pub changed_files: Vec<String>,
    pub selected: Vec<JsonSelected>,
    pub results: Vec<JsonResult>,
    pub summary: JsonSummary,
}

#[derive(Debug, Clone, Serialize)]
pub struct JsonSelected {
    pub id: String,
    pub source: String,
    pub reasons: Vec<JsonReason>,
}

#[derive(Debug, Clone, Serialize)]
pub struct JsonReason {
    pub rule: String,
    #[serde(rename = "ruleSource")]
    pub rule_source: String,
    pub path: String,
    pub pattern: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct JsonResult {
    pub id: String,
    pub status: String,
    #[serde(rename = "durationMs")]
    pub duration_ms: u64,
}

#[derive(Debug, Clone, Serialize)]
pub struct JsonSummary {
    pub passed: usize,
    pub failed: usize,
    pub skipped: usize,
    #[serde(rename = "durationMs")]
    pub duration_ms: u64,
}

pub struct ReportConfig {
    pub verbose: bool,
    pub quiet: bool,
    pub show_passed: bool,
    pub json_output: bool,
    pub report_path: Option<PathBuf>,
    pub no_color: bool,
    pub config_files: Vec<PathBuf>,
    pub changed_files: Vec<String>,
    pub selected: Vec<PlanTarget>,
}

pub struct ReportBuilder {
    pub outcomes: Vec<RunOutcome>,
    pub config: ReportConfig,
    pub repo_root: PathBuf,
    pub invocation_cwd: PathBuf,
    pub start_time: std::time::Instant,
}

impl ReportBuilder {
    pub fn new(
        config: ReportConfig,
        repo_root: PathBuf,
        invocation_cwd: PathBuf,
    ) -> Self {
        ReportBuilder {
            outcomes: Vec::new(),
            config,
            repo_root,
            invocation_cwd,
            start_time: std::time::Instant::now(),
        }
    }

    pub fn add_outcome(&mut self, outcome: RunOutcome) {
        self.outcomes.push(outcome);
    }

    pub fn finish(&self) {
        let total_duration = self.start_time.elapsed();

        let mut passed = 0usize;
        let mut failed = 0usize;
        let mut skipped = 0usize;

        for outcome in &self.outcomes {
            match outcome {
                RunOutcome::Passed { .. } => passed += 1,
                RunOutcome::Failed { .. } => failed += 1,
                RunOutcome::Skipped { .. } => skipped += 1,
            }
        }

        // Build JSON report
        if self.config.json_output || self.config.report_path.is_some() {
            let selected: Vec<JsonSelected> = self
                .config
                .selected
                .iter()
                .map(|pt| {
                    let reasons: Vec<JsonReason> = pt
                        .reasons
                        .iter()
                        .map(|r| JsonReason {
                            rule: r.rule.clone(),
                            rule_source: r.rule_source.to_string_lossy().to_string(),
                            path: r.path.clone(),
                            pattern: r.pattern.clone(),
                        })
                        .collect();
                    JsonSelected {
                        id: pt.id.clone(),
                        source: pt.source.to_string_lossy().to_string(),
                        reasons,
                    }
                })
                .collect();

            let results: Vec<JsonResult> = self
                .outcomes
                .iter()
                .map(|o| match o {
                    RunOutcome::Passed { target_id, duration, .. } => JsonResult {
                        id: target_id.clone(),
                        status: "passed".to_string(),
                        duration_ms: duration.as_millis() as u64,
                    },
                    RunOutcome::Failed { target_id, duration, .. } => JsonResult {
                        id: target_id.clone(),
                        status: "failed".to_string(),
                        duration_ms: duration.as_millis() as u64,
                    },
                    RunOutcome::Skipped { target_id, .. } => JsonResult {
                        id: target_id.clone(),
                        status: "skipped".to_string(),
                        duration_ms: 0,
                    },
                })
                .collect();

            let report = JsonReport {
                mode: "handoff".to_string(),
                repo_root: self.repo_root.to_string_lossy().to_string(),
                invocation_cwd: self.invocation_cwd.to_string_lossy().to_string(),
                config_files: self
                    .config
                    .config_files
                    .iter()
                    .map(|p| p.to_string_lossy().to_string())
                    .collect(),
                changed_files: self.config.changed_files.clone(),
                selected,
                results,
                summary: JsonSummary {
                    passed,
                    failed,
                    skipped,
                    duration_ms: total_duration.as_millis() as u64,
                },
            };

            let json = serde_json::to_string_pretty(&report).unwrap();

            if self.config.json_output {
                println!("{}", json);
            }

            if let Some(path) = &self.config.report_path {
                if let Err(e) = std::fs::write(path, &json) {
                    eprintln!("warning: failed to write report to {}: {}", path.display(), e);
                }
            }
        }

        // Console output
        if !self.config.quiet {
            let num_changed = self.config.changed_files.len();

            if self.config.verbose || !self.config.json_output {
                if !self.config.json_output {
                    println!(
                        "repo-handoff: changed files: {}\n",
                        num_changed
                    );

                    if !self.config.selected.is_empty() {
                        println!("Selected checks:");
                        for pt in &self.config.selected {
                            println!("  {}", pt.id);
                            if self.config.verbose {
                                for reason in &pt.reasons {
                                    println!(
                                        "    selected by rule {}: path {} matched {}",
                                        reason.rule, reason.path, reason.pattern
                                    );
                                    println!(
                                        "    rule defined in {}",
                                        reason.rule_source.display()
                                    );
                                }
                            }
                        }
                        println!();
                    }
                }

                for outcome in &self.outcomes {
                    match outcome {
                        RunOutcome::Passed { target_id, source_file: _, duration } => {
                            if self.config.show_passed || self.config.verbose {
                                let ms = duration.as_millis();
                                println!("OK    {} ({}.{:03}s)", target_id, ms / 1000, ms % 1000);
                            }
                        }
                        RunOutcome::Failed {
                            target_id,
                            source_file,
                            duration,
                            failures,
                            result,
                        } => {
                            let ms = duration.as_millis();
                            println!("FAIL  {} ({}.{:03}s)", target_id, ms / 1000, ms % 1000);

                            for failure in failures {
                                println!("  failure: {}", failure);
                            }

                            if result.timed_out {
                                println!("  reason: timed out");
                            }

                            println!("  defined in: {}", source_file.display());
                            println!("  cwd: {}", result.command_program);
                            println!("  command: {} {}", result.command_program, result.command_args.join(" "));
                            println!("  exit: {}", result.exit_code);

                            if !result.stdout.is_empty() {
                                println!("\nstdout:");
                                for line in result.stdout.lines() {
                                    println!("  {}", line);
                                }
                            }

                            if !result.stderr.is_empty() {
                                println!("\nstderr:");
                                for line in result.stderr.lines() {
                                    println!("  {}", line);
                                }
                            }

                            println!();
                        }
                        RunOutcome::Skipped { target_id, source_file: _, reason } => {
                            if self.config.show_passed || self.config.verbose {
                                println!("SKIP  {} ({})", target_id, reason);
                            }
                        }
                    }
                }
            }

            // Summary line
            let summary = format!(
                "\nSummary:\n  PASS {} / FAIL {} / SKIP {}",
                passed, failed, skipped
            );
            println!("{}", summary);
        }

        // Final message
        if failed == 0 {
            println!("\nrepo-handoff: handoff passed");
        } else {
            println!("\nrepo-handoff: handoff failed");
        }
    }

    pub fn any_failed(&self) -> bool {
        self.outcomes.iter().any(|o| matches!(o, RunOutcome::Failed { .. }))
    }
}

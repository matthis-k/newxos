use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser, Debug)]
#[command(name = "repo-handoff", about = "Path-aware handoff and correctness gate for repo changes")]
#[command(version)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Command>,

    /// Load explicit config file. Repeatable. Disables auto-discovery.
    #[arg(short = 'c', long = "config", value_name = "PATH", global = true)]
    pub config: Vec<PathBuf>,

    /// Disable config auto-discovery. Requires at least one --config.
    #[arg(long = "no-discover", global = true)]
    pub no_discover: bool,

    /// Override detected repo root.
    #[arg(long = "repo-root", value_name = "PATH", global = true)]
    pub repo_root: Option<PathBuf>,

    /// Use staged files only (commit hook mode).
    #[arg(long = "staged", global = true)]
    pub staged: bool,

    /// Diff from ref (e.g. HEAD~1).
    #[arg(long = "changed-from", value_name = "REF", global = true)]
    pub changed_from: Option<String>,

    /// Diff to ref (optional, requires --changed-from).
    #[arg(long = "changed-to", value_name = "REF", global = true)]
    pub changed_to: Option<String>,

    /// Select strict default group (normally "test").
    #[arg(long = "all", global = true)]
    pub all: bool,

    /// Add explicit target/group to plan. Repeatable.
    #[arg(long = "target", value_name = "ID", global = true)]
    pub target: Vec<String>,

    /// Alias for --target.
    #[arg(long = "group", value_name = "ID", global = true)]
    pub group: Vec<String>,

    /// Exclude target/group. Repeatable.
    #[arg(long = "exclude", value_name = "ID", global = true)]
    pub exclude: Vec<String>,

    /// Allow explicitly selected manual targets.
    #[arg(long = "allow-manual", global = true)]
    pub allow_manual: bool,

    /// Print selected plan without executing.
    #[arg(long = "dry-run", global = true)]
    pub dry_run: bool,

    /// Stop after first failed target.
    #[arg(long = "fail-fast", global = true)]
    pub fail_fast: bool,

    /// Print command output for passing targets too.
    #[arg(long = "verbose", global = true)]
    pub verbose: bool,

    /// Run all tests and show a color-coded health tree.
    #[arg(short = 'v', long = "health", global = true)]
    pub health: bool,

    /// Only print failures and final summary.
    #[arg(long = "quiet", short = 'q', global = true)]
    pub quiet: bool,

    /// Print machine-readable report to stdout.
    #[arg(long = "json", global = true)]
    pub json: bool,

    /// Write JSON report to path.
    #[arg(long = "report", value_name = "PATH", global = true)]
    pub report: Option<PathBuf>,

    /// Print passed target names in default output.
    #[arg(long = "show-passed", global = true)]
    pub show_passed: bool,

    /// Print merged config and exit.
    #[arg(long = "print-config", global = true)]
    pub print_config: bool,

    /// Include config-source diagnostics.
    #[arg(long = "explain-config", global = true)]
    pub explain_config: bool,

    /// Disable color.
    #[arg(long = "no-color", global = true)]
    pub no_color: bool,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    /// Default. Select targets from changed files and run them.
    Check {
        /// Override --all for check subcommand.
        #[arg(long)]
        all: bool,
    },
    /// Run one target or group subtree.
    Run {
        id: String,
    },
    /// Print the configured group/target tree.
    Tree {
        id: Option<String>,
    },
    /// List groups and targets.
    List,
    /// Show changed files, matching rules, selected targets, and source configs.
    Explain,
    /// Validate discovered/explicit configs and merged config.
    ValidateConfig,
}

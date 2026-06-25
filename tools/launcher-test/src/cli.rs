use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Debug, Parser)]
#[command(name = "newshell-launcher-test", about = "Run launcher test cases against a newshell instance")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    /// Validate test case JSON files against the schema
    Validate {
        /// Path to test case file or directory
        path: PathBuf,
        /// Path to JSON schema file for validation
        #[arg(long)]
        schema: Option<PathBuf>,
    },
    /// List available test cases
    List {
        /// Path to test case file or directory
        path: PathBuf,
        /// Optional filter string
        #[arg(long)]
        filter: Option<String>,
    },
    /// Run test cases against a launcher instance
    Run {
        /// Path to test case file or directory
        path: PathBuf,
        /// Run mode: headless or visible
        #[arg(long, default_value = "headless")]
        mode: RunMode,
        /// Optional filter string for case names/tags
        #[arg(long)]
        filter: Option<String>,
        /// Path to launcher IPC socket (auto-detected if not provided)
        #[arg(long)]
        socket: Option<PathBuf>,
        /// Print debug pipeline info on failure
        #[arg(long)]
        debug_pipeline: bool,
    },
    /// Derive debugging probes from canonical test cases
    Probe {
        /// Path to canonical test case file or directory
        path: PathBuf,
        /// Optional filter string for case names/tags
        #[arg(long)]
        filter: Option<String>,
        /// Print the derived probe without executing
        #[arg(long)]
        print: bool,
        /// Print only the derived jq filter
        #[arg(long)]
        print_jq: bool,
        /// Execute the probe against a running instance
        #[arg(long)]
        run: bool,
        /// Verbose output (with --run)
        #[arg(long)]
        verbose: bool,
    },
    /// Policy unit test commands
    Policy {
        #[command(subcommand)]
        subcommand: PolicyCommand,
    },
    /// Integration test commands (validate only, use `run` for runtime)
    Integration {
        #[command(subcommand)]
        subcommand: IntegrationCommand,
    },
    /// Run all tests: validate policy + integration cases, then run integration if mode specified
    All {
        /// Run mode for integration tests: headless or visible
        #[arg(long, default_value = "headless")]
        mode: RunMode,
        /// Path to launcher IPC socket (auto-detected if not provided)
        #[arg(long)]
        socket: Option<PathBuf>,
    },
}

#[derive(Debug, Subcommand)]
pub enum PolicyCommand {
    /// Validate policy unit test JSON files against the policy schema
    Validate {
        /// Path to policy test case file or directory
        path: PathBuf,
    },
    /// List policy unit test cases
    List {
        /// Path to policy test case file or directory
        path: PathBuf,
        /// Optional filter string
        #[arg(long)]
        filter: Option<String>,
    },
    /// Run policy unit tests against a newshell instance (requires QML execution)
    Run {
        /// Path to policy test case file or directory
        path: PathBuf,
        /// Path to launcher IPC socket (auto-detected if not provided)
        #[arg(long)]
        socket: Option<PathBuf>,
    },
}

#[derive(Debug, Subcommand)]
pub enum IntegrationCommand {
    /// Validate integration test JSON files against the launcher schema
    Validate {
        /// Path to integration test case file or directory
        path: PathBuf,
        /// Path to JSON schema file for validation
        #[arg(long)]
        schema: Option<PathBuf>,
    },
    /// List integration test cases
    List {
        /// Path to integration test case file or directory
        path: PathBuf,
        /// Optional filter string
        #[arg(long)]
        filter: Option<String>,
    },
}

#[derive(Debug, Clone, clap::ValueEnum)]
pub enum RunMode {
    Headless,
    Visible,
}

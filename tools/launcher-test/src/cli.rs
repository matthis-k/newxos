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
    },
}

#[derive(Debug, Clone, clap::ValueEnum)]
pub enum RunMode {
    Headless,
    Visible,
}

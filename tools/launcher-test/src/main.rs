mod assertions;
mod cli;
mod ipc;
mod pretty;
mod runner;
mod schema;

use clap::Parser;
use std::process;

#[tokio::main]
async fn main() {
    let cli = cli::Cli::parse();

    let result = match &cli.command {
        cli::Command::Validate { path, schema } => {
            match runner::validate_cases(path, schema.as_deref()) {
                Ok(errors) if errors.is_empty() => {
                    println!("All test case files valid.");
                    Ok(())
                }
                Ok(errors) => {
                    for err in &errors {
                        eprintln!("Validation error: {}", err);
                    }
                    Err(anyhow::anyhow!("Validation failed with {} error(s)", errors.len()))
                }
                Err(e) => Err(e),
            }
        }
        cli::Command::List { path, filter } => {
            match runner::list_cases(path, filter.as_deref()) {
                Ok(_) => Ok(()),
                Err(e) => Err(e),
            }
        }
        cli::Command::Run { path, mode, filter, socket } => {
            match runner::run_cases(path, filter.as_deref(), mode, socket.as_deref()) {
                Ok(summary) => {
                    if summary.failed > 0 {
                        Err(anyhow::anyhow!("{} test(s) failed", summary.failed))
                    } else {
                        Ok(())
                    }
                }
                Err(e) => Err(e),
            }
        }
    };

    if let Err(e) = result {
        eprintln!("Error: {}", e);
        process::exit(1);
    }
}

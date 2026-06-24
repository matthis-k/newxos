mod assertions;
mod cli;
mod ipc;
mod pretty;
mod probe;
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
        cli::Command::Run { path, mode, filter, socket, debug_pipeline } => {
            match runner::run_cases(path, filter.as_deref(), mode, socket.as_deref(), *debug_pipeline) {
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
        cli::Command::Probe { path, filter, print: _, print_jq, run, verbose } => {
            let probes = probe::generate_probes(path, filter.as_deref());
            if probes.is_empty() {
                eprintln!("No cases matched the filter");
                process::exit(1);
            }
            for p in &probes {
                if *run {
                    let show_jq = *print_jq;
                    if !show_jq {
                        println!("Running probe: {}", p.case_name);
                    }
                    match probe::run_probe(p, *verbose) {
                        Ok(()) => {
                            if show_jq {
                                probe::print_probe(p, true);
                            }
                        }
                        Err(e) => {
                            eprintln!("Probe failed for '{}': {}", p.case_name, e);
                            process::exit(1);
                        }
                    }
                } else {
                    probe::print_probe(p, *print_jq);
                }
            }
            Ok(())
        }
    };

    if let Err(e) = result {
        eprintln!("Error: {}", e);
        process::exit(1);
    }
}

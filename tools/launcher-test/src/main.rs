mod assertions;
mod cli;
mod ipc;
mod pretty;
mod probe;
mod runner;
mod schema;

use clap::Parser;
use std::process;

fn main() -> Result<(), anyhow::Error> {
    let cli = cli::Cli::parse();

    match &cli.command {
        cli::Command::Validate { path, schema } => {
            let errors = runner::validate_cases(path, schema.as_deref())?;
            if errors.is_empty() {
                println!("All test case files valid.");
                Ok(())
            } else {
                for err in &errors {
                    eprintln!("Validation error: {}", err);
                }
                Err(anyhow::anyhow!("Validation failed with {} error(s)", errors.len()))
            }
        }
        cli::Command::List { path, filter } => {
            runner::list_cases(path, filter.as_deref())?;
            Ok(())
        }
        cli::Command::Run { path, mode, filter, socket, debug_pipeline } => {
            let summary = runner::run_cases(path, filter.as_deref(), mode, socket.as_deref(), *debug_pipeline)?;
            if summary.failed > 0 {
                Err(anyhow::anyhow!("{} test(s) failed", summary.failed))
            } else {
                Ok(())
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
                    if let Err(e) = probe::run_probe(p, *verbose) {
                        eprintln!("Probe failed for '{}': {}", p.case_name, e);
                        process::exit(1);
                    }
                    if show_jq {
                        probe::print_probe(p, true);
                    }
                } else {
                    probe::print_probe(p, *print_jq);
                }
            }
            Ok(())
        }
        cli::Command::Policy { subcommand } => {
            match subcommand {
                cli::PolicyCommand::Validate { path } => {
                    let schema_path = path.join("../schemas/policy-unit.schema.json");
                    let schema = if schema_path.exists() { Some(schema_path) } else { None };
                    let errors = runner::validate_policy_cases(path, schema.as_deref())?;
                    if errors.is_empty() {
                        println!("All policy unit test files valid.");
                        Ok(())
                    } else {
                        for err in &errors {
                            eprintln!("Validation error: {}", err);
                        }
                        Err(anyhow::anyhow!("Policy validation failed with {} error(s)", errors.len()))
                    }
                }
                cli::PolicyCommand::List { path, filter } => {
                    runner::list_policy_cases(path, filter.as_deref())?;
                    Ok(())
                }
                cli::PolicyCommand::Run { path, socket: _ } => {
                    let errors = runner::validate_policy_cases(path, None)?;
                    if !errors.is_empty() {
                        for err in &errors {
                            eprintln!("Validation error: {}", err);
                        }
                        return Err(anyhow::anyhow!("Policy validation failed with {} error(s)", errors.len()));
                    }
                    println!("Policy cases valid. Run requires newshell with PolicyUnitHost.qml loaded.");
                    println!("  (QML host execution not yet implemented)");
                    Ok(())
                }
            }
        }
        cli::Command::Integration { subcommand } => {
            match subcommand {
                cli::IntegrationCommand::Validate { path, schema } => {
                    let errors = runner::validate_cases(path, schema.as_deref())?;
                    if errors.is_empty() {
                        println!("All integration test case files valid.");
                        Ok(())
                    } else {
                        for err in &errors {
                            eprintln!("Validation error: {}", err);
                        }
                        Err(anyhow::anyhow!("Integration validation failed with {} error(s)", errors.len()))
                    }
                }
                cli::IntegrationCommand::List { path, filter } => {
                    runner::list_cases(path, filter.as_deref())?;
                    Ok(())
                }
            }
        }
        cli::Command::All { mode, socket } => {
            let mut all_errors: Vec<String> = Vec::new();

            let policy_path = std::path::Path::new("tests/launcher/policies");
            if policy_path.exists() {
                let schema = std::path::Path::new("tests/launcher/policies/schemas/policy-unit.schema.json");
                match runner::validate_policy_cases(policy_path, Some(schema)) {
                    Ok(errors) if errors.is_empty() => {
                        println!("Policy unit tests: valid");
                    }
                    Ok(errors) => {
                        for err in &errors {
                            eprintln!("Policy validation error: {}", err);
                        }
                        all_errors.push(format!("Policy validation: {} error(s)", errors.len()));
                    }
                    Err(e) => {
                        let msg = format!("Policy validation error: {}", e);
                        eprintln!("{}", msg);
                        all_errors.push(msg);
                    }
                }
            } else {
                println!("Policy unit tests: directory not found (skipped)");
            }

            let integration_path = std::path::Path::new("tests/launcher/cases");
            let schema_path = std::path::Path::new("tests/launcher/schemas/launcher-test.schema.json");
            if integration_path.exists() {
                match runner::validate_cases(integration_path, if schema_path.exists() { Some(schema_path) } else { None }) {
                    Ok(errors) if errors.is_empty() => {
                        println!("Integration test cases: valid");
                    }
                    Ok(errors) => {
                        for err in &errors {
                            eprintln!("Integration validation error: {}", err);
                        }
                        all_errors.push(format!("Integration validation: {} error(s)", errors.len()));
                    }
                    Err(e) => {
                        let msg = format!("Integration validation error: {}", e);
                        eprintln!("{}", msg);
                        all_errors.push(msg);
                    }
                }
            } else {
                println!("Integration test cases: directory not found (skipped)");
            }

            if integration_path.exists() {
                match runner::run_cases(integration_path, None, mode, socket.as_deref(), false) {
                    Ok(summary) => {
                        if summary.failed > 0 {
                            all_errors.push(format!("Integration runtime: {} test(s) failed", summary.failed));
                        }
                    }
                    Err(e) => {
                        println!("Integration runtime: skipped (need newshell instance): {}", e);
                    }
                }
            }

            if all_errors.is_empty() {
                Ok(())
            } else {
                Err(anyhow::anyhow!("{} check(s) failed: {}", all_errors.len(), all_errors.join("; ")))
            }
        }
    }
}

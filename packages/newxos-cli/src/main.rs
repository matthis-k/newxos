mod cli;
mod commands;
mod error;
mod support;

use clap::Parser;
use cli::{Cli, Command, CompletionGroup, HomeAction};
use std::process;

fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Command::BuildIso { key } => commands::build_iso(key),
        Command::FirstInstall { host } => commands::first_install(host),
        Command::Switch { target } => commands::os(cli::OsAction::Switch {
            host: target.host,
            git_only: target.git_only,
        }),
        Command::Os { action } => commands::os(action),
        Command::Home { action } => match action {
            HomeAction::Switch { config, git_only } => commands::home("switch", &config, git_only),
            HomeAction::Build { config, git_only } => commands::home("build", &config, git_only),
        },
        Command::Flake { action } => commands::flake(action),
        Command::Memory { action } => commands::memory(action),
        Command::Ai => commands::ai(),
        Command::Git => commands::git(),
        Command::ReloadShell => commands::reload_shell(),
        Command::DevMode => commands::dev_mode(),
        Command::Clean { args } => commands::clean(args),
        Command::Complete { group } => complete(group),
        Command::Completions { shell } => {
            support::completions::print_completions(&shell);
            Ok(0)
        }
    };

    match result {
        Ok(code) => process::exit(code),
        Err(e) => {
            eprintln!("error: {}", e);
            process::exit(1);
        }
    }
}

fn complete(group: CompletionGroup) -> error::Result<i32> {
    let root = support::repo::repo_root()?;

    match group {
        CompletionGroup::NixosHosts => {
            for host in support::discovery::nixos_hosts(&root)? {
                println!("{}", host);
            }
        }
        CompletionGroup::HomeConfigs => {
            for config in support::discovery::home_configs(&root)? {
                println!("{}", config);
            }
        }
        CompletionGroup::RunTargets => {
            for target in support::discovery::run_targets(&root)? {
                println!("{}", target);
            }
        }
    }

    Ok(0)
}

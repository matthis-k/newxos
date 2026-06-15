use clap::{Parser, Subcommand, ValueEnum};

#[derive(Parser, Debug)]
#[command(name = "newxos", about = "Manage the newxos flake")]
#[command(version, propagate_version = true)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    #[command(name = "build-iso")]
    BuildIso {
        #[arg(long)]
        key: Option<String>,
    },

    #[command(name = "first-install")]
    FirstInstall {
        host: String,
    },

    Switch {
        #[command(flatten)]
        target: TargetArgs,
    },

    Os {
        #[command(subcommand)]
        action: OsAction,
    },

    Home {
        #[command(subcommand)]
        action: HomeAction,
    },

    Flake {
        #[command(subcommand)]
        action: FlakeAction,
    },

    Memory {
        #[command(subcommand)]
        action: MemoryAction,
    },

    Ai,

    Git,

    #[command(name = "reload_shell")]
    ReloadShell,

    #[command(name = "dev_mode")]
    DevMode,

    Clean {
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        args: Vec<String>,
    },

    #[command(name = "_complete", hide = true)]
    Complete {
        group: CompletionGroup,
    },

    Completions {
        shell: CompletionShell,
    },
}

#[derive(clap::Args, Clone, Debug)]
pub struct TargetArgs {
    pub host: Option<String>,

    #[arg(long)]
    pub git_only: bool,
}

#[derive(Subcommand, Debug)]
pub enum OsAction {
    Switch {
        host: Option<String>,
        #[arg(long)]
        git_only: bool,
    },
    Boot {
        host: Option<String>,
        #[arg(long)]
        git_only: bool,
    },
    Build {
        host: Option<String>,
        #[arg(long)]
        git_only: bool,
    },
}

#[derive(Subcommand, Debug)]
pub enum HomeAction {
    Switch {
        config: String,
        #[arg(long)]
        git_only: bool,
    },
    Build {
        config: String,
        #[arg(long)]
        git_only: bool,
    },
}

#[derive(Subcommand, Debug)]
pub enum FlakeAction {
    Build {
        host: Option<String>,
        #[arg(long)]
        git_only: bool,
    },
    Check {
        host: Option<String>,
        #[arg(long)]
        git_only: bool,
    },
    Show {
        host: Option<String>,
        #[arg(long)]
        git_only: bool,
    },
    Run {
        attr: String,
        #[arg(long)]
        git_only: bool,
    },
}

#[derive(Subcommand, Clone, Debug)]
pub enum MemoryAction {
    Reindex,
    Reset,
}

#[derive(ValueEnum, Clone, Debug)]
pub enum CompletionGroup {
    #[value(name = "nixos-hosts")]
    NixosHosts,
    #[value(name = "home-configs")]
    HomeConfigs,
    #[value(name = "run-targets")]
    RunTargets,
}

#[derive(ValueEnum, Clone, Debug)]
pub enum CompletionShell {
    Fish,
    Bash,
    Zsh,
    Elvish,
    #[value(name = "powershell")]
    PowerShell,
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[test]
    fn verify_cli() {
        Cli::command().debug_assert();
    }

    #[test]
    fn parse_help_exits_ok() {
        let result = Cli::try_parse_from(["newxos", "--help"]);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.kind(), clap::error::ErrorKind::DisplayHelp);
    }

    #[test]
    fn parse_os_help_exits_ok() {
        let result = Cli::try_parse_from(["newxos", "os", "--help"]);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.kind(), clap::error::ErrorKind::DisplayHelp);
    }

    #[test]
    fn parse_flake_help_exits_ok() {
        let result = Cli::try_parse_from(["newxos", "flake", "--help"]);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.kind(), clap::error::ErrorKind::DisplayHelp);
    }

    #[test]
    fn parse_clean_with_trailing_flags() {
        let cli = Cli::try_parse_from(["newxos", "clean", "--dry", "--keep", "5"]).unwrap();
        match cli.command {
            Command::Clean { args } => {
                assert_eq!(args, vec!["--dry", "--keep", "5"]);
            }
            _ => panic!("expected Clean command"),
        }
    }

    #[test]
    fn parse_clean_empty() {
        let cli = Cli::try_parse_from(["newxos", "clean"]).unwrap();
        match cli.command {
            Command::Clean { args } => {
                assert!(args.is_empty());
            }
            _ => panic!("expected Clean command"),
        }
    }

    #[test]
    fn parse_switch_with_host() {
        let cli = Cli::try_parse_from(["newxos", "switch", "myhost"]).unwrap();
        match cli.command {
            Command::Switch { target } => {
                assert_eq!(target.host, Some("myhost".to_string()));
                assert!(!target.git_only);
            }
            _ => panic!("expected Switch command"),
        }
    }

    #[test]
    fn parse_switch_git_only() {
        let cli = Cli::try_parse_from(["newxos", "switch", "--git-only"]).unwrap();
        match cli.command {
            Command::Switch { target } => {
                assert_eq!(target.host, None);
                assert!(target.git_only);
            }
            _ => panic!("expected Switch command"),
        }
    }

    #[test]
    fn parse_build_iso_with_key() {
        let cli = Cli::try_parse_from(["newxos", "build-iso", "--key", "/path/to/key"]).unwrap();
        match cli.command {
            Command::BuildIso { key } => {
                assert_eq!(key, Some("/path/to/key".to_string()));
            }
            _ => panic!("expected BuildIso command"),
        }
    }

    #[test]
    fn parse_first_install() {
        let cli = Cli::try_parse_from(["newxos", "first-install", "myhost"]).unwrap();
        match cli.command {
            Command::FirstInstall { host } => {
                assert_eq!(host, "myhost");
            }
            _ => panic!("expected FirstInstall command"),
        }
    }

    #[test]
    fn parse_flake_run() {
        let cli = Cli::try_parse_from(["newxos", "flake", "run", "write-flake"]).unwrap();
        match cli.command {
            Command::Flake { action: FlakeAction::Run { attr, git_only } } => {
                assert_eq!(attr, "write-flake");
                assert!(!git_only);
            }
            _ => panic!("expected Flake Run command"),
        }
    }
}

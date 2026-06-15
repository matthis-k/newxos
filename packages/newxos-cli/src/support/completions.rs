use clap::CommandFactory;
use clap_complete::{generate, Shell};

use crate::cli::{Cli, CompletionShell};

pub fn print_completions(shell: &CompletionShell) {
    let mut cmd = Cli::command();
    let shell = match shell {
        CompletionShell::Fish => Shell::Fish,
        CompletionShell::Bash => Shell::Bash,
        CompletionShell::Zsh => Shell::Zsh,
        CompletionShell::Elvish => Shell::Elvish,
        CompletionShell::PowerShell => Shell::PowerShell,
    };
    generate(shell, &mut cmd, "newxos", &mut std::io::stdout());
}

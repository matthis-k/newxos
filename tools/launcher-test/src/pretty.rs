use colored::Colorize;

use crate::schema::*;

pub fn print_case_header(name: &str, index: usize, total: usize) {
    println!("\n{} {}/{}: {}", "[CASE]".cyan().bold(), index + 1, total, name);
}

pub fn print_pass(name: &str, duration_ms: u64) {
    println!(
        "  {} {} ({}ms)",
        "[PASS]".green().bold(),
        name,
        duration_ms
    );
}

pub fn print_fail(name: &str, failures: &[String], duration_ms: u64) {
    println!(
        "  {} {} ({}ms)",
        "[FAIL]".red().bold(),
        name,
        duration_ms
    );
    for failure in failures {
        println!("    {} {}", "✗".red(), failure);
    }
}

pub fn print_skip(name: &str, reason: &str) {
    println!("  {} {} ({})", "[SKIP]".yellow().bold(), name, reason);
}

pub fn print_summary(summary: &RunSummary) {
    println!("\n{}", "═══════════════════════════════════════".cyan());
    println!("  {} {}", "Summary".bold(), "─".repeat(40));
    println!("  Total:   {}", summary.total);
    println!("  {} {}", "Passed:  ".green().bold(), summary.passed);
    if summary.failed > 0 {
        println!("  {} {}", "Failed:  ".red().bold(), summary.failed);
    }
    if summary.skipped > 0 {
        println!("  {} {}", "Skipped: ".yellow().bold(), summary.skipped);
    }
    println!("  Duration: {}ms", summary.duration_ms);
    println!("{}", "═══════════════════════════════════════".cyan());
}

pub fn print_rows(rows: &[PipelineRow]) {
    println!("  {}", "Rows:".bold().underline());
    println!(
        "  {:<4} {:<30} {:<14} {:<20} {:<5} {}",
        "Rank", "Title", "Placement", "Source", "OwnVis", "Breadcrumb"
    );
    println!("  {}", "─".repeat(90));
    for (i, row) in rows.iter().enumerate() {
        let own_vis = if row.own_visible.unwrap_or(false) { "✓" } else { " " };
        let bc = row.breadcrumb_text.as_deref().unwrap_or("");
        println!(
            "  {:<4} {:<30} {:<14} {:<20} {:<5} {}",
            i,
            row.title.as_deref().unwrap_or("").chars().take(28).collect::<String>(),
            row.placement.as_deref().unwrap_or(""),
            row.source.as_deref().unwrap_or(""),
            own_vis,
            bc
        );
    }
}

pub fn print_fixtures_intro() {
    println!(
        "{} Using fixture mode: set NEWSHELL_TEST_MODE=1 and \
         NEWSHELL_DESKTOP_FIXTURE/NEWSHELL_FILES_FIXTURE/NEWSHELL_ACTIONS_FIXTURE \
         for deterministic tests",
        "[INFO]".blue()
    );
}

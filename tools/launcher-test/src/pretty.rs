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

pub fn print_visual_state(state: &LauncherVisualState) {
    println!("  {}", "State:".bold().underline());
    println!("  Query: '{}'", state.query);
    println!(
        "  Selected: index={}, key={:?}, rows={}, {}",
        state.selected_index,
        state.selected_key.as_deref().unwrap_or(""),
        state.rows.len(),
        if state.model_busy { "busy" } else { "settled" },
    );
    if let Some(ref action) = state.last_executed_action {
        println!(
            "  Last executed: key={:?} title={:?} testMode={:?}",
            action.key, action.title, action.test_mode
        );
    }
    println!("  {}", "Rows:".bold());
    print_rows_table(&state.rows);
}

fn print_rows_table(rows: &[VisualRow]) {
    println!(
        "  {:<4} {:<5} {:<5} {:<6} {:<6} {:<12} {:<16} {:<30} {}",
        "Idx", "Sel", "Hl", "SelAb", "Exec", "Placement", "Backend", "Title", "Path"
    );
    println!("  {}", "─".repeat(120));
    for (i, row) in rows.iter().enumerate() {
        let sel = if row.selected { "✓" } else { "" };
        let hl = if row.highlighted { "✓" } else { "" };
        let sel_able = if row.selectable { "✓" } else { "" };
        let exec = if row.executable { "✓" } else { "" };
        let placement = row.placement.as_deref().unwrap_or("");
        let backend = row.backend.as_deref().unwrap_or("");
        let title: String = row.title.chars().take(28).collect();
        let path = row.path.join(" > ");
        println!(
            "  {:<4} {:<5} {:<5} {:<6} {:<6} {:<12} {:<16} {:<30} {}",
            i, sel, hl, sel_able, exec, placement, backend, title, path
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

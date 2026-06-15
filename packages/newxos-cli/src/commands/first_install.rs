use std::process::Command;

use crate::error::Result;
use crate::support::discovery;
use crate::support::process::{exec_replace, run_status};
use crate::support::repo::install_repo_root;

pub fn run(host: String) -> Result<i32> {
    let euid = libc_geteuid();
    if euid != 0 {
        let exe = std::env::current_exe()?;
        exec_replace("sudo", &[exe.to_string_lossy().to_string(), "first-install".to_string(), host.clone()])?;
        return Ok(0);
    }

    let root = install_repo_root()?;
    discovery::require_nixos_host(&root, &host)?;

    let install_user = host.split('-').next().unwrap_or(&host);
    let flake_ref = format!("path:{}#{}", root.display(), host);
    let root_mountpoint = "/mnt";

    run_status(
        "disko",
        &[
            "--mode",
            "destroy,format,mount",
            "--root-mountpoint",
            root_mountpoint,
            "--flake",
            &flake_ref,
        ],
    )?;

    install_sops_age_key(root_mountpoint)?;

    run_status(
        "nixos-install",
        &[
            "--root",
            root_mountpoint,
            "--flake",
            &flake_ref,
            "--no-root-passwd",
        ],
    )?;

    println!("=== copying newxos flake to /home/{}/newxos ===", install_user);
    copy_repo_to_home(&root, root_mountpoint, install_user)?;

    println!();
    println!("=== install complete ===");
    println!("reboot into {}", host);

    Ok(0)
}

fn install_sops_age_key(root_mountpoint: &str) -> Result<()> {
    let key_source = if std::path::Path::new("/var/lib/sops-nix/key.txt").exists() {
        Some("/var/lib/sops-nix/key.txt")
    } else if std::path::Path::new("/etc/newxos-sops-age-key.txt").exists() {
        Some("/etc/newxos-sops-age-key.txt")
    } else {
        None
    };

    if let Some(source) = key_source {
        let dest_dir = format!("{}/var/lib/sops-nix", root_mountpoint);
        let dest = format!("{}/var/lib/sops-nix/key.txt", root_mountpoint);

        run_status("install", &["-d", "-m", "0700", &dest_dir])?;
        run_status("install", &["-m", "0400", source, &dest])?;
    }

    Ok(())
}

fn copy_repo_to_home(root: &std::path::Path, root_mountpoint: &str, user: &str) -> Result<()> {
    let home_dir = format!("{}/home/{}/newxos", root_mountpoint, user);

    run_status("mkdir", &["-p", &home_dir])?;

    let rm_target = format!("{}/home/{}/newxos", root_mountpoint, user);
    run_status("rm", &["-rf", &rm_target])?;

    run_status("cp", &["-aL", &root.to_string_lossy(), &home_dir])?;

    let chown_path = format!("/home/{}/newxos", user);
    run_status(
        "chroot",
        &[
            root_mountpoint,
            "chown",
            "-R",
            &format!("{}:users", user),
            &chown_path,
        ],
    )?;

    Ok(())
}

fn libc_geteuid() -> u32 {
    Command::new("id")
        .arg("-u")
        .output()
        .ok()
        .and_then(|o| String::from_utf8_lossy(&o.stdout).trim().parse().ok())
        .unwrap_or(1000)
}

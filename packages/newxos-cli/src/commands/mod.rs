mod build_iso;
mod clean;
mod first_install;
mod flake;
mod home;
mod memory;
mod misc;
mod os;

pub use build_iso::run as build_iso;
pub use clean::run as clean;
pub use first_install::run as first_install;
pub use flake::run as flake;
pub use home::run as home;
pub use memory::run as memory;
pub use misc::{ai, dev_mode, git, reload_shell};
pub use os::run as os;

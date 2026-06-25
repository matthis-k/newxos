use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum HandoffError {
    #[error("config discovery requires rg. Install ripgrep or pass --config explicitly.")]
    NoRipgrep,
    #[error("config file not found: {0}")]
    ConfigNotFound(PathBuf),
    #[error("unsupported config version {0} in {1}")]
    UnsupportedVersion(u32, PathBuf),
    #[error("duplicate {kind} id `{id}`\n  first defined in {first}\n  redefined in {second}\n  add \"override\": true if this is intentional")]
    DuplicateId {
        kind: String,
        id: String,
        first: PathBuf,
        second: PathBuf,
    },
    #[error("cycle detected in group `{group}`")]
    CycleDetected { group: String },
    #[error("no such group or target: {0}")]
    NoSuchTarget(String),
    #[error("target `{0}` is manual; use --allow-manual to run")]
    ManualTarget(String),
    #[error("target `{0}` is a group, not executable")]
    GroupNotExecutable(String),
    #[error("no config files found")]
    NoConfigFound,
    #[error("--no-discover requires at least one --config")]
    NoDiscoverWithoutConfig,
    #[error("{0}")]
    Other(String),
}

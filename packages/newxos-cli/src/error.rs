use std::fmt;

pub type Result<T> = std::result::Result<T, CliError>;

#[derive(Debug)]
#[allow(dead_code)]
pub enum CliError {
    Message(String),
    ExitCode(i32),
}

impl fmt::Display for CliError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CliError::Message(msg) => write!(f, "{}", msg),
            CliError::ExitCode(code) => write!(f, "process exited with code {}", code),
        }
    }
}

impl std::error::Error for CliError {}

impl From<String> for CliError {
    fn from(s: String) -> Self {
        CliError::Message(s)
    }
}

impl From<&str> for CliError {
    fn from(s: &str) -> Self {
        CliError::Message(s.to_string())
    }
}

impl From<std::io::Error> for CliError {
    fn from(e: std::io::Error) -> Self {
        CliError::Message(e.to_string())
    }
}

impl From<serde_json::Error> for CliError {
    fn from(e: serde_json::Error) -> Self {
        CliError::Message(e.to_string())
    }
}

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestSuite {
    pub cases: Vec<TestCase>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestCase {
    pub name: String,
    #[serde(default)]
    pub tags: Vec<String>,
    pub query: Option<String>,
    pub expect: Option<Expectation>,
    pub setup: Option<Setup>,
    pub steps: Option<Vec<Step>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Setup {
    #[serde(default = "default_true")]
    pub reset: bool,
    #[serde(default)]
    pub visible: bool,
}

fn default_true() -> bool { true }

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum StepAction {
    #[serde(rename = "setQuery")]
    SetQuery { query: String },
    #[serde(rename = "typeText")]
    TypeText { text: String },
    #[serde(rename = "backspace")]
    Backspace { count: Option<u32> },
    #[serde(rename = "open")]
    Open { visible: Option<bool> },
    #[serde(rename = "close")]
    Close,
    #[serde(rename = "reset")]
    Reset,
    #[serde(rename = "moveSelection")]
    MoveSelection { direction: String },
    #[serde(rename = "expand")]
    Expand { selector: Option<NodeSelector> },
    #[serde(rename = "collapse")]
    Collapse { selector: Option<NodeSelector> },
    #[serde(rename = "execute")]
    Execute { selector: Option<NodeSelector> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeSelector {
    pub key: Option<String>,
    pub title: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Step {
    #[serde(rename = "do")]
    pub action: Option<StepAction>,
    pub expect: Option<Expectation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Expectation {
    pub query: Option<String>,
    pub exactly_one_selected: Option<bool>,
    pub selected: Option<RowMatcher>,
    pub expanded: Option<Vec<RowMatcher>>,
    pub rows: Option<RowsExpectation>,
    pub last_executed_action: Option<RowMatcher>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct RowsExpectation {
    pub count: Option<usize>,
    pub contains: Option<Vec<RowMatcher>>,
    pub not_contains: Option<Vec<RowMatcher>>,
    pub contains_title: Option<Vec<String>>,
    pub not_contains_title: Option<Vec<String>>,
    pub contains_in_order: Option<Vec<String>>,
    pub first: Option<RowMatcher>,
    pub none_highlighted_except_selected: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct RowMatcher {
    pub key: Option<String>,
    pub title: Option<String>,
    pub backend: Option<String>,
    pub placement: Option<String>,
    pub executable: Option<bool>,
    pub selectable: Option<bool>,
    pub selected: Option<bool>,
    pub highlighted: Option<bool>,
    pub expanded: Option<bool>,
    pub breadcrumb_text: Option<String>,
    pub path: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LauncherVisualState {
    pub version: u64,
    #[serde(rename = "type")]
    pub state_type: String,
    pub visible: bool,
    pub closing: bool,
    pub query: String,
    pub input_text: String,
    pub generation: u64,
    pub query_revision: u64,
    pub loading: bool,
    pub model_busy: bool,
    pub last_executed_action: Option<ExecutedAction>,
    pub selected_index: i64,
    pub selected_key: Option<String>,
    pub expanded_keys: Vec<String>,
    pub rows: Vec<VisualRow>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutedAction {
    pub key: Option<String>,
    pub title: Option<String>,
    pub timestamp: Option<u64>,
    pub test_mode: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VisualRow {
    pub key: String,
    pub title: String,
    pub subtitle: Option<String>,
    pub backend: Option<String>,
    pub depth: u64,
    pub path: Vec<String>,
    pub placement: Option<String>,
    pub executable: bool,
    pub selectable: bool,
    pub selected: bool,
    pub highlighted: bool,
    pub expanded: bool,
    pub visible: bool,
    pub breadcrumb_text: Option<String>,
    pub default_action: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestResult {
    pub name: String,
    pub passed: bool,
    pub failures: Vec<String>,
    pub duration_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunSummary {
    pub total: usize,
    pub passed: usize,
    pub failed: usize,
    pub skipped: usize,
    pub duration_ms: u64,
    pub results: Vec<TestResult>,
}

impl TestCase {
    pub fn normalized_steps(&self) -> Vec<NormalizedStep> {
        if let Some(ref steps) = self.steps {
            let mut out = Vec::new();
            let has_initial_reset = steps.first().map_or(false, |s| {
                matches!(s.action, Some(StepAction::Reset))
            });
            if !has_initial_reset {
                if self.setup.as_ref().map_or(true, |s| s.reset) {
                    out.push(NormalizedStep::Do(StepAction::Reset));
                }
                let visible = self.setup.as_ref().map_or(false, |s| s.visible);
                out.push(NormalizedStep::Do(StepAction::Open { visible: Some(visible) }));
            }
            for step in steps {
                if let Some(ref action) = step.action {
                    out.push(NormalizedStep::Do(action.clone()));
                }
                if let Some(ref expect) = step.expect {
                    out.push(NormalizedStep::Expect(expect.clone()));
                }
            }
            out
        } else if let Some(ref query) = self.query {
            let mut out = Vec::new();
            if self.setup.as_ref().map_or(true, |s| s.reset) {
                out.push(NormalizedStep::Do(StepAction::Reset));
            }
            out.push(NormalizedStep::Do(StepAction::Open { visible: Some(false) }));
            out.push(NormalizedStep::Do(StepAction::SetQuery { query: query.clone() }));
            if let Some(ref expect) = self.expect {
                out.push(NormalizedStep::Expect(expect.clone()));
            }
            out
        } else {
            Vec::new()
        }
    }
}

#[derive(Debug, Clone)]
pub enum NormalizedStep {
    Do(StepAction),
    Expect(Expectation),
}

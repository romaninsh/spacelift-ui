use axum::{Json, Router, extract::State, routing::get};
use serde::Serialize;

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Version {
    pub version: String,
    pub color: String,
}

impl Version {
    pub fn new(color: impl Into<String>) -> Self {
        let color = color.into();
        Self {
            version: env!("CARGO_PKG_VERSION").into(),
            color: if color.is_empty() {
                "gray".into()
            } else {
                color
            },
        }
    }

    pub fn from_env() -> Self {
        Self::new(std::env::var("COLOR").unwrap_or_default())
    }
}

pub fn app(version: Version) -> Router {
    Router::new()
        .route("/healthz", get(healthz))
        .route("/version", get(self::version))
        .with_state(version)
}

async fn healthz() -> &'static str {
    "ok"
}

async fn version(State(v): State<Version>) -> Json<Version> {
    Json(v)
}

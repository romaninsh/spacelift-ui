use axum::{Json, Router, extract::State, routing::get};
use serde::Serialize;
use tower_http::cors::CorsLayer;

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Version {
    pub version: String,
    pub env: String,
    pub color: String,
}

impl Version {
    pub fn new(env: impl Into<String>, color: impl Into<String>) -> Self {
        Self {
            version: env!("CARGO_PKG_VERSION").into(),
            env: or(env.into(), "local"),
            color: or(color.into(), "gray"),
        }
    }

    pub fn from_env() -> Self {
        Self::new(var("APP_ENV"), var("APP_COLOR"))
    }
}

pub fn app(version: Version) -> Router {
    Router::new()
        .route("/healthz", get(healthz))
        .route("/version", get(self::version))
        .layer(CorsLayer::permissive())
        .with_state(version)
}

fn var(key: &str) -> String {
    std::env::var(key).unwrap_or_default()
}

fn or(value: String, fallback: &str) -> String {
    if value.is_empty() {
        fallback.into()
    } else {
        value
    }
}

async fn healthz() -> &'static str {
    "ok"
}

async fn version(State(v): State<Version>) -> Json<Version> {
    Json(v)
}

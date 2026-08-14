use api::{Version, app};
use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use tower::ServiceExt;

async fn get(path: &str) -> (StatusCode, String) {
    let response = app(Version::new("local", "green"))
        .oneshot(Request::builder().uri(path).body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = response.status();
    let body = response.into_body().collect().await.unwrap().to_bytes();
    (status, String::from_utf8(body.to_vec()).unwrap())
}

#[test]
fn version_reports_the_crate_version_and_the_given_colour() {
    let version = Version::new("local", "blue");

    assert_eq!(version.version, env!("CARGO_PKG_VERSION"));
    assert_eq!(version.color, "blue");
}

#[test]
fn version_falls_back_to_local_and_gray_when_nothing_is_configured() {
    assert_eq!(Version::new("", "").color, "gray");
    assert_eq!(Version::new("", "").env, "local");
}

#[tokio::test]
async fn healthz_reports_the_service_is_serving() {
    let (status, body) = get("/healthz").await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(body, "ok");
}

#[tokio::test]
async fn version_endpoint_returns_json() {
    let (status, body) = get("/version").await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(
        serde_json::from_str::<serde_json::Value>(&body).unwrap(),
        serde_json::json!({ "version": env!("CARGO_PKG_VERSION"), "env": "local", "color": "green" })
    );
}

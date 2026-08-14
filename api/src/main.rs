#[tokio::main]
async fn main() {
    let host = std::env::var("SERVICE_HOST").unwrap_or_else(|_| "127.0.0.1".into());
    let port = std::env::var("SERVICE_PORT").unwrap_or_else(|_| "8080".into());
    let listener = tokio::net::TcpListener::bind(format!("{host}:{port}"))
        .await
        .unwrap();
    axum::serve(listener, api::app(api::Version::from_env()))
        .await
        .unwrap();
}

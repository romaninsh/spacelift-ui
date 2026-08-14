FROM rust:1-slim AS build
WORKDIR /src
COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
    && echo 'fn main() {}' > src/main.rs \
    && touch src/lib.rs \
    && cargo build --release --locked \
    && rm -rf src
COPY src src
RUN touch src/lib.rs src/main.rs && cargo build --release --locked

FROM debian:trixie-slim
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app
COPY --from=build /src/target/release/api /usr/local/bin/api
USER 10001
EXPOSE 8080
CMD ["api"]

API_PORT ?= 8080
FRONTEND_PORT ?= 8081
COLOR ?= green

.PHONY: install build test lint fmt clean api frontend dev

install:
	cd frontend && npm install

build:
	cd api && cargo build --release
	cd frontend && npm run build

test:
	cd api && cargo test

lint:
	cd api && cargo fmt --check && cargo clippy --all-targets -- -D warnings
	cd frontend && npx tsc -b && npm run lint

fmt:
	cd api && cargo fmt

clean:
	cd api && cargo clean
	rm -rf frontend/dist frontend/node_modules

api:
	cd api && COLOR=$(COLOR) SERVICE_PORT=$(API_PORT) cargo run

frontend:
	cd frontend && npm run dev -- --port $(FRONTEND_PORT)

dev:
	@trap 'kill 0' EXIT INT TERM; \
	$(MAKE) api & \
	$(MAKE) frontend & \
	wait

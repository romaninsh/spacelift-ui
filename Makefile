API_PORT ?= 8080
FRONTEND_PORT ?= 8081
APP_COLOR ?= green

.PHONY: install build test lint fmt clean api frontend dev up down spacelift-token

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
	cd api && APP_COLOR=$(APP_COLOR) SERVICE_PORT=$(API_PORT) cargo run

frontend:
	cd frontend && npm run dev -- --port $(FRONTEND_PORT)

dev:
	@trap 'kill 0' EXIT INT TERM; \
	$(MAKE) api & \
	$(MAKE) frontend & \
	wait

up:
	docker compose up --build

down:
	docker compose down

# Mint a fresh 10-hour Spacelift JWT into admin-2/.env, which the graphql
# datasource reads as ${SPACELIFT_TOKEN}.
spacelift-token:
	@set -a; . .secret/spacelift.env; set +a; \
	token=$$(spacectl profile export-token 2>/dev/null); \
	[ -n "$$token" ] || { echo "spacectl returned no token"; exit 1; }; \
	sed -i '' "s|^SPACELIFT_TOKEN=.*|SPACELIFT_TOKEN=$$token|" admin-2/.env; \
	echo "admin-2/.env updated"

type Raw = {
  API_URL?: string
  SPAWN_SPEED?: string
  ENV?: string
}

declare global {
  interface Window {
    __CONFIG__?: Raw
  }
}

const raw: Raw = window.__CONFIG__ ?? {}

export const config = {
  apiUrl: raw.API_URL || 'http://127.0.0.1:8080',
  spawnSpeed: Number(raw.SPAWN_SPEED) || 2,
  env: raw.ENV || 'local',
}

export const version = __APP_VERSION__

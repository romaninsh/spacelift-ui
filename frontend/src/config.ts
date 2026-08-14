export type Config = {
  apiUrl: string
  spawnSpeed: number
}

declare global {
  interface Window {
    __CONFIG__?: Partial<Config>
  }
}

export const config: Config = {
  apiUrl: window.__CONFIG__?.apiUrl ?? 'http://127.0.0.1:8080',
  spawnSpeed: Number(window.__CONFIG__?.spawnSpeed) || 2,
}

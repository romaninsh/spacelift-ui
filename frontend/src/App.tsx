import { useEffect, useRef, useState } from 'react'
import { config, version as appVersion } from './config'

type Version = { version: string; color: string }

type Bubble = { id: number; left: number; size: number; duration: number; color: string }

const unreachable: Version = { version: 'unreachable', color: 'gray' }

export default function App() {
  const [version, setVersion] = useState<Version>({ version: '…', color: 'gray' })
  const [bubbles, setBubbles] = useState<Bubble[]>([])
  const nextId = useRef(0)

  useEffect(() => {
    let live = true
    const poll = async () => {
      try {
        const response = await fetch(`${config.apiUrl}/version`)
        if (!response.ok) throw new Error(String(response.status))
        const next: Version = await response.json()
        if (live) setVersion(next)
      } catch {
        if (live) setVersion(unreachable)
      }
    }
    poll()
    const timer = setInterval(poll, 1000)
    return () => {
      live = false
      clearInterval(timer)
    }
  }, [])

  useEffect(() => {
    const timer = setInterval(() => {
      setBubbles((current) => [
        ...current,
        {
          id: nextId.current++,
          left: Math.random() * 92,
          size: 24 + Math.random() * 48,
          duration: 5 + Math.random() * 4,
          color: version.color,
        },
      ])
    }, 1000 / config.spawnSpeed)
    return () => clearInterval(timer)
  }, [version.color])

  return (
    <div className="h-screen overflow-hidden bg-slate-950 font-mono text-slate-200">
      <header className="flex items-center gap-3 border-b border-slate-800 px-4 py-3 text-sm">
        <span
          className="size-3 rounded-full ring-2 ring-slate-700"
          style={{ background: version.color }}
        />
        <span className="font-semibold">{version.version}</span>
        <span className="text-slate-500">{version.color}</span>
        <span className="ml-auto text-slate-600">{config.spawnSpeed}/s</span>
      </header>

      <main className="relative h-[calc(100vh-49px)]">
        {bubbles.map((bubble) => (
          <span
            key={bubble.id}
            className="bubble absolute bottom-0 rounded-full blur-[0.5px]"
            style={{
              left: `${bubble.left}%`,
              width: bubble.size,
              height: bubble.size,
              background: bubble.color,
              animationDuration: `${bubble.duration}s`,
            }}
            onAnimationEnd={() =>
              setBubbles((current) => current.filter((each) => each.id !== bubble.id))
            }
          />
        ))}
      </main>

      <footer className="pointer-events-none fixed bottom-0 left-0 px-4 py-3 text-xs text-slate-600">
        frontend {appVersion}
      </footer>
    </div>
  )
}

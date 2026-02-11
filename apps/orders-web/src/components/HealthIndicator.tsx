import { useEffect, useState } from 'react'
import { checkHealth } from '../api/orders'

function getDotColor(status: 'checking' | 'healthy' | 'unhealthy'): string {
  if (status === 'healthy') return 'bg-green-500'
  if (status === 'unhealthy') return 'bg-red-500'
  return 'bg-yellow-500 animate-pulse'
}

export default function HealthIndicator() {
  const [status, setStatus] = useState<'checking' | 'healthy' | 'unhealthy'>('checking')

  useEffect(() => {
    let cancelled = false
    const check = async () => {
      try {
        const { ok } = await checkHealth()
        if (!cancelled) setStatus(ok ? 'healthy' : 'unhealthy')
      } catch {
        if (!cancelled) setStatus('unhealthy')
      }
    }
    check()
    const id = setInterval(check, 30000)
    return () => {
      cancelled = true
      clearInterval(id)
    }
  }, [])

  const dotColor = getDotColor(status)

  return (
    <span
      className="inline-flex items-center gap-1.5 text-sm"
      title={`API: ${status}`}
    >
      <span
        className={`h-2 w-2 rounded-full ${dotColor}`}
        aria-hidden
      />
      API {status}
    </span>
  )
}

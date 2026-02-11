import { Link } from 'react-router-dom'
import HealthIndicator from './HealthIndicator'
import type { ReactNode } from 'react'

interface LayoutProps {
  children: ReactNode
}

export default function Layout({ children }: LayoutProps) {
  return (
    <div style={{ maxWidth: 960, margin: '0 auto', padding: 24 }}>
      <nav style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: 16 }}>
          <Link to="/">Orders</Link>
          <Link to="/new">New Order</Link>
        </div>
        <HealthIndicator />
      </nav>
      <main>{children}</main>
    </div>
  )
}

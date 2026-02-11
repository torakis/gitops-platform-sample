import type { Order, CreateOrderRequest } from '../types/order'

// VITE_API_URL: set for custom API base (e.g. http://localhost:5000); empty = same-origin
const API_BASE = import.meta.env.VITE_API_URL ?? ''

async function fetchApi<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

export async function listOrders(): Promise<Order[]> {
  return fetchApi<Order[]>('/api/orders')
}

export async function getOrder(id: number): Promise<Order> {
  return fetchApi<Order>(`/api/orders/${id}`)
}

export async function createOrder(data: CreateOrderRequest): Promise<Order> {
  return fetchApi<Order>('/api/orders', {
    method: 'POST',
    body: JSON.stringify(data),
  })
}

export async function checkHealth(): Promise<{ ok: boolean }> {
  const res = await fetch(`${API_BASE}/healthz`)
  return { ok: res.ok }
}

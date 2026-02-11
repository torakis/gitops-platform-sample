import { useEffect, useState } from 'react'
import { listOrders } from '../api/orders'
import type { Order } from '../types/order'

export default function OrderList() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    listOrders()
      .then(setOrders)
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <p>Loading orders...</p>
  if (error) return <p style={{ color: 'red' }}>Error: {error}</p>

  return (
    <div>
      <h1>Orders</h1>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ textAlign: 'left', borderBottom: '2px solid #ddd' }}>
            <th>ID</th>
            <th>Customer</th>
            <th>Product</th>
            <th>Qty</th>
            <th>Price</th>
            <th>Status</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.id} style={{ borderBottom: '1px solid #eee' }}>
              <td>{o.id}</td>
              <td>{o.customerName}</td>
              <td>{o.product}</td>
              <td>{o.quantity}</td>
              <td>${o.unitPrice.toFixed(2)}</td>
              <td>{o.status}</td>
              <td>{new Date(o.createdAt).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {orders.length === 0 && <p>No orders yet.</p>}
    </div>
  )
}

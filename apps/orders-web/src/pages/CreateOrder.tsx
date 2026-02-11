import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { createOrder } from '../api/orders'

export default function CreateOrder() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState({
    customerName: '',
    product: '',
    quantity: 1,
    unitPrice: 0,
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      await createOrder(form)
      navigate('/')
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create order')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h1>Create Order</h1>
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 12, maxWidth: 400 }}>
        <label>
          Customer Name
          <input
            type="text"
            value={form.customerName}
            onChange={(e) => setForm((f) => ({ ...f, customerName: e.target.value }))}
            required
          />
        </label>
        <label>
          Product
          <input
            type="text"
            value={form.product}
            onChange={(e) => setForm((f) => ({ ...f, product: e.target.value }))}
            required
          />
        </label>
        <label>
          Quantity
          <input
            type="number"
            min={1}
            value={form.quantity}
            onChange={(e) => setForm((f) => ({ ...f, quantity: parseInt(e.target.value) || 1 }))}
          />
        </label>
        <label>
          Unit Price
          <input
            type="number"
            min={0}
            step={0.01}
            value={form.unitPrice}
            onChange={(e) => setForm((f) => ({ ...f, unitPrice: parseFloat(e.target.value) || 0 }))}
          />
        </label>
        {error && <p style={{ color: 'red' }}>{error}</p>}
        <button type="submit" disabled={loading}>
          {loading ? 'Creating...' : 'Create Order'}
        </button>
      </form>
    </div>
  )
}

export type OrderStatus = 'Pending' | 'Processing' | 'Processed' | 'Shipped' | 'Delivered' | 'Cancelled'

export interface Order {
  id: number
  customerName: string
  product: string
  quantity: number
  unitPrice: number
  status: OrderStatus
  createdAt: string
  updatedAt?: string
}

export interface CreateOrderRequest {
  customerName: string
  product: string
  quantity: number
  unitPrice: number
}

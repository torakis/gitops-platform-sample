import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import App from './App'

function renderApp() {
  return render(
    <BrowserRouter>
      <App />
    </BrowserRouter>
  )
}

describe('App', () => {
  it('renders orders link', () => {
    renderApp()
    expect(screen.getByText('Orders')).toBeInTheDocument()
  })
})

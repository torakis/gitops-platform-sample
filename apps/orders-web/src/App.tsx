import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import OrderList from './pages/OrderList'
import CreateOrder from './pages/CreateOrder'

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<OrderList />} />
          <Route path="/new" element={<CreateOrder />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  )
}

export default App

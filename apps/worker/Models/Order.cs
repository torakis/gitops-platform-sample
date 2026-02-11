namespace Worker.Models;

public class Order
{
    public int Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Product { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public OrderStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public enum OrderStatus
{
    Pending = 0,
    Processing = 1,
    Processed = 2,
    Shipped = 3,
    Delivered = 4,
    Cancelled = 5
}

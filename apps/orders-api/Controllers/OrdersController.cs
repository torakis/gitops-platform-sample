using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OrdersApi.Data;
using OrdersApi.Models;
using OrdersApi.Services;

namespace OrdersApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly OrdersDbContext _db;
    private readonly FeatureFlags _featureFlags;
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(OrdersDbContext db, FeatureFlags featureFlags, ILogger<OrdersController> logger)
    {
        _db = db;
        _featureFlags = featureFlags;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Order>>> List(CancellationToken ct)
    {
        _logger.LogInformation("Listing orders");
        var orders = await _db.Orders
            .OrderByDescending(o => o.CreatedAt)
            .Take(100)
            .ToListAsync(ct);
        return Ok(orders);
    }

    [HttpPost]
    public async Task<ActionResult<Order>> Create([FromBody] CreateOrderRequest req, CancellationToken ct)
    {
        decimal unitPrice = req.UnitPrice;
        if (_featureFlags.EnableDiscounts)
        {
            unitPrice *= 0.9m;
            _logger.LogInformation("Discount applied (EnableDiscounts=true): {Original} -> {Discounted}",
                req.UnitPrice, unitPrice);
        }

        var order = new Order
        {
            CustomerName = req.CustomerName,
            Product = req.Product,
            Quantity = req.Quantity,
            UnitPrice = unitPrice,
            Status = OrderStatus.Pending
        };
        _db.Orders.Add(order);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Order created {OrderId} for {Customer}", order.Id, order.CustomerName);
        return CreatedAtAction(nameof(Get), new { id = order.Id }, order);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Order>> Get(int id, CancellationToken ct)
    {
        var order = await _db.Orders.FindAsync(new object[] { id }, ct);
        return order == null ? NotFound() : Ok(order);
    }

    [HttpPatch("{id:int}/status")]
    public async Task<ActionResult<Order>> UpdateStatus(int id, [FromBody] UpdateStatusRequest req, CancellationToken ct)
    {
        var order = await _db.Orders.FindAsync(new object[] { id }, ct);
        if (order == null) return NotFound();
        order.Status = req.Status;
        order.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        return Ok(order);
    }
}

public record CreateOrderRequest(string CustomerName, string Product, int Quantity, decimal UnitPrice);
public record UpdateStatusRequest(OrderStatus Status);

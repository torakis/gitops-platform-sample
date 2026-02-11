using Microsoft.EntityFrameworkCore;
using Worker.Data;
using Worker.Models;

namespace Worker.Services;

public class OrderProcessorService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<OrderProcessorService> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromSeconds(10);
    private readonly TimeSpan _processingDelay = TimeSpan.FromSeconds(5);

    public OrderProcessorService(IServiceProvider services, ILogger<OrderProcessorService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Order processor started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOrdersAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing orders");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task ProcessOrdersAsync(CancellationToken ct)
    {
        await using var scope = _services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();

        // Step 1: Pending -> Processing
        var pending = await db.Orders
            .Where(o => o.Status == OrderStatus.Pending)
            .Take(5)
            .ToListAsync(ct);

        foreach (var order in pending)
        {
            order.Status = OrderStatus.Processing;
            order.UpdatedAt = DateTime.UtcNow;
            _logger.LogInformation("Processing order {OrderId} for {Customer}", order.Id, order.CustomerName);
        }

        if (pending.Count > 0)
            await db.SaveChangesAsync(ct);

        // Step 2: Processing -> Processed (after delay)
        var processing = await db.Orders
            .Where(o => o.Status == OrderStatus.Processing
                && o.UpdatedAt != null
                && o.UpdatedAt.Value.Add(_processingDelay) <= DateTime.UtcNow)
            .Take(5)
            .ToListAsync(ct);

        foreach (var order in processing)
        {
            order.Status = OrderStatus.Processed;
            order.UpdatedAt = DateTime.UtcNow;
            _logger.LogInformation("Order {OrderId} marked processed", order.Id);
        }

        if (processing.Count > 0)
            await db.SaveChangesAsync(ct);
    }
}

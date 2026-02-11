using Microsoft.EntityFrameworkCore;
using OrdersApi.Models;

namespace OrdersApi.Data;

public class OrdersDbContext : DbContext
{
    public OrdersDbContext(DbContextOptions<OrdersDbContext> options)
        : base(options) { }

    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Order>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.CustomerName).HasMaxLength(200);
            e.Property(x => x.Product).HasMaxLength(200);
            e.Property(x => x.UnitPrice).HasPrecision(18, 2);
        });
    }
}

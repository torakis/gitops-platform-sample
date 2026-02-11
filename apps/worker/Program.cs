using Microsoft.EntityFrameworkCore;
using Worker.Data;
using Worker.Services;

var builder = WebApplication.CreateBuilder(args);

var conn = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Host=localhost;Database=orders;Username=postgres;Password=postgres";

builder.Services.AddDbContext<OrdersDbContext>(options =>
    options.UseNpgsql(conn));

builder.Services.AddHostedService<OrderProcessorService>();

var app = builder.Build();

app.MapGet("/healthz", () => Results.Ok());
app.MapGet("/readyz", () => Results.Ok());

app.Run();

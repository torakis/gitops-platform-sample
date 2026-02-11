using Microsoft.EntityFrameworkCore;
using OrdersApi.Data;
using OrdersApi.Extensions;
using OrdersApi.Services;
using Prometheus;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Structured logging
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "orders-api")
    .WriteTo.Console(new Serilog.Formatting.Json.JsonFormatter())
    .CreateLogger();

builder.Host.UseSerilog();

// Database
builder.Services.AddDbContext<OrdersDbContext>(options =>
{
    var conn = builder.Configuration.GetConnectionString("DefaultConnection")
        ?? "Host=localhost;Database=orders;Username=postgres;Password=postgres";
    options.UseNpgsql(conn);
});

// Feature flags (from ConfigMap env: FeatureFlags__EnableDiscounts=true)
builder.Services.AddSingleton(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    return new FeatureFlags
    {
        EnableDiscounts = config.GetValue<bool>("FeatureFlags:EnableDiscounts")
    };
});

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Health checks
builder.Services.AddHealthChecks()
    .AddNpgSql(builder.Configuration.GetConnectionString("DefaultConnection")
        ?? "Host=localhost;Database=orders;Username=postgres;Password=postgres", name: "postgres");

var app = builder.Build();

// Migrate on startup (dev/staging; in prod use init containers or separate jobs)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
    db.Database.Migrate();
}

app.UseCorrelationId();
app.UseCors();
app.UseSerilogRequestLogging();
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpMetrics();
app.MapControllers();

// Kubernetes-style health endpoints
app.MapHealthChecks("/healthz");
app.MapHealthChecks("/readyz");

// Prometheus metrics (see docs/orders-api-metrics.md)
app.MapMetrics();

app.Run();

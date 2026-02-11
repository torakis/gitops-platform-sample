using Prometheus;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(o => o.ListenAnyIP(8080));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseHttpMetrics();
app.MapMetrics();

app.MapGet("/healthz", () => Results.Ok());
app.MapGet("/readyz", () => Results.Ok());

app.MapGet("/api/hello", (string? name) =>
{
    var n = name ?? "world";
    return Results.Ok(new { message = $"Hello, {n}!" });
});

app.Run();

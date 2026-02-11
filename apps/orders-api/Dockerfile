# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file first for layer cache
COPY ["OrdersApi.csproj", "."]
RUN dotnet restore --no-cache

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Runtime stage (minimal)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

RUN adduser --disabled-password --gecos "" appuser
USER appuser

COPY --from=build /app/publish .
EXPOSE 5000
ENTRYPOINT ["dotnet", "OrdersApi.dll"]

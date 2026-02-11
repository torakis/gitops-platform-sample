# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore && dotnet publish -c Release -o /app/publish

# Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
RUN adduser --disabled-password --gecos "" appuser
USER appuser
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "MyService.dll"]

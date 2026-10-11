$mvn = if (Get-Command mvn -ErrorAction SilentlyContinue) { "mvn" } else { "C:\Program Files\JetBrains\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin\mvn.cmd" }

Write-Host "Building all microservices..."
& $mvn clean install -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit $LASTEXITCODE
}

Write-Host "Starting Resource Service (Port 9191)..."
Start-Process -FilePath $mvn -ArgumentList "spring-boot:run" -WorkingDirectory "resource-service" -WindowStyle Minimized

Write-Host "Starting Inventory Service (Port 9192)..."
Start-Process -FilePath $mvn -ArgumentList "spring-boot:run" -WorkingDirectory "inventory-service" -WindowStyle Minimized

Write-Host "Starting Request Service (Port 9193)..."
Start-Process -FilePath $mvn -ArgumentList "spring-boot:run" -WorkingDirectory "request-service" -WindowStyle Minimized

Write-Host "Starting Frontend UI (Port 8080)..."
Start-Process -FilePath $mvn -ArgumentList "spring-boot:run" -WorkingDirectory "frontend-ui" -WindowStyle Minimized

Write-Host "=================================================="
Write-Host "All services are booting up in new windows!"
Write-Host "Resource Service:  http://localhost:9191/swagger-ui.html"
Write-Host "Inventory Service: http://localhost:9192/swagger-ui.html"
Write-Host "Request Service:   http://localhost:9193/swagger-ui.html"
Write-Host "Frontend UI:       http://localhost:8080"
Write-Host "=================================================="
Write-Host "Close the respective terminal windows to stop the services."

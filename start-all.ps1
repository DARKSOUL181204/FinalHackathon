$mvn = if (Get-Command mvn -ErrorAction SilentlyContinue) { "mvn" } else { "C:\Program Files\JetBrains\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin\mvn.cmd" }

Write-Host "Building all microservices..."
& $mvn clean install -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit $LASTEXITCODE
}

Write-Host "Starting Resource Service (Port 9191)..." -ForegroundColor Cyan
$p1 = Start-Process -FilePath "java" -ArgumentList "-jar", "resource-service/target/resource-service-1.0.0-SNAPSHOT.jar" -PassThru -WindowStyle Minimized

Write-Host "Starting Inventory Service (Port 9192)..." -ForegroundColor Cyan
$p2 = Start-Process -FilePath "java" -ArgumentList "-jar", "inventory-service/target/inventory-service-1.0.0-SNAPSHOT.jar" -PassThru -WindowStyle Minimized

Write-Host "Starting Request Service (Port 9193)..." -ForegroundColor Cyan
$p3 = Start-Process -FilePath "java" -ArgumentList "-jar", "request-service/target/request-service-1.0.0-SNAPSHOT.jar" -PassThru -WindowStyle Minimized

Write-Host "Starting Frontend UI (Port 8080)..." -ForegroundColor Cyan
$p4 = Start-Process -FilePath "java" -ArgumentList "-jar", "frontend-ui/target/frontend-ui-1.0.0-SNAPSHOT.jar" -PassThru -WindowStyle Minimized

Start-Sleep -Seconds 6

if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Seeding sample data..." -ForegroundColor Cyan
    python seed_data.py
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    Write-Host "Seeding sample data..." -ForegroundColor Cyan
    python3 seed_data.py
}

Write-Host "==================================================" -ForegroundColor Green
Write-Host "All 4 services are running!" -ForegroundColor Green
Write-Host "Frontend UI:   http://localhost:8080" -ForegroundColor Green
Write-Host "Default Login: admin / ChangeMe!2026" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Press any key to stop all services..."

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Stop-Process -Id $p1.Id, $p2.Id, $p3.Id, $p4.Id -Force -ErrorAction SilentlyContinue


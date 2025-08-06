# COGITATIVOSHIELD DASHBOARD LAUNCHER
# Starts the Security Operations Center Dashboard

clear
Write-Host ""
Write-Host "  ┌────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │          COGITATIVOSHIELD SOC              │" -ForegroundColor Cyan
Write-Host "  │      Security Operations Dashboard         │" -ForegroundColor Cyan
Write-Host "  └────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DashboardPath = "C:\Users\andre.darby\Ops\SOC-Dashboard.html"
$BackendScript = "C:\Users\andre.darby\Ops\Dashboard-Backend.ps1"
$DataPath = "C:\SecurityOps\DashboardData"
$Port = 8080

# Create data directory
if (!(Test-Path $DataPath)) {
    Write-Host "[✓] Creating data directory..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
}

# Check if dashboard file exists
if (!(Test-Path $DashboardPath)) {
    Write-Host "[×] Dashboard file not found: $DashboardPath" -ForegroundColor Red
    exit 1
}

# Function to start local web server
function Start-LocalWebServer {
    param(
        [int]$Port = 8080,
        [string]$Path
    )
    
    Write-Host "[→] Starting local web server on port $Port..." -ForegroundColor Yellow
    
    # Create a simple HTTP listener
    $http = [System.Net.HttpListener]::new()
    $http.Prefixes.Add("http://localhost:$Port/")
    
    try {
        $http.Start()
        Write-Host "[✓] Web server started at http://localhost:$Port" -ForegroundColor Green
        
        # Open browser
        Write-Host "[→] Opening dashboard in browser..." -ForegroundColor Yellow
        Start-Process "http://localhost:$Port/dashboard"
        
        Write-Host "`n🌐 Dashboard is running!" -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Cyan
        
        # Serve requests
        while ($http.IsListening) {
            $context = $http.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # Serve dashboard HTML
            if ($request.Url.LocalPath -eq "/dashboard" -or $request.Url.LocalPath -eq "/") {
                $html = Get-Content $DashboardPath -Raw
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentType = "text/html"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            # Serve data JSON
            elseif ($request.Url.LocalPath -eq "/api/data") {
                $jsonPath = "$DataPath\dashboard-data.json"
                if (Test-Path $jsonPath) {
                    $json = Get-Content $jsonPath -Raw
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json"
                    $response.Headers.Add("Access-Control-Allow-Origin", "*")
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                } else {
                    $response.StatusCode = 404
                }
            }
            # Execute commands
            elseif ($request.Url.LocalPath -eq "/api/command" -and $request.HttpMethod -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream)
                $body = $reader.ReadToEnd()
                $command = $body | ConvertFrom-Json
                
                # Execute the command
                $result = & $BackendScript -Command $command.Name -Parameters $command.Parameters
                
                $json = $result | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentType = "application/json"
                $response.Headers.Add("Access-Control-Allow-Origin", "*")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            else {
                $response.StatusCode = 404
            }
            
            $response.Close()
        }
    } catch {
        Write-Host "[×] Error: $_" -ForegroundColor Red
    } finally {
        $http.Stop()
        Write-Host "`n[✓] Server stopped" -ForegroundColor Yellow
    }
}

# Alternative: Simple browser launch
Write-Host ""
Write-Host "Choose launch method:" -ForegroundColor Cyan
Write-Host "  [1] Open dashboard directly (simple)" -ForegroundColor White
Write-Host "  [2] Start local web server (advanced)" -ForegroundColor White
Write-Host "  [3] Update data only" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1-3)"

switch ($choice) {
    "1" {
        # Simple launch - just open the HTML file
        Write-Host "`n[→] Updating dashboard data..." -ForegroundColor Yellow
        & $BackendScript
        
        Write-Host "[→] Opening dashboard..." -ForegroundColor Yellow
        Start-Process $DashboardPath
        
        Write-Host "`n✅ Dashboard opened!" -ForegroundColor Green
        Write-Host ""
Write-Host "Dashboard Features:" -ForegroundColor Cyan
        Write-Host "  • Real-time security metrics" -ForegroundColor White
        Write-Host "  • Live activity feed" -ForegroundColor White
        Write-Host "  • Quick action buttons" -ForegroundColor White
        Write-Host "  • Command terminal" -ForegroundColor White
        Write-Host "  • Top security reporters" -ForegroundColor White
        
        Write-Host "`nNote: For real-time updates, run the backend script periodically" -ForegroundColor Yellow
        Write-Host "Command: & '$BackendScript'" -ForegroundColor Gray
    }
    
    "2" {
        # Advanced - start web server
        Write-Host "`n[→] Updating dashboard data..." -ForegroundColor Yellow
        & $BackendScript
        
        Start-LocalWebServer -Port $Port -Path $DashboardPath
    }
    
    "3" {
        # Update data only
        Write-Host "`n[→] Updating dashboard data..." -ForegroundColor Yellow
        & $BackendScript
        
        Write-Host "`n✅ Data updated successfully!" -ForegroundColor Green
        Write-Host "Dashboard data location: $DataPath\dashboard-data.json" -ForegroundColor Cyan
    }
    
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    }
}

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  Thank you for using CogitativoShield!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
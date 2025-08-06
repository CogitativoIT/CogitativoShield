# SIMPLE SECURITY WORKFLOW TEST
Write-Host "Security Operations Test - $(Get-Date)" -ForegroundColor Cyan

# Test scheduled tasks
Write-Host "`nChecking scheduled tasks..." -ForegroundColor Yellow
$tasks = Get-ScheduledTask -TaskPath "\SecurityOps\*" -ErrorAction SilentlyContinue
if ($tasks) {
    Write-Host "Found $($tasks.Count) scheduled tasks:" -ForegroundColor Green
    $tasks | ForEach-Object {
        Write-Host "  - $($_.TaskName): $($_.State)"
    }
} else {
    Write-Host "No tasks found in \SecurityOps" -ForegroundColor Red
}

# Test directories
Write-Host "`nChecking directories..." -ForegroundColor Yellow
$dirs = @("C:\SecurityOps\DMARC", "C:\SecurityOps\Phishing", "C:\SecurityOps\DailyReports", "C:\SecurityOps\Logs")
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Write-Host "  OK: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $dir" -ForegroundColor Red
    }
}

# Test scripts
Write-Host "`nChecking scripts..." -ForegroundColor Yellow
$scripts = @(
    "PROCESS-DMARC-REPORTS.ps1",
    "RESPOND-TO-PHISHING.ps1",
    "DAILY-SECURITY-REPORT.ps1",
    "SETUP-SCHEDULED-TASKS.ps1"
)
foreach ($script in $scripts) {
    $path = "C:\Users\andre.darby\Ops\$script"
    if (Test-Path $path) {
        Write-Host "  OK: $script" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $script" -ForegroundColor Red
    }
}

Write-Host "`nTest complete!" -ForegroundColor Green
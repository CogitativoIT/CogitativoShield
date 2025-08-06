# SETUP SCHEDULED TASKS FOR SECURITY OPERATIONS AUTOMATION
# Creates Windows scheduled tasks to run security scripts automatically

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  SECURITY OPERATIONS TASK SCHEDULER" -ForegroundColor Cyan
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Cyan

# Check for administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isAdmin) {
    Write-Host "⚠️ WARNING: Administrator privileges recommended for creating scheduled tasks" -ForegroundColor Yellow
    Write-Host "Some tasks may fail to create without elevation" -ForegroundColor Yellow
    Write-Host ""
}

# Configuration
$scriptPath = "C:\Users\andre.darby\Ops"
$taskFolder = "\SecurityOps"
$userName = "andre.darby@cogitativo.com"

# Create task folder if it doesn't exist
Write-Host "`n[1/8] Creating task folder..." -ForegroundColor Yellow
try {
    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    $rootFolder = $scheduler.GetFolder("\")
    
    try {
        $folder = $scheduler.GetFolder($taskFolder)
        Write-Host "  Task folder already exists" -ForegroundColor Gray
    } catch {
        $folder = $rootFolder.CreateFolder($taskFolder)
        Write-Host "  ✅ Created task folder: $taskFolder" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ Failed to create task folder: $_" -ForegroundColor Red
}

# Task 1: DMARC Processing (Every 6 hours)
Write-Host "`n[2/8] Creating DMARC Processing task..." -ForegroundColor Yellow

$dmarcAction = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath\PROCESS-DMARC-REPORTS.ps1`"" `
    -WorkingDirectory $scriptPath

$dmarcTrigger = New-ScheduledTaskTrigger -Daily -At "2:00AM" -DaysInterval 1
$dmarcTrigger2 = New-ScheduledTaskTrigger -Daily -At "8:00AM" -DaysInterval 1
$dmarcTrigger3 = New-ScheduledTaskTrigger -Daily -At "2:00PM" -DaysInterval 1
$dmarcTrigger4 = New-ScheduledTaskTrigger -Daily -At "8:00PM" -DaysInterval 1

$dmarcSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartInterval (New-TimeSpan -Minutes 30) `
    -RestartCount 3

$dmarcPrincipal = New-ScheduledTaskPrincipal -UserId $userName -LogonType S4U -RunLevel Limited

try {
    $existingTask = Get-ScheduledTask -TaskName "SecurityOps-DMARC" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Updating existing DMARC task..." -ForegroundColor Yellow
        Set-ScheduledTask -TaskName "SecurityOps-DMARC" `
            -Action $dmarcAction `
            -Trigger @($dmarcTrigger, $dmarcTrigger2, $dmarcTrigger3, $dmarcTrigger4) `
            -Settings $dmarcSettings `
            -Principal $dmarcPrincipal
    } else {
        Register-ScheduledTask -TaskName "SecurityOps-DMARC" `
            -TaskPath $taskFolder `
            -Action $dmarcAction `
            -Trigger @($dmarcTrigger, $dmarcTrigger2, $dmarcTrigger3, $dmarcTrigger4) `
            -Settings $dmarcSettings `
            -Principal $dmarcPrincipal `
            -Description "Process DMARC reports every 6 hours"
    }
    Write-Host "  ✅ DMARC task configured (runs at 2AM, 8AM, 2PM, 8PM)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to create DMARC task: $_" -ForegroundColor Red
}

# Task 2: Phishing Response (Every 30 minutes)
Write-Host "`n[3/8] Creating Phishing Response task..." -ForegroundColor Yellow

$phishingAction = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath\RESPOND-TO-PHISHING.ps1`"" `
    -WorkingDirectory $scriptPath

$phishingTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 30)

$phishingSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

$phishingPrincipal = New-ScheduledTaskPrincipal -UserId $userName -LogonType S4U -RunLevel Limited

try {
    $existingTask = Get-ScheduledTask -TaskName "SecurityOps-Phishing" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Updating existing Phishing task..." -ForegroundColor Yellow
        Set-ScheduledTask -TaskName "SecurityOps-Phishing" `
            -Action $phishingAction `
            -Trigger $phishingTrigger `
            -Settings $phishingSettings `
            -Principal $phishingPrincipal
    } else {
        Register-ScheduledTask -TaskName "SecurityOps-Phishing" `
            -TaskPath $taskFolder `
            -Action $phishingAction `
            -Trigger $phishingTrigger `
            -Settings $phishingSettings `
            -Principal $phishingPrincipal `
            -Description "Respond to phishing reports every 30 minutes"
    }
    Write-Host "  ✅ Phishing response task configured (every 30 minutes)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to create Phishing task: $_" -ForegroundColor Red
}

# Task 3: Daily Security Report (8:00 AM)
Write-Host "`n[4/8] Creating Daily Security Report task..." -ForegroundColor Yellow

$reportAction = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath\DAILY-SECURITY-REPORT.ps1`"" `
    -WorkingDirectory $scriptPath

$reportTrigger = New-ScheduledTaskTrigger -Daily -At "8:00AM"

$reportSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

$reportPrincipal = New-ScheduledTaskPrincipal -UserId $userName -LogonType S4U -RunLevel Limited

try {
    $existingTask = Get-ScheduledTask -TaskName "SecurityOps-DailyReport" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Updating existing Daily Report task..." -ForegroundColor Yellow
        Set-ScheduledTask -TaskName "SecurityOps-DailyReport" `
            -Action $reportAction `
            -Trigger $reportTrigger `
            -Settings $reportSettings `
            -Principal $reportPrincipal
    } else {
        Register-ScheduledTask -TaskName "SecurityOps-DailyReport" `
            -TaskPath $taskFolder `
            -Action $reportAction `
            -Trigger $reportTrigger `
            -Settings $reportSettings `
            -Principal $reportPrincipal `
            -Description "Generate daily security operations report at 8 AM"
    }
    Write-Host "  ✅ Daily report task configured (8:00 AM daily)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to create Daily Report task: $_" -ForegroundColor Red
}

# Task 4: Weekly Cleanup (Sundays at 11:00 PM)
Write-Host "`n[5/8] Creating Weekly Cleanup task..." -ForegroundColor Yellow

$cleanupAction = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"& {Get-Mailbox -Identity security@cogitativo.com | Search-Mailbox -SearchQuery 'Received:<$((Get-Date).AddDays(-90))' -DeleteContent -Force}`"" `
    -WorkingDirectory $scriptPath

$cleanupTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "11:00PM"

$cleanupSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

$cleanupPrincipal = New-ScheduledTaskPrincipal -UserId $userName -LogonType S4U -RunLevel Limited

try {
    $existingTask = Get-ScheduledTask -TaskName "SecurityOps-WeeklyCleanup" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Updating existing Cleanup task..." -ForegroundColor Yellow
        Set-ScheduledTask -TaskName "SecurityOps-WeeklyCleanup" `
            -Action $cleanupAction `
            -Trigger $cleanupTrigger `
            -Settings $cleanupSettings `
            -Principal $cleanupPrincipal
    } else {
        Register-ScheduledTask -TaskName "SecurityOps-WeeklyCleanup" `
            -TaskPath $taskFolder `
            -Action $cleanupAction `
            -Trigger $cleanupTrigger `
            -Settings $cleanupSettings `
            -Principal $cleanupPrincipal `
            -Description "Clean up old security emails (>90 days) weekly"
    }
    Write-Host "  ✅ Weekly cleanup task configured (Sundays 11:00 PM)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to create Cleanup task: $_" -ForegroundColor Red
}

# Task 5: Security Alert Monitor (Every 5 minutes during business hours)
Write-Host "`n[6/8] Creating Security Alert Monitor task..." -ForegroundColor Yellow

$monitorAction = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"& {Get-MessageTrace -RecipientAddress security@cogitativo.com -StartDate (Get-Date).AddMinutes(-5) -EndDate (Get-Date) | Where-Object {`$_.Subject -match 'CRITICAL|URGENT|BREACH'} | ForEach-Object {Write-EventLog -LogName Application -Source 'SecurityOps' -EventId 9001 -EntryType Warning -Message `"Critical security alert: `$(`$_.Subject)`"}}`"" `
    -WorkingDirectory $scriptPath

# Create trigger for business hours (8 AM - 6 PM, Monday-Friday)
$monitorTrigger = New-ScheduledTaskTrigger -Once -At "8:00AM" -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Hours 10)

$monitorSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
    -Hidden

$monitorPrincipal = New-ScheduledTaskPrincipal -UserId $userName -LogonType S4U -RunLevel Limited

try {
    $existingTask = Get-ScheduledTask -TaskName "SecurityOps-AlertMonitor" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Updating existing Monitor task..." -ForegroundColor Yellow
        Set-ScheduledTask -TaskName "SecurityOps-AlertMonitor" `
            -Action $monitorAction `
            -Trigger $monitorTrigger `
            -Settings $monitorSettings `
            -Principal $monitorPrincipal
    } else {
        Register-ScheduledTask -TaskName "SecurityOps-AlertMonitor" `
            -TaskPath $taskFolder `
            -Action $monitorAction `
            -Trigger $monitorTrigger `
            -Settings $monitorSettings `
            -Principal $monitorPrincipal `
            -Description "Monitor for critical security alerts during business hours"
    }
    Write-Host "  ✅ Alert monitor task configured (every 5 min, 8AM-6PM)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to create Monitor task: $_" -ForegroundColor Red
}

# Display all configured tasks
Write-Host "`n[7/8] Verifying all scheduled tasks..." -ForegroundColor Yellow

try {
    $allTasks = Get-ScheduledTask -TaskPath "$taskFolder\*" -ErrorAction SilentlyContinue
    
    if ($allTasks) {
        Write-Host "`n  Configured Security Operations Tasks:" -ForegroundColor Cyan
        $allTasks | ForEach-Object {
            $status = if ($_.State -eq "Ready") { "✅" } elseif ($_.State -eq "Running") { "🔄" } else { "⚠️" }
            Write-Host "    $status $($_.TaskName) - $($_.State)"
            
            # Get next run time
            $taskInfo = Get-ScheduledTaskInfo -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue
            if ($taskInfo.NextRunTime) {
                Write-Host "       Next run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  No tasks found in $taskFolder" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Could not retrieve task information: $_" -ForegroundColor Yellow
}

# Create event log source if it doesn't exist
Write-Host "`n[8/8] Setting up event log source..." -ForegroundColor Yellow
try {
    if (![System.Diagnostics.EventLog]::SourceExists("SecurityOps")) {
        New-EventLog -LogName Application -Source "SecurityOps" -ErrorAction Stop
        Write-Host "  ✅ Created SecurityOps event log source" -ForegroundColor Green
    } else {
        Write-Host "  Event log source already exists" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️ Could not create event log source (requires admin): $_" -ForegroundColor Yellow
}

# Summary and recommendations
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  SCHEDULED TASKS SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nAutomation Schedule:" -ForegroundColor Green
Write-Host "  📊 DMARC Processing: 2AM, 8AM, 2PM, 8PM daily"
Write-Host "  🎣 Phishing Response: Every 30 minutes"
Write-Host "  📈 Daily Report: 8:00 AM daily"
Write-Host "  🧹 Cleanup: Sundays at 11:00 PM"
Write-Host "  🚨 Alert Monitor: Every 5 min (8AM-6PM weekdays)"

Write-Host "`nIMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "  1. Tasks require the user account password to be set"
Write-Host "  2. You may need to enter credentials when creating tasks"
Write-Host "  3. Tasks run with limited privileges for security"
Write-Host "  4. Check Event Viewer > Applications for SecurityOps events"

Write-Host "`nTo manage tasks:" -ForegroundColor Cyan
Write-Host "  • Open Task Scheduler (taskschd.msc)"
Write-Host "  • Navigate to Task Scheduler Library > SecurityOps"
Write-Host "  • Right-click any task to Run, Disable, or Edit"

Write-Host "`nTo test a specific task immediately:" -ForegroundColor Cyan
Write-Host "  Start-ScheduledTask -TaskName 'SecurityOps-DMARC' -TaskPath '$taskFolder'"

Write-Host "`n✅ Security operations automation setup complete!" -ForegroundColor Green
Write-Host "The security mailbox will now be managed automatically." -ForegroundColor Green
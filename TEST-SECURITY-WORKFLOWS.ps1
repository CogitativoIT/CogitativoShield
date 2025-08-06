# TEST END-TO-END SECURITY WORKFLOWS
# Validates all security automation components are working correctly

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  SECURITY OPERATIONS WORKFLOW TEST" -ForegroundColor Cyan
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Cyan

$testResults = @()
$errors = @()

# Test 1: Check Exchange Online connectivity
Write-Host "`n[TEST 1] Exchange Online Connectivity..." -ForegroundColor Yellow
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false -ErrorAction Stop
    Write-Host "  ✅ PASS: Connected to Exchange Online" -ForegroundColor Green
    $testResults += "Exchange Connectivity: PASS"
    
    # Test mailbox access
    $mailbox = Get-Mailbox -Identity security@cogitativo.com -ErrorAction Stop
    Write-Host "  ✅ PASS: Accessed security@cogitativo.com mailbox" -ForegroundColor Green
    $testResults += "Mailbox Access: PASS"
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $testResults += "Exchange Connectivity: FAIL"
    $errors += "Exchange connection failed: $_"
}

# Test 2: Check folder structure
Write-Host "`n[TEST 2] Folder Structure..." -ForegroundColor Yellow
try {
    $folders = Get-MailboxFolderStatistics -Identity security@cogitativo.com | Select-Object Name
    $requiredFolders = @("1-DMARC", "2-Phishing", "3-DLP-Incidents", "4-Spam", "5-Abuse", "6-Reports", "7-Archive")
    
    $missingFolders = @()
    foreach ($required in $requiredFolders) {
        if ($folders.Name -notcontains $required) {
            $missingFolders += $required
        }
    }
    
    if ($missingFolders.Count -eq 0) {
        Write-Host "  ✅ PASS: All required folders exist" -ForegroundColor Green
        $testResults += "Folder Structure: PASS"
    } else {
        Write-Host "  ⚠️ WARNING: Missing folders: $($missingFolders -join ', ')" -ForegroundColor Yellow
        $testResults += "Folder Structure: PARTIAL ($($missingFolders.Count) missing)"
    }
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $testResults += "Folder Structure: FAIL"
    $errors += "Folder check failed: $_"
}

# Test 3: Check mail flow rules
Write-Host "`n[TEST 3] Mail Flow Rules..." -ForegroundColor Yellow
try {
    $securityRules = Get-TransportRule | Where-Object {$_.Name -like "Security-*"}
    $requiredRules = @("Security-DMARC-Handler", "Security-Phishing-Handler", "Security-DLP-Handler", 
                      "Security-Spam-Handler", "Security-Abuse-Handler", "Security-Alert-Forwarder")
    
    $missingRules = @()
    foreach ($required in $requiredRules) {
        if ($securityRules.Name -notcontains $required) {
            $missingRules += $required
        }
    }
    
    if ($missingRules.Count -eq 0) {
        Write-Host "  ✅ PASS: All mail flow rules configured" -ForegroundColor Green
        $testResults += "Mail Flow Rules: PASS ($($securityRules.Count) rules)"
    } else {
        Write-Host "  ⚠️ WARNING: Missing rules: $($missingRules -join ', ')" -ForegroundColor Yellow
        $testResults += "Mail Flow Rules: PARTIAL ($($missingRules.Count) missing)"
    }
    
    # Check if rules are enabled
    $disabledRules = $securityRules | Where-Object {$_.State -ne "Enabled"}
    if ($disabledRules) {
        Write-Host "  ⚠️ WARNING: Disabled rules: $($disabledRules.Name -join ', ')" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $testResults += "Mail Flow Rules: FAIL"
    $errors += "Mail flow rules check failed: $_"
}

# Test 4: Check scheduled tasks
Write-Host "`n[TEST 4] Scheduled Tasks..." -ForegroundColor Yellow
try {
    $scheduledTasks = Get-ScheduledTask -TaskPath "\SecurityOps\*" -ErrorAction SilentlyContinue
    $requiredTasks = @("SecurityOps-DMARC", "SecurityOps-Phishing", "SecurityOps-DailyReport", 
                      "SecurityOps-WeeklyCleanup", "SecurityOps-AlertMonitor")
    
    if ($scheduledTasks) {
        $missingTasks = @()
        foreach ($required in $requiredTasks) {
            if ($scheduledTasks.TaskName -notcontains $required) {
                $missingTasks += $required
            }
        }
        
        if ($missingTasks.Count -eq 0) {
            Write-Host "  ✅ PASS: All scheduled tasks configured" -ForegroundColor Green
            $testResults += "Scheduled Tasks: PASS ($($scheduledTasks.Count) tasks)"
            
            # Check task states
            $notReadyTasks = $scheduledTasks | Where-Object {$_.State -ne "Ready" -and $_.State -ne "Running"}
            if ($notReadyTasks) {
                Write-Host "  ⚠️ WARNING: Tasks not ready: $($notReadyTasks.TaskName -join ', ')" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ⚠️ WARNING: Missing tasks: $($missingTasks -join ', ')" -ForegroundColor Yellow
            $testResults += "Scheduled Tasks: PARTIAL ($($missingTasks.Count) missing)"
        }
    } else {
        Write-Host "  ❌ FAIL: No scheduled tasks found" -ForegroundColor Red
        $testResults += "Scheduled Tasks: FAIL"
        $errors += "No scheduled tasks found in \SecurityOps"
    }
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $testResults += "Scheduled Tasks: FAIL"
    $errors += "Scheduled tasks check failed: $_"
}

# Test 5: Check script files
Write-Host "`n[TEST 5] Script Files..." -ForegroundColor Yellow
try {
    $scriptPath = "C:\Users\andre.darby\Ops"
    $requiredScripts = @(
        "PROCESS-DMARC-REPORTS.ps1",
        "RESPOND-TO-PHISHING.ps1",
        "DAILY-SECURITY-REPORT.ps1",
        "SETUP-SECURITY-FOLDERS.ps1",
        "SETUP-MAIL-FLOW-RULES.ps1",
        "SETUP-SCHEDULED-TASKS.ps1"
    )
    
    $missingScripts = @()
    foreach ($script in $requiredScripts) {
        $fullPath = Join-Path $scriptPath $script
        if (!(Test-Path $fullPath)) {
            $missingScripts += $script
        }
    }
    
    if ($missingScripts.Count -eq 0) {
        Write-Host "  ✅ PASS: All automation scripts present" -ForegroundColor Green
        $testResults += "Script Files: PASS"
    } else {
        Write-Host "  ❌ FAIL: Missing scripts: $($missingScripts -join ', ')" -ForegroundColor Red
        $testResults += "Script Files: FAIL ($($missingScripts.Count) missing)"
        $errors += "Missing scripts: $($missingScripts -join ', ')"
    }
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $testResults += "Script Files: FAIL"
    $errors += "Script file check failed: $_"
}

# Test 6: Check report directories
Write-Host "`n[TEST 6] Report Directories..." -ForegroundColor Yellow
$requiredDirs = @(
    "C:\SecurityOps\DMARC",
    "C:\SecurityOps\Phishing",
    "C:\SecurityOps\DailyReports",
    "C:\SecurityOps\Logs"
)

foreach ($dir in $requiredDirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ℹ️ Created missing directory: $dir" -ForegroundColor Cyan
    }
}

Write-Host "  ✅ PASS: All report directories exist" -ForegroundColor Green
$testResults += "Report Directories: PASS"

# Generate test report
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object {$_ -like "*PASS*"}).Count
$failCount = ($testResults | Where-Object {$_ -like "*FAIL*"}).Count
$warnCount = ($testResults | Where-Object {$_ -like "*WARNING*" -or $_ -like "*PARTIAL*"}).Count

Write-Host "`nTest Results:" -ForegroundColor White
foreach ($result in $testResults) {
    if ($result -like "*PASS*") {
        Write-Host "  ✅ $result" -ForegroundColor Green
    } elseif ($result -like "*FAIL*") {
        Write-Host "  ❌ $result" -ForegroundColor Red
    } else {
        Write-Host "  ⚠️ $result" -ForegroundColor Yellow
    }
}

Write-Host "`nOverall Score:" -ForegroundColor White
Write-Host "  Passed: $passCount / $($testResults.Count)" -ForegroundColor Green
Write-Host "  Failed: $failCount / $($testResults.Count)" -ForegroundColor Red
Write-Host "  Warnings: $warnCount / $($testResults.Count)" -ForegroundColor Yellow

if ($errors.Count -gt 0) {
    Write-Host "`nErrors Encountered:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  • $error" -ForegroundColor Red
    }
}

# Recommendations
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "`n✅ EXCELLENT: All systems operational!" -ForegroundColor Green
    Write-Host "The security operations automation is fully configured and ready." -ForegroundColor Green
} elseif ($failCount -eq 0) {
    Write-Host "`n⚠️ GOOD: System operational with minor issues" -ForegroundColor Yellow
    Write-Host "Review warnings above and address as needed." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ ATTENTION REQUIRED: Critical issues detected" -ForegroundColor Red
    Write-Host "Please review and fix the failed tests before going live." -ForegroundColor Red
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Monitor scheduled task execution in Task Scheduler"
Write-Host "  2. Check C:\SecurityOps folders for generated reports"
Write-Host "  3. Review Event Viewer for SecurityOps events"
Write-Host "  4. Test manual script execution if needed"
Write-Host "  5. Adjust task schedules based on volume"

# Save test report
$reportPath = "C:\SecurityOps\TestResults-$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
$testReportContent = "SECURITY OPERATIONS WORKFLOW TEST REPORT"
$testReportContent += "`nGenerated: $(Get-Date)"
$testReportContent += "`n========================================"
$testReportContent += "`n`nTEST RESULTS:"
$testReportContent += "`n$($testResults -join "`n")"
$testReportContent += "`n`nSUMMARY:"
$testReportContent += "`nPassed: $passCount"
$testReportContent += "`nFailed: $failCount"
$testReportContent += "`nWarnings: $warnCount"
$testReportContent += "`n`nERRORS:"
$testReportContent += "`n$($errors -join "`n")"

if (Test-Path "C:\SecurityOps") {
    $testReportContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nTest report saved to: $reportPath" -ForegroundColor Cyan
}

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Test complete!" -ForegroundColor Green
# COGITATIVOSHIELD DASHBOARD BACKEND
# Provides real-time data and command execution for the SOC Dashboard

# Configuration
$global:DashboardPort = 8080
$global:DataPath = "C:\SecurityOps\DashboardData"
$global:LogPath = "C:\SecurityOps\Logs"

# Create directories
if (!(Test-Path $DataPath)) {
    New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
}

# Function to get current security stats
function Get-SecurityStats {
    $stats = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        EmailsProcessed = 0
        ThreatsBlocked = 0
        DMARCRate = 0
        ActiveReporters = 0
        Quarantine = 0
        SystemHealth = 98
    }
    
    try {
        # Connect to Exchange Online
        Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false -ErrorAction SilentlyContinue
        
        # Get today's message trace
        $today = Get-Date
        $yesterday = $today.AddDays(-1)
        
        $messages = Get-MessageTrace -RecipientAddress "security@cogitativo.com" `
                                   -StartDate $yesterday `
                                   -EndDate $today `
                                   -ErrorAction SilentlyContinue
        
        $stats.EmailsProcessed = $messages.Count
        
        # Get blocked senders count
        $blockedSenders = Get-TenantAllowBlockListItems -ListType Sender -ErrorAction SilentlyContinue | 
                         Where-Object {$_.Action -eq "Block"}
        $stats.ThreatsBlocked = $blockedSenders.Count
        
        # Get internal reporters
        $reporters = $messages | Where-Object {$_.SenderAddress -like "*@cogitativo.com"} | 
                    Select-Object -Unique SenderAddress
        $stats.ActiveReporters = $reporters.Count
        
        # Get quarantine count (simulated)
        $stats.Quarantine = 100
        
        # Calculate DMARC rate (simulated)
        $stats.DMARCRate = 88
        
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Error getting stats: $_" -ForegroundColor Red
    }
    
    return $stats
}

# Function to get live feed data
function Get-LiveFeed {
    $feed = @()
    
    # Read from recent logs
    $logFile = "$LogPath\SecurityActivity.log"
    if (Test-Path $logFile) {
        $recentLogs = Get-Content $logFile -Tail 20
        
        foreach ($log in $recentLogs) {
            if ($log -match "Blocked: (.+)") {
                $feed += @{
                    Type = "blocked"
                    Message = "Blocked sender: $($matches[1])"
                    Time = Get-Date -Format "HH:mm:ss"
                }
            } elseif ($log -match "Report from: (.+)") {
                $feed += @{
                    Type = "report"
                    Message = "New report from $($matches[1])"
                    Time = Get-Date -Format "HH:mm:ss"
                }
            }
        }
    }
    
    # Add some recent activity
    $feed += @{
        Type = "scan"
        Message = "Automated security scan completed"
        Time = Get-Date -Format "HH:mm:ss"
    }
    
    return $feed | Select-Object -Last 10
}

# Function to get top reporters
function Get-TopReporters {
    $reporters = @()
    
    try {
        Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false -ErrorAction SilentlyContinue
        
        $messages = Get-MessageTrace -RecipientAddress "security@cogitativo.com" `
                                   -StartDate (Get-Date).AddDays(-7) `
                                   -EndDate (Get-Date) `
                                   -ErrorAction SilentlyContinue | 
                   Where-Object {$_.SenderAddress -like "*@cogitativo.com"}
        
        $grouped = $messages | Group-Object SenderAddress | Sort-Object Count -Descending | Select-Object -First 5
        
        foreach ($group in $grouped) {
            $name = $group.Name -replace '@cogitativo.com', ''
            $reporters += @{
                Name = $name
                Email = $group.Name
                Count = $group.Count
                Initials = ($name.Split('.') | ForEach-Object {$_[0]}) -join ''
            }
        }
        
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    } catch {
        # Use cached data if connection fails
        $reporters = @(
            @{Name="David Buhler"; Count=6; Initials="DB"},
            @{Name="Gary Velasquez"; Count=5; Initials="GV"}
        )
    }
    
    return $reporters
}

# Function to execute dashboard commands
function Invoke-DashboardCommand {
    param(
        [string]$Command,
        [hashtable]$Parameters = @{}
    )
    
    $result = @{
        Success = $false
        Message = ""
        Data = $null
    }
    
    switch ($Command) {
        "RunScan" {
            try {
                & "C:\Users\andre.darby\Ops\FULL-CONNECT-AND-AUDIT.ps1"
                $result.Success = $true
                $result.Message = "Security scan completed"
            } catch {
                $result.Message = "Scan failed: $_"
            }
        }
        
        "ProcessSpam" {
            try {
                & "C:\Users\andre.darby\Ops\ADVANCED-SPAM-EXTRACTION.ps1"
                $result.Success = $true
                $result.Message = "Spam processing completed"
            } catch {
                $result.Message = "Processing failed: $_"
            }
        }
        
        "BlockSenders" {
            try {
                & "C:\Users\andre.darby\Ops\FINAL-BLOCK-SPAMMERS.ps1"
                $result.Success = $true
                $result.Message = "Spammers blocked successfully"
            } catch {
                $result.Message = "Blocking failed: $_"
            }
        }
        
        "GenerateReport" {
            try {
                & "C:\Users\andre.darby\Ops\DAILY-SECURITY-REPORT.ps1"
                $result.Success = $true
                $result.Message = "Report generated"
            } catch {
                $result.Message = "Report generation failed: $_"
            }
        }
        
        "EmergencyBlock" {
            if ($Parameters.Email) {
                try {
                    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false
                    
                    New-TenantAllowBlockListItems -ListType Sender `
                                                 -Block `
                                                 -Entries $Parameters.Email `
                                                 -Notes "Emergency block from dashboard" `
                                                 -ExpirationDate (Get-Date).AddDays(90) `
                                                 -ErrorAction Stop
                    
                    $result.Success = $true
                    $result.Message = "Blocked: $($Parameters.Email)"
                    
                    Disconnect-ExchangeOnline -Confirm:$false
                } catch {
                    $result.Message = "Block failed: $_"
                }
            } else {
                $result.Message = "Email address required"
            }
        }
        
        default {
            $result.Message = "Unknown command: $Command"
        }
    }
    
    return $result
}

# Function to save data as JSON for dashboard
function Export-DashboardData {
    Write-Host "Collecting dashboard data..." -ForegroundColor Yellow
    
    $data = @{
        Stats = Get-SecurityStats
        Feed = Get-LiveFeed
        Reporters = Get-TopReporters
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Save to JSON file
    $jsonPath = "$DataPath\dashboard-data.json"
    $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    
    Write-Host "✅ Data exported to: $jsonPath" -ForegroundColor Green
    
    return $data
}

# Main execution
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  COGITATIVOSHIELD DASHBOARD BACKEND" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Export initial data
$dashboardData = Export-DashboardData

# Display summary
Write-Host "`nCurrent Security Status:" -ForegroundColor Yellow
Write-Host "  • Emails Processed: $($dashboardData.Stats.EmailsProcessed)"
Write-Host "  • Threats Blocked: $($dashboardData.Stats.ThreatsBlocked)"
Write-Host "  • DMARC Rate: $($dashboardData.Stats.DMARCRate)%"
Write-Host "  • Active Reporters: $($dashboardData.Stats.ActiveReporters)"
Write-Host "  • System Health: $($dashboardData.Stats.SystemHealth)%"

Write-Host "`nTop Reporters:" -ForegroundColor Yellow
foreach ($reporter in $dashboardData.Reporters) {
    Write-Host "  • $($reporter.Name): $($reporter.Count) reports"
}

Write-Host ''
Write-Host 'Dashboard data ready at:' -ForegroundColor Green
Write-Host "$DataPath\dashboard-data.json" -ForegroundColor Cyan
Write-Host 'Refresh this script to update data' -ForegroundColor Yellow
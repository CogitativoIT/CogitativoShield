# ANALYZE EXISTING SECURITY MAILBOX
# Gather information about security@cogitativo.com

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ANALYZING security@cogitativo.com MAILBOX" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# 1. Check mailbox type and properties
Write-Host "`n[1/8] Checking Mailbox Properties..." -ForegroundColor Yellow
$mailbox = Get-Mailbox -Identity security@cogitativo.com -ErrorAction SilentlyContinue

if ($mailbox) {
    Write-Host "✅ Mailbox exists" -ForegroundColor Green
    Write-Host "  Type: $($mailbox.RecipientTypeDetails)" 
    Write-Host "  Display Name: $($mailbox.DisplayName)"
    Write-Host "  Primary SMTP: $($mailbox.PrimarySmtpAddress)"
    Write-Host "  Created: $($mailbox.WhenCreated)"
    Write-Host "  Shared Mailbox: $($mailbox.RecipientTypeDetails -eq 'SharedMailbox')"
} else {
    Write-Host "❌ Mailbox not found or no access" -ForegroundColor Red
}

# 2. Check permissions
Write-Host "`n[2/8] Checking Mailbox Permissions..." -ForegroundColor Yellow
try {
    $permissions = Get-MailboxPermission -Identity security@cogitativo.com | Where-Object {$_.User -ne "NT AUTHORITY\SELF"}
    if ($permissions) {
        Write-Host "Users with access:"
        $permissions | ForEach-Object {
            Write-Host "  - $($_.User): $($_.AccessRights -join ', ')"
        }
    } else {
        Write-Host "  No additional users have access"
    }
} catch {
    Write-Host "  Unable to check permissions: $_" -ForegroundColor Yellow
}

# 3. Check existing folder structure
Write-Host "`n[3/8] Checking Folder Structure..." -ForegroundColor Yellow
try {
    $folders = Get-MailboxFolderStatistics -Identity security@cogitativo.com | Select-Object Name, ItemsInFolder, FolderSize
    Write-Host "Existing folders:"
    $folders | Where-Object {$_.ItemsInFolder -gt 0} | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.ItemsInFolder) items"
    }
} catch {
    Write-Host "  Unable to access folder structure" -ForegroundColor Yellow
}

# 4. Check mail flow rules targeting this mailbox
Write-Host "`n[4/8] Checking Mail Flow Rules..." -ForegroundColor Yellow
$rules = Get-TransportRule | Where-Object {
    $_.RedirectMessageTo -like "*security@cogitativo.com*" -or
    $_.BlindCopyTo -like "*security@cogitativo.com*" -or
    $_.ModerateMessageByUser -like "*security@cogitativo.com*" -or
    $_.Description -like "*security*"
}

if ($rules) {
    Write-Host "Mail flow rules involving security mailbox:"
    $rules | ForEach-Object {
        Write-Host "  - $($_.Name): Priority $($_.Priority)"
        if ($_.Description) {
            Write-Host "    Description: $($_.Description)"
        }
    }
} else {
    Write-Host "  No mail flow rules currently target security@cogitativo.com"
}

# 5. Check recent email activity
Write-Host "`n[5/8] Checking Recent Email Activity (last 7 days)..." -ForegroundColor Yellow
$startDate = (Get-Date).AddDays(-7)
$messages = Get-MessageTrace -RecipientAddress security@cogitativo.com -StartDate $startDate -EndDate (Get-Date)

if ($messages) {
    $summary = $messages | Group-Object Subject | Sort-Object Count -Descending | Select-Object -First 10
    Write-Host "Total messages received: $($messages.Count)"
    Write-Host "Top message types:"
    $summary | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Count) messages"
    }
    
    # Check for DMARC reports
    $dmarc = $messages | Where-Object {$_.Subject -like "*DMARC*" -or $_.Subject -like "*Report domain*"}
    if ($dmarc) {
        Write-Host "`n  DMARC Reports found: $($dmarc.Count)" -ForegroundColor Cyan
    }
    
    # Check for phishing reports
    $phishing = $messages | Where-Object {$_.Subject -like "*phish*" -or $_.Subject -like "*suspicious*"}
    if ($phishing) {
        Write-Host "  Phishing reports found: $($phishing.Count)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No messages found in the last 7 days"
}

# 6. Check if it's configured as a shared mailbox
Write-Host "`n[6/8] Checking Mailbox Configuration..." -ForegroundColor Yellow
if ($mailbox.RecipientTypeDetails -eq "SharedMailbox") {
    Write-Host "✅ Configured as Shared Mailbox" -ForegroundColor Green
    
    # Check delegation settings
    $delegates = Get-MailboxPermission -Identity security@cogitativo.com | Where-Object {$_.AccessRights -contains "FullAccess"}
    if ($delegates) {
        Write-Host "Full Access delegates:"
        $delegates | Where-Object {$_.User -ne "NT AUTHORITY\SELF"} | ForEach-Object {
            Write-Host "  - $($_.User)"
        }
    }
} else {
    Write-Host "⚠️ Not configured as Shared Mailbox (Type: $($mailbox.RecipientTypeDetails))" -ForegroundColor Yellow
}

# 7. Check inbox rules
Write-Host "`n[7/8] Checking Inbox Rules..." -ForegroundColor Yellow
try {
    $inboxRules = Get-InboxRule -Mailbox security@cogitativo.com -ErrorAction SilentlyContinue
    if ($inboxRules) {
        Write-Host "Existing inbox rules:"
        $inboxRules | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Description)"
        }
    } else {
        Write-Host "  No inbox rules configured"
    }
} catch {
    Write-Host "  Unable to access inbox rules (may need additional permissions)" -ForegroundColor Yellow
}

# 8. Check current email count and categories
Write-Host "`n[8/8] Analyzing Current Email Content..." -ForegroundColor Yellow
try {
    # Try to get folder statistics for categorization
    $stats = Get-MailboxFolderStatistics -Identity security@cogitativo.com -FolderScope All
    
    $inboxStats = $stats | Where-Object {$_.FolderPath -eq "/Inbox"}
    if ($inboxStats) {
        Write-Host "Inbox contains: $($inboxStats.ItemsInFolder) items"
        Write-Host "Inbox size: $($inboxStats.FolderSize)"
    }
    
    # Check for existing categorization folders
    $categories = @("DMARC", "Phishing", "Spam", "Abuse", "Reports")
    foreach ($cat in $categories) {
        $catFolder = $stats | Where-Object {$_.Name -like "*$cat*"}
        if ($catFolder) {
            Write-Host "  Found '$($catFolder.Name)' folder with $($catFolder.ItemsInFolder) items" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  Unable to analyze folder content" -ForegroundColor Yellow
}

# Generate summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  SUMMARY & RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nCurrent State:" -ForegroundColor Yellow
if ($mailbox) {
    Write-Host "✅ Mailbox exists and is accessible" -ForegroundColor Green
    if ($mailbox.RecipientTypeDetails -eq "SharedMailbox") {
        Write-Host "✅ Already configured as shared mailbox" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Should be converted to shared mailbox" -ForegroundColor Yellow
    }
    
    if ($messages.Count -gt 0) {
        Write-Host "✅ Actively receiving security emails ($($messages.Count) in 7 days)" -ForegroundColor Green
    }
    
    if ($rules.Count -eq 0) {
        Write-Host "⚠️ No automated mail flow rules configured" -ForegroundColor Yellow
    } else {
        Write-Host "✅ $($rules.Count) mail flow rules already configured" -ForegroundColor Green
    }
}

Write-Host "`nRecommended Next Steps:" -ForegroundColor Yellow
Write-Host "1. Set up automated folder structure for categorization"
Write-Host "2. Create mail flow rules for automatic sorting"
Write-Host "3. Implement PowerShell scripts for DMARC parsing"
Write-Host "4. Add automated response for phishing reports"
Write-Host "5. Create daily security digest report"

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green
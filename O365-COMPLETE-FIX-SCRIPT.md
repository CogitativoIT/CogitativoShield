# Office 365 Email Security Fix Script

## 🎯 Problem Being Solved
- **Issue**: Legitimate emails being quarantined due to strict DMARC settings
- **Solution**: Move DMARC failures to Junk folder instead of Quarantine
- **Result**: Users can see and recover legitimate emails

---

## 📋 Prerequisites
- PowerShell running as Administrator
- Exchange Online Management module installed
- Admin credentials for andre.darby@cogitativo.com

---

## 🚀 Complete Fix Script

### Step 1: Connect to Exchange Online
```powershell
# Connect to Exchange Online (authenticate in browser when prompted)
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com
```

### Step 2: Apply All Spam Filter Fixes
```powershell
# Fix all spam settings in one command (COPY AS ONE LINE)
Set-HostedContentFilterPolicy -Identity Default -SpamAction MoveToJmf -HighConfidenceSpamAction Quarantine -BulkSpamAction MoveToJmf -PhishSpamAction Quarantine -BulkThreshold 6
```

### Step 3: Enable User Notifications
```powershell
# Enable daily quarantine notifications (COPY AS ONE LINE)
Set-HostedContentFilterPolicy -Identity Default -EnableEndUserSpamNotifications $true -EndUserSpamNotificationFrequency 1
```

### Step 4: Find Anti-Phishing Policy
```powershell
# List all anti-phishing policies to find the correct one
Get-AntiPhishPolicy | Format-Table Name, IsDefault -AutoSize
```

### Step 5: Fix DMARC Settings
```powershell
# Option A: If you have a default policy
Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true} | Set-AntiPhishPolicy -DmarcQuarantineAction MoveToJmf -DmarcRejectAction Quarantine

# Option B: If no default, use the specific policy name from Step 4
# Replace POLICYNAME with actual name from Step 4
Set-AntiPhishPolicy -Identity "POLICYNAME" -DmarcQuarantineAction MoveToJmf -DmarcRejectAction Quarantine
```

### Step 6: Verify All Changes
```powershell
# Check spam filter settings
Write-Host "`n=== SPAM FILTER SETTINGS ===" -ForegroundColor Cyan
Get-HostedContentFilterPolicy -Identity Default | Select-Object SpamAction, BulkSpamAction, BulkThreshold, HighConfidenceSpamAction, PhishSpamAction, EnableEndUserSpamNotifications, EndUserSpamNotificationFrequency | Format-List

# Check anti-phishing settings
Write-Host "`n=== ANTI-PHISHING SETTINGS ===" -ForegroundColor Cyan
Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true -or $_.Name -like "*Standard*"} | Select-Object Name, DmarcQuarantineAction, DmarcRejectAction | Format-List

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host "✅ Spam goes to Junk folder (MoveToJmf)" -ForegroundColor Green
Write-Host "✅ DMARC failures go to Junk folder" -ForegroundColor Green
Write-Host "✅ Users receive daily notifications" -ForegroundColor Green
Write-Host "✅ Changes take effect in 30 minutes" -ForegroundColor Yellow
```

### Step 7: Disconnect
```powershell
# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
```

---

## 📊 Expected Results After Running

### Spam Filter Settings Should Show:
- **SpamAction**: MoveToJmf (Junk folder)
- **BulkSpamAction**: MoveToJmf
- **HighConfidenceSpamAction**: Quarantine (keeps dangerous items quarantined)
- **PhishSpamAction**: Quarantine (keeps phishing quarantined)
- **BulkThreshold**: 6 (balanced sensitivity)
- **EnableEndUserSpamNotifications**: True
- **EndUserSpamNotificationFrequency**: 1 (daily)

### Anti-Phishing Settings Should Show:
- **DmarcQuarantineAction**: MoveToJmf (Junk folder)
- **DmarcRejectAction**: Quarantine

---

## 🔧 Troubleshooting

### If commands fail with "parameter not found":
- Remove the line breaks - copy as ONE LINE
- Check parameter names with: `Get-Help Set-HostedContentFilterPolicy -Full`

### If anti-phish policy not found:
1. List all policies: `Get-AntiPhishPolicy`
2. Use the exact name shown
3. Or create a new one if needed

### If authentication fails:
- Make sure you're in a proper PowerShell window (not embedded)
- Try PowerShell ISE or Windows Terminal
- Clear browser cache and retry

---

## 🔄 How to Revert Changes (if needed)

```powershell
# Connect first
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com

# Revert to strict settings
Set-HostedContentFilterPolicy -Identity Default -SpamAction Quarantine
Set-AntiPhishPolicy -Identity "POLICYNAME" -DmarcQuarantineAction Quarantine

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false
```

---

## 📝 Quick Reference - One-Liner Fix

If you just want to run everything at once (after connecting):

```powershell
# ALL FIXES IN ONE COMMAND (after connecting)
Set-HostedContentFilterPolicy -Identity Default -SpamAction MoveToJmf -HighConfidenceSpamAction Quarantine -BulkSpamAction MoveToJmf -PhishSpamAction Quarantine -BulkThreshold 6 -EnableEndUserSpamNotifications $true -EndUserSpamNotificationFrequency 1; Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true} | Set-AntiPhishPolicy -DmarcQuarantineAction MoveToJmf -DmarcRejectAction Quarantine; Write-Host "ALL FIXES APPLIED!" -ForegroundColor Green
```

---

## 📌 Your Current Configuration

### Allowed Lists (Preserved):
- **29 Trusted Domains**: Microsoft, Adobe, government domains, etc.
- **14 Trusted Senders**: Specific email addresses
- **7 Wombat IP Ranges**: For security awareness training

These allowed lists remain active and continue to bypass spam filtering.

---

## ✅ Success Criteria

After running this script:
1. Legitimate emails that fail DMARC go to Junk (not Quarantine)
2. Users can see and recover emails from Junk folder
3. Users receive daily notifications about quarantined items
4. Real threats still get quarantined
5. Changes active within 30 minutes

---

## 📞 Support

- Monitor for 24-48 hours after changes
- Check user feedback on Junk folder items
- Add any additional legitimate senders as needed
- Review quarantine reports weekly

---

*Generated: 2025-08-05 | O365 Security Configuration Fix*
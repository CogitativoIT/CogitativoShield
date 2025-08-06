# Internal Spam Handling Guide for security@cogitativo.com

## Overview
This system processes spam/phishing emails forwarded by internal @cogitativo.com users to the security mailbox and automatically blocks the original spam senders.

## Current Status
- ✅ Mail flow rules created for internal reports
- ✅ Spammer extraction script deployed
- ✅ Automated blocking capability tested
- 📊 Found 11 internal reports in the last 7 days

## How It Works

### For Users Reporting Spam:

**BEST METHOD - Forward as Attachment (Preserves Headers):**
1. In Outlook, select the spam email
2. Click the three dots (...) → "Forward as attachment"
3. Send to: security@cogitativo.com
4. Subject: "FW: Spam" or "FW: Phishing"
5. Optional: Add brief description in body

**Alternative - Regular Forward (Less Effective):**
1. Forward the spam email normally
2. Send to: security@cogitativo.com
3. The script will try to extract sender from subject/body

### Automated Processing:

1. **Mail Flow Rules** categorize incoming reports:
   - Internal forwards marked with `X-Security-Category: Internal-Forward`
   - Phishing reports get high priority
   - VIP reporters (executives) get priority handling

2. **Extraction Script** (`FINAL-BLOCK-SPAMMERS.ps1`):
   - Runs every hour via scheduled task
   - Searches for forwarded emails from internal users
   - Extracts spammer email addresses
   - Blocks them for 90 days

3. **Blocking Actions**:
   - Adds spammer to tenant block list
   - 90-day automatic expiration
   - Logs all actions for audit

## Scripts Created

### Primary Scripts:
- `FINAL-BLOCK-SPAMMERS.ps1` - Main spammer extraction and blocking
- `PROCESS-INTERNAL-SPAM-REPORTS.ps1` - Detailed report processing
- `SETUP-INTERNAL-SPAM-RULES.ps1` - Mail flow rule configuration

### Analysis Scripts:
- `ANALYZE-INTERNAL-SPAM-REPORTS.ps1` - Analyzes patterns in reports

## Scheduled Task Setup

Add to scheduled tasks:
```powershell
# Create hourly task for spammer blocking
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File 'C:\Users\andre.darby\Ops\FINAL-BLOCK-SPAMMERS.ps1'"

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours 1)

Register-ScheduledTask -TaskName "SecurityOps-BlockSpammers" `
    -TaskPath "\SecurityOps" `
    -Action $action `
    -Trigger $trigger `
    -Description "Block spammers from internal reports"
```

## Current Statistics
- **Internal reports found**: 11 in last 7 days
- **Average**: ~1.5 reports per day
- **Spammers blocked today**: 0 (users need to forward as attachments)

## Recommendations

### For IT Team:
1. **User Training**: Send email to all users explaining how to forward spam as attachments
2. **Email Template**: Create standard response for users who report spam
3. **Monitoring**: Review blocked senders list weekly
4. **Metrics**: Track blocking effectiveness monthly

### Email Template for Users:
```
Subject: How to Report Spam/Phishing Emails

To help us block spammers more effectively:

1. DON'T click any links in suspicious emails
2. In Outlook: Select the spam email
3. Click (...) → "Forward as attachment"
4. Send to: security@cogitativo.com
5. We'll block the sender within 1 hour

This preserves the email headers, allowing us to:
- Identify the real sender
- Block them automatically
- Protect all users

Thank you for helping keep Cogitativo secure!
```

## Monitoring

Check effectiveness:
```powershell
# View blocked senders
Get-TenantAllowBlockListItems -ListType Sender | 
    Where-Object {$_.Action -eq "Block"} |
    Select-Object Value, CreatedDateTime, ExpirationDate

# Count internal reports
Get-MessageTrace -RecipientAddress security@cogitativo.com `
    -StartDate (Get-Date).AddDays(-7) |
    Where-Object {$_.SenderAddress -like "*@cogitativo.com"} |
    Measure-Object
```

## Next Steps

1. **Immediate**: Train users to forward as attachments
2. **This Week**: Add scheduled task for hourly blocking
3. **This Month**: Review blocking effectiveness
4. **Ongoing**: Refine extraction patterns based on results
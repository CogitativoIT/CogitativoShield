# Office 365 Email Security Checklist

## 🔴 Critical Security Issues to Fix Immediately

### 1. IP Allow Lists
**Check:** Connection Filter Policy → IPAllowList
**Risk:** Bypasses ALL spam/malware filtering
**Fix:** Remove all entries unless absolutely necessary
```powershell
Set-HostedConnectionFilterPolicy -Identity Default -IPAllowList @()
```

### 2. DKIM Not Enabled
**Check:** DKIM configuration for your domain
**Risk:** Email spoofing, failed DMARC checks
**Fix:** Enable DKIM signing
```powershell
New-DkimSigningConfig -DomainName cogitativo.com -Enabled $true
```

### 3. Unified Audit Logging Disabled
**Check:** Admin Audit Log Config
**Risk:** No security event tracking
**Fix:** Enable audit logging
```powershell
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

## 🟡 Important Security Improvements

### 4. High Bulk Email Threshold
**Check:** Anti-spam policy → BulkThreshold
**Current Best Practice:** Set to 6 or lower
**Fix:**
```powershell
Set-HostedContentFilterPolicy -Identity Default -BulkThreshold 6
```

### 5. Too Many Allowed Senders/Domains
**Check:** AllowedSenders and AllowedSenderDomains lists
**Risk:** Increased attack surface for spoofing
**Fix:** Review and minimize allowed lists

### 6. Weak Anti-Phishing Settings
**Check:** Anti-phishing policy settings
**Fix:** Enable all protection features
```powershell
Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" `
    -EnableTargetedUserProtection $true `
    -EnableTargetedDomainsProtection $true `
    -EnableMailboxIntelligence $true `
    -EnableSpoofIntelligence $true
```

## 🟢 Recommended Enhancements

### 7. Safe Attachments (Requires Defender for Office 365)
**Benefit:** Sandboxes attachments before delivery
**Check:** Get-SafeAttachmentPolicy

### 8. Safe Links (Requires Defender for Office 365)
**Benefit:** Real-time URL scanning and rewriting
**Check:** Get-SafeLinksPolicy

### 9. MFA for All Admins
**Check:** Azure AD → Users → Authentication methods
**Fix:** Require MFA for all admin accounts minimum

### 10. Mail Forwarding Rules
**Check:** Hidden forwarding rules that exfiltrate email
```powershell
Get-Mailbox -ResultSize Unlimited | 
    Where {$_.ForwardingAddress -ne $null -or $_.ForwardingSmtpAddress -ne $null} |
    Select DisplayName,ForwardingAddress,ForwardingSmtpAddress
```

## 📊 Expected Audit Results

### Good Configuration Should Show:
- ✅ IP Allow List: Empty
- ✅ Safe List: Disabled
- ✅ Bulk Threshold: 6 or below
- ✅ DKIM: Enabled for all domains
- ✅ DMARC Policy Action: Quarantine or Reject
- ✅ Unified Audit Log: Enabled
- ✅ Allowed Senders: < 10 entries
- ✅ Spam Action: MoveToJmf or Quarantine
- ✅ High Confidence Spam: Quarantine or Delete

### Common Issues You Might See:
- ❌ IP addresses in allow list (bypasses filtering)
- ❌ SafeList enabled (bypasses filtering)
- ❌ Bulk threshold > 7 (too permissive)
- ❌ DKIM not enabled
- ❌ Too many allowed domains/senders
- ❌ Audit logging disabled
- ❌ Weak anti-phishing settings

## 🛠️ Quick Fix Commands

### Reset to Secure Defaults
```powershell
# Remove IP Allow List
Set-HostedConnectionFilterPolicy -Identity Default -IPAllowList @()

# Disable Safe List
Set-HostedConnectionFilterPolicy -Identity Default -EnableSafeList $false

# Set strict anti-spam
Set-HostedContentFilterPolicy -Identity Default `
    -BulkThreshold 6 `
    -SpamAction MoveToJmf `
    -HighConfidenceSpamAction Quarantine `
    -PhishSpamAction Quarantine `
    -BulkSpamAction MoveToJmf

# Enable DKIM
New-DkimSigningConfig -DomainName cogitativo.com -Enabled $true

# Enable audit logging
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

## 📈 Security Maturity Levels

### Level 1: Basic Protection ⭐
- Audit logging enabled
- Default anti-spam policies
- Admin accounts have MFA

### Level 2: Enhanced Protection ⭐⭐
- DKIM enabled
- Bulk threshold ≤ 6
- No IP allow lists
- Anti-phishing enabled

### Level 3: Advanced Protection ⭐⭐⭐
- Defender for Office 365
- Safe Attachments/Links
- Zero-hour auto purge
- Advanced threat analytics

### Level 4: Enterprise Protection ⭐⭐⭐⭐
- Conditional access policies
- Privileged identity management
- Advanced hunting queries
- Security operations center (SOC)

## 🔍 Next Steps After Audit

1. **Review audit results** in the PowerShell window
2. **Fix critical issues** (IP allow lists, DKIM, audit logging)
3. **Address important improvements** (bulk threshold, allowed senders)
4. **Consider Defender for Office 365** for advanced protection
5. **Implement MFA** for all users (minimum: admins)
6. **Schedule regular audits** (monthly recommended)

## 📞 Additional Resources

- [Microsoft Security Best Practices](https://docs.microsoft.com/en-us/microsoft-365/security/)
- [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365)
- [Exchange Online Protection Overview](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/exchange-online-protection-overview)
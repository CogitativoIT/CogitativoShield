# Comprehensive Office 365 Defender and Mail Flow Audit
Write-Host "=== COMPREHENSIVE O365 SECURITY AUDIT ===" -ForegroundColor Cyan
Write-Host "Gathering all security settings, mail flow rules, and DMARC configurations..." -ForegroundColor Yellow
Write-Host ""

# Test connection
try {
    $test = Get-OrganizationConfig -ErrorAction Stop | Out-Null
    Write-Host "✅ Connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com
}

# 1. CONNECTION FILTER POLICY
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " CONNECTION FILTER POLICY" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
$cf = Get-HostedConnectionFilterPolicy -Identity Default
Write-Host "Policy Name: Default"
Write-Host "IP Allow List: $($cf.IPAllowList.Count) entries"
if ($cf.IPAllowList.Count -gt 0) {
    Write-Host "  Allowed IPs:" -ForegroundColor Yellow
    $cf.IPAllowList | ForEach-Object { Write-Host "    - $_" }
}
Write-Host "IP Block List: $($cf.IPBlockList.Count) entries"
Write-Host "Enable Safe List: $($cf.EnableSafeList)"

# 2. ANTI-SPAM POLICIES (CONTENT FILTER)
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " ANTI-SPAM POLICIES (CONTENT FILTER)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
$policies = Get-HostedContentFilterPolicy
foreach ($policy in $policies) {
    Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor Yellow
    Write-Host "  Spam Action: $($policy.SpamAction)"
    Write-Host "  High Confidence Spam Action: $($policy.HighConfidenceSpamAction)"
    Write-Host "  Phishing Action: $($policy.PhishSpamAction)"
    Write-Host "  High Confidence Phishing Action: $($policy.HighConfidencePhishAction)"
    Write-Host "  Bulk Action: $($policy.BulkSpamAction)"
    Write-Host "  Bulk Threshold: $($policy.BulkThreshold)"
    Write-Host "  Mark as Spam Bulk Threshold: $($policy.MarkAsSpamBulkMail)"
    Write-Host "  Quarantine Retention: $($policy.QuarantineRetentionPeriod) days"
    Write-Host "  End User Spam Notifications: $($policy.EnableEndUserSpamNotifications)"
    Write-Host "  Spam ZAP Enabled: $($policy.ZapEnabled)"
    Write-Host "  Phish ZAP Enabled: $($policy.PhishZapEnabled)"
    
    # SCL Thresholds
    Write-Host "`n  SCL Thresholds:" -ForegroundColor Cyan
    Write-Host "    SCL Delete Threshold: $($policy.SCLDelete)"
    Write-Host "    SCL Reject Threshold: $($policy.SCLReject)"
    Write-Host "    SCL Quarantine Threshold: $($policy.SCLQuarantine)"
    Write-Host "    SCL Junk Threshold: $($policy.SCLJunk)"
    
    # Allowed Lists
    Write-Host "`n  Allowed Lists:" -ForegroundColor Cyan
    Write-Host "    Allowed Sender Domains: $($policy.AllowedSenderDomains.Count)"
    if ($policy.AllowedSenderDomains.Count -gt 0 -and $policy.AllowedSenderDomains.Count -le 10) {
        $policy.AllowedSenderDomains | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
    } elseif ($policy.AllowedSenderDomains.Count -gt 10) {
        Write-Host "      (First 10 of $($policy.AllowedSenderDomains.Count)):" -ForegroundColor Gray
        $policy.AllowedSenderDomains | Select-Object -First 10 | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
    }
    
    Write-Host "    Allowed Senders: $($policy.AllowedSenders.Count)"
    if ($policy.AllowedSenders.Count -gt 0 -and $policy.AllowedSenders.Count -le 10) {
        $policy.AllowedSenders | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
    } elseif ($policy.AllowedSenders.Count -gt 10) {
        Write-Host "      (First 10 of $($policy.AllowedSenders.Count)):" -ForegroundColor Gray
        $policy.AllowedSenders | Select-Object -First 10 | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
    }
    
    Write-Host "    Blocked Sender Domains: $($policy.BlockedSenderDomains.Count)"
    Write-Host "    Blocked Senders: $($policy.BlockedSenders.Count)"
}

# 3. ANTI-PHISHING POLICIES
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " ANTI-PHISHING POLICIES" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
$phishPolicies = Get-AntiPhishPolicy
foreach ($policy in $phishPolicies) {
    Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor Yellow
    Write-Host "  Enabled: $($policy.Enabled)"
    Write-Host "  DMARC Settings:" -ForegroundColor Cyan
    Write-Host "    DMARC Policy Action: $($policy.DmarcPolicyAction)"
    Write-Host "    DMARC Quarantine Action: $($policy.DmarcQuarantineAction)"
    Write-Host "    DMARC Reject Action: $($policy.DmarcRejectAction)"
    Write-Host "    Honor DMARC Policy: $($policy.HonorDmarcPolicy)"
    Write-Host "  Impersonation Protection:" -ForegroundColor Cyan
    Write-Host "    User Protection: $($policy.EnableTargetedUserProtection)"
    Write-Host "    Domain Protection: $($policy.EnableTargetedDomainsProtection)"
    Write-Host "    Mailbox Intelligence: $($policy.EnableMailboxIntelligence)"
    Write-Host "    Mailbox Intelligence Protection: $($policy.EnableMailboxIntelligenceProtection)"
    Write-Host "  Spoof Settings:" -ForegroundColor Cyan
    Write-Host "    Spoof Intelligence: $($policy.EnableSpoofIntelligence)"
    Write-Host "    Unauthenticated Sender: $($policy.EnableUnauthenticatedSender)"
    Write-Host "    Authentication Fail Action: $($policy.AuthenticationFailAction)"
    Write-Host "  Threshold Settings:" -ForegroundColor Cyan
    Write-Host "    Phishing Threshold: $($policy.PhishThresholdLevel)"
}

# 4. TENANT ALLOW/BLOCK LIST
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " TENANT ALLOW/BLOCK LIST" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue

# Spoof Items
Write-Host "`nSpoofed Sender Entries (Allowed):" -ForegroundColor Yellow
try {
    $spoofItems = Get-TenantAllowBlockListSpoofItems -Action Allow -ErrorAction SilentlyContinue
    if ($spoofItems) {
        Write-Host "  Total: $($spoofItems.Count) entries"
        $spoofItems | Select-Object -First 10 | Format-Table SpoofedUser,SendingInfrastructure,SpoofType,Action -AutoSize
        if ($spoofItems.Count -gt 10) {
            Write-Host "  ... and $($spoofItems.Count - 10) more entries"
        }
    } else {
        Write-Host "  None configured"
    }
} catch {
    Write-Host "  Unable to retrieve spoof items"
}

# Sender Allow List
Write-Host "`nSender Allow Entries:" -ForegroundColor Yellow
try {
    $senderAllow = Get-TenantAllowBlockListItems -ListType Sender -Allow -ErrorAction SilentlyContinue
    if ($senderAllow) {
        Write-Host "  Total: $($senderAllow.Count) entries"
        $senderAllow | Select-Object -First 5 | Format-Table Value,Action,ExpirationDate,Notes -AutoSize
    } else {
        Write-Host "  None configured"
    }
} catch {
    Write-Host "  Unable to retrieve sender allow list"
}

# Domain Allow List
Write-Host "`nDomain Allow Entries:" -ForegroundColor Yellow
try {
    $domainAllow = Get-TenantAllowBlockListItems -ListType Domain -Allow -ErrorAction SilentlyContinue
    if ($domainAllow) {
        Write-Host "  Total: $($domainAllow.Count) entries"
        $domainAllow | Select-Object -First 5 | Format-Table Value,Action,ExpirationDate,Notes -AutoSize
    } else {
        Write-Host "  None configured"
    }
} catch {
    Write-Host "  Unable to retrieve domain allow list"
}

# 5. MAIL FLOW RULES (TRANSPORT RULES)
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " MAIL FLOW RULES (TRANSPORT RULES)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
$rules = Get-TransportRule
Write-Host "Total Rules: $($rules.Count)" -ForegroundColor Yellow
if ($rules.Count -gt 0) {
    foreach ($rule in $rules) {
        Write-Host "`nRule: $($rule.Name)" -ForegroundColor Yellow
        Write-Host "  State: $($rule.State)"
        Write-Host "  Priority: $($rule.Priority)"
        Write-Host "  Mode: $($rule.Mode)"
        if ($rule.Description) {
            Write-Host "  Description: $($rule.Description)"
        }
        
        # Show conditions
        if ($rule.FromAddressContainsWords) {
            Write-Host "  From Contains: $($rule.FromAddressContainsWords -join ', ')" -ForegroundColor Gray
        }
        if ($rule.SenderDomainIs) {
            Write-Host "  Sender Domain Is: $($rule.SenderDomainIs -join ', ')" -ForegroundColor Gray
        }
        if ($rule.RecipientDomainIs) {
            Write-Host "  Recipient Domain Is: $($rule.RecipientDomainIs -join ', ')" -ForegroundColor Gray
        }
        if ($rule.SCLOver) {
            Write-Host "  SCL Over: $($rule.SCLOver)" -ForegroundColor Gray
        }
        
        # Show actions
        if ($rule.SetSCL) {
            Write-Host "  Action - Set SCL to: $($rule.SetSCL)" -ForegroundColor Cyan
        }
        if ($rule.SetHeaderName -and $rule.SetHeaderValue) {
            Write-Host "  Action - Set Header: $($rule.SetHeaderName) = $($rule.SetHeaderValue)" -ForegroundColor Cyan
        }
        if ($rule.ModifySubject) {
            Write-Host "  Action - Modify Subject: $($rule.ModifySubject)" -ForegroundColor Cyan
        }
        if ($rule.DeleteMessage) {
            Write-Host "  Action - Delete Message: $($rule.DeleteMessage)" -ForegroundColor Cyan
        }
        if ($rule.Quarantine) {
            Write-Host "  Action - Quarantine: $($rule.Quarantine)" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "  No mail flow rules configured"
}

# 6. SAFE ATTACHMENTS & SAFE LINKS
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " DEFENDER FOR OFFICE 365 FEATURES" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue

# Safe Attachments
Write-Host "`nSafe Attachments:" -ForegroundColor Yellow
try {
    $safeAttach = Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue
    if ($safeAttach) {
        foreach ($policy in $safeAttach) {
            Write-Host "  Policy: $($policy.Name)"
            Write-Host "    Action: $($policy.Action)"
            Write-Host "    Redirect: $($policy.Redirect)"
            Write-Host "    Redirect Address: $($policy.RedirectAddress)"
        }
    } else {
        Write-Host "  ⚠️ No Safe Attachment policies configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ℹ️ Safe Attachments not available (requires Defender for Office 365)" -ForegroundColor Gray
}

# Safe Links
Write-Host "`nSafe Links:" -ForegroundColor Yellow
try {
    $safeLinks = Get-SafeLinksPolicy -ErrorAction SilentlyContinue
    if ($safeLinks) {
        foreach ($policy in $safeLinks) {
            Write-Host "  Policy: $($policy.Name)"
            Write-Host "    Scan URLs: $($policy.ScanUrls)"
            Write-Host "    Track Clicks: $($policy.TrackClicks)"
            Write-Host "    Enable for Internal: $($policy.EnableForInternalSenders)"
        }
    } else {
        Write-Host "  ⚠️ No Safe Links policies configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ℹ️ Safe Links not available (requires Defender for Office 365)" -ForegroundColor Gray
}

# 7. QUARANTINE POLICIES
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " QUARANTINE POLICIES" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
try {
    $quarPolicies = Get-QuarantinePolicy -ErrorAction SilentlyContinue
    if ($quarPolicies) {
        foreach ($policy in $quarPolicies) {
            Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor Yellow
            Write-Host "  End User Quarantine Permissions:"
            Write-Host "    Can Delete: $($policy.EndUserQuarantinePermissions.PermissionToDelete)"
            Write-Host "    Can Preview: $($policy.EndUserQuarantinePermissions.PermissionToPreview)"
            Write-Host "    Can Release: $($policy.EndUserQuarantinePermissions.PermissionToRelease)"
            Write-Host "    Can Request Release: $($policy.EndUserQuarantinePermissions.PermissionToRequestRelease)"
            Write-Host "    Can Block Sender: $($policy.EndUserQuarantinePermissions.PermissionToBlockSender)"
        }
    }
} catch {
    Write-Host "  Unable to retrieve quarantine policies"
}

# 8. OUTBOUND SPAM POLICY
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " OUTBOUND SPAM POLICY" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
$outbound = Get-HostedOutboundSpamFilterPolicy
foreach ($policy in $outbound) {
    Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor Yellow
    Write-Host "  Recipient Limit Per Hour: $($policy.RecipientLimitPerHour)"
    Write-Host "  Recipient Limit Per Day: $($policy.RecipientLimitPerDay)"
    Write-Host "  Outbound Spam Action: $($policy.OutboundSpamAction)"
    Write-Host "  Auto Forwarding Mode: $($policy.AutoForwardingMode)"
}

# 9. DKIM & SPF STATUS
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " EMAIL AUTHENTICATION (DKIM/SPF/DMARC)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue

# DKIM
Write-Host "`nDKIM Configuration:" -ForegroundColor Yellow
$dkim = Get-DkimSigningConfig
foreach ($domain in $dkim) {
    Write-Host "  Domain: $($domain.Domain)"
    Write-Host "    Enabled: $($domain.Enabled)"
    Write-Host "    Status: $($domain.Status)"
    if ($domain.Selector1CNAME) {
        Write-Host "    Selector1 CNAME: $($domain.Selector1CNAME)" -ForegroundColor Gray
    }
    if ($domain.Selector2CNAME) {
        Write-Host "    Selector2 CNAME: $($domain.Selector2CNAME)" -ForegroundColor Gray
    }
}

# SPF
Write-Host "`nSPF Record Check:" -ForegroundColor Yellow
try {
    $spf = Resolve-DnsName -Name cogitativo.com -Type TXT -ErrorAction SilentlyContinue | Where-Object {$_.Strings -like "*spf*"}
    if ($spf) {
        Write-Host "  ✅ SPF Record: $($spf.Strings)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ No SPF record found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Unable to check SPF record"
}

# DMARC
Write-Host "`nDMARC Record Check:" -ForegroundColor Yellow
try {
    $dmarc = Resolve-DnsName -Name _dmarc.cogitativo.com -Type TXT -ErrorAction SilentlyContinue
    if ($dmarc) {
        Write-Host "  ✅ DMARC Record: $($dmarc.Strings)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ No DMARC record found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Unable to check DMARC record"
}

# 10. SUMMARY AND RECOMMENDATIONS
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host " SUMMARY & RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue

Write-Host "`n📊 CURRENT CONFIGURATION SUMMARY:" -ForegroundColor Yellow
$defaultPolicy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "  • Allowed Sender Domains: $($defaultPolicy.AllowedSenderDomains.Count)"
Write-Host "  • Allowed Senders: $($defaultPolicy.AllowedSenders.Count)"
Write-Host "  • Bulk Threshold: $($defaultPolicy.BulkThreshold)"
Write-Host "  • SCL Junk Threshold: $($defaultPolicy.SCLJunk)"
Write-Host "  • SCL Quarantine Threshold: $($defaultPolicy.SCLQuarantine)"

$defaultPhish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true -or $_.Name -like "*Default*"} | Select-Object -First 1
if ($defaultPhish) {
    Write-Host "  • DMARC Policy Action: $($defaultPhish.DmarcPolicyAction)"
    Write-Host "  • Honor DMARC Policy: $($defaultPhish.HonorDmarcPolicy)"
}

Write-Host "`n⚠️ DMARC QUARANTINE ISSUE:" -ForegroundColor Red
Write-Host "  Current Issue: Legitimate emails being quarantined due to DMARC policy"
Write-Host "  Root Causes:"
Write-Host "    1. DMARC policy action is set to strict enforcement"
Write-Host "    2. Some legitimate senders failing DMARC authentication"
Write-Host "    3. SCL threshold may be too aggressive"

Write-Host "`n✅ RECOMMENDED FIXES:" -ForegroundColor Green
Write-Host "  1. ADJUST SCL THRESHOLDS:" -ForegroundColor Yellow
Write-Host "     Set-HostedContentFilterPolicy -Identity Default ```-SCLJunk 4``"
Write-Host "     (This will send spam with SCL 4+ to Junk instead of quarantine)"
Write-Host ""
Write-Host "  2. MODIFY DMARC HANDLING:" -ForegroundColor Yellow
Write-Host "     Set-AntiPhishPolicy -Identity 'Office365 AntiPhish Default' ```"
Write-Host "       -DmarcQuarantineAction MoveToJmf ```"
Write-Host "       -DmarcRejectAction MoveToJmf"
Write-Host ""
Write-Host "  3. REVIEW ALLOWED LISTS:" -ForegroundColor Yellow
Write-Host "     Your allowed lists are configured but may need additions for:"
Write-Host "     - Services that fail DMARC (marketing platforms, newsletters)"
Write-Host "     - Third-party senders on behalf of your domain"
Write-Host ""
Write-Host "  4. ENABLE END-USER QUARANTINE ACCESS:" -ForegroundColor Yellow
Write-Host "     Set-HostedContentFilterPolicy -Identity Default ```"
Write-Host "       -EnableEndUserSpamNotifications `$true ```"
Write-Host "       -EndUserSpamNotificationFrequency 1"

Write-Host "`n📋 IMMEDIATE ACTION ITEMS:" -ForegroundColor Cyan
Write-Host "  Run these commands to reduce false positives:" -ForegroundColor White
Write-Host ""
Write-Host "  # Lower SCL threshold to reduce quarantine" -ForegroundColor Gray
Write-Host "  Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4" -ForegroundColor White
Write-Host ""
Write-Host "  # Change DMARC quarantine to Junk folder instead" -ForegroundColor Gray
Write-Host "  Set-AntiPhishPolicy -Identity 'Office365 AntiPhish Default' -DmarcQuarantineAction MoveToJmf" -ForegroundColor White
Write-Host ""
Write-Host "  # Enable user notifications for quarantine" -ForegroundColor Gray
Write-Host "  Set-HostedContentFilterPolicy -Identity Default -EnableEndUserSpamNotifications `$true" -ForegroundColor White

Write-Host "`n=== Audit Complete ===" -ForegroundColor Green
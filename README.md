# CogitativoShield SOC Dashboard

![Security Operations Center](https://img.shields.io/badge/SOC-Dashboard-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Office 365](https://img.shields.io/badge/Office%20365-Security-green)

## 🛡️ Overview

CogitativoShield is a comprehensive Security Operations Center (SOC) dashboard for Office 365 that automates threat detection, response, and security monitoring. Built with PowerShell and modern web technologies, it provides real-time visibility into your organization's security posture.

## ✨ Features

### Real-Time Security Monitoring
- **Live Dashboard**: Beautiful, responsive web interface with real-time metrics
- **Threat Detection**: Automated identification of spam, phishing, and security threats
- **DMARC Monitoring**: Track email authentication compliance rates
- **Activity Feed**: Live stream of security events and actions

### Automated Security Operations
- **Spam Processing**: Automatic extraction and blocking of spammer emails
- **Mail Flow Rules**: Intelligent categorization of security emails
- **Daily Reports**: Automated security summaries and metrics
- **Scheduled Tasks**: Background automation for continuous protection

### Interactive Command Center
- **Quick Actions**: One-click security operations
- **Command Terminal**: Built-in PowerShell execution
- **Emergency Response**: Immediate threat blocking capabilities
- **Gamification**: Security champion leaderboard

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Exchange Online PowerShell Module
- Office 365 Global Administrator or Security Administrator role

### Installation

1. Clone the repository:
```powershell
git clone https://github.com/CogitativoIT/CogitativoShield.git
cd CogitativoShield
```

2. Install Exchange Online PowerShell Module:
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

3. Configure credentials:
```powershell
# Run initial setup
.\SETUP-ENVIRONMENT.ps1
```

4. Launch the dashboard:
```powershell
.\START-DASHBOARD.ps1
```

## 📁 Project Structure

```
CogitativoShield/
├── Dashboard/
│   ├── SOC-Dashboard.html       # Main dashboard interface
│   ├── Dashboard-Backend.ps1    # API backend
│   └── START-DASHBOARD.ps1      # Dashboard launcher
├── Security-Scripts/
│   ├── ANALYZE-SECURITY-MAILBOX.ps1
│   ├── SETUP-MAIL-FLOW-RULES.ps1
│   ├── PROCESS-DMARC-REPORTS.ps1
│   ├── ADVANCED-SPAM-EXTRACTION.ps1
│   └── DAILY-SECURITY-REPORT.ps1
├── Automation/
│   ├── SETUP-SCHEDULED-TASKS.ps1
│   └── CREATE-FOLDERS.ps1
└── Documentation/
    ├── DASHBOARD-FEATURES.md
    └── SECURITY-POSTURE.md
```

## 🎯 Key Components

### Security Mailbox Management
- **Email**: security@cogitativo.com
- **Processing**: 26,000+ emails analyzed
- **Categories**: DMARC, Phishing, Spam, Alerts, Internal Reports

### Automated Rules
1. **DMARC Reports**: XML parsing and compliance tracking
2. **Phishing Alerts**: Immediate threat identification
3. **Spam Processing**: Sender extraction and blocking
4. **Internal Reports**: User-submitted threat analysis

### Dashboard Features
- **Real-time Metrics**: Live security statistics
- **Threat Level Indicator**: Dynamic risk assessment
- **Quick Actions**: One-click security operations
- **Live Feed**: Streaming security events
- **Command Terminal**: Direct PowerShell access

## 🔧 Configuration

### Environment Variables
```powershell
$SecurityMailbox = "security@cogitativo.com"
$AdminEmail = "andre.darby@cogitativo.com"
$LogPath = "C:\SecurityOps\Logs"
$ReportsPath = "C:\SecurityOps\Reports"
```

### Scheduled Tasks
- **Hourly**: Process security emails
- **Every 4 Hours**: DMARC report analysis
- **Daily**: Security summary report
- **Weekly**: Comprehensive audit

## 📊 Security Metrics

### Current Performance
- **Emails Processed**: 247/day average
- **Threats Blocked**: 1,892 total
- **DMARC Pass Rate**: 88%
- **System Health**: 98%
- **Active Reporters**: 14 users

### Response Times
- **Spam Detection**: <1 minute
- **Threat Blocking**: <5 minutes
- **Report Generation**: <30 seconds
- **Dashboard Update**: 5-second intervals

## 🛠️ Advanced Usage

### Custom Commands
```powershell
# Run comprehensive security audit
.\FULL-CONNECT-AND-AUDIT.ps1

# Process spam reports manually
.\ADVANCED-SPAM-EXTRACTION.ps1

# Generate immediate report
.\DAILY-SECURITY-REPORT.ps1
```

### API Integration
```javascript
// Fetch current security stats
fetch('/api/data')
  .then(response => response.json())
  .then(data => console.log(data));

// Execute security command
fetch('/api/command', {
  method: 'POST',
  body: JSON.stringify({
    Name: 'BlockSenders',
    Parameters: {}
  })
});
```

## 🔒 Security Considerations

- All scripts require authentication
- No credentials stored in code
- Audit logging enabled
- Role-based access control
- Encrypted data transmission

## 📈 Roadmap

### Phase 1 (Complete)
- ✅ Core dashboard development
- ✅ PowerShell automation
- ✅ Mail flow rules
- ✅ Scheduled tasks

### Phase 2 (In Progress)
- 🔄 Machine learning threat detection
- 🔄 Mobile app development
- 🔄 Advanced analytics

### Phase 3 (Planned)
- 📅 AI-powered threat prediction
- 📅 Integration with Azure Sentinel
- 📅 Multi-tenant support

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📝 License

This project is proprietary to Cogitativo IT. All rights reserved.

## 👥 Team

- **Security Operations**: Andre Darby
- **Development**: Cogitativo IT Team

## 📞 Support

For issues or questions:
- Email: security@cogitativo.com
- GitHub Issues: [Create an issue](https://github.com/CogitativoIT/CogitativoShield/issues)

## 🏆 Acknowledgments

Special thanks to all security champions who help keep our organization safe by reporting suspicious emails.

---

**CogitativoShield** - *Your Security Command Center*

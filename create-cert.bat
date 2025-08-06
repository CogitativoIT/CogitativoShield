@echo off
powershell -ExecutionPolicy Bypass -Command ^
"$cert = New-SelfSignedCertificate -Subject 'CN=O365-Automation-Cogitativo' -CertStoreLocation 'cert:\CurrentUser\My' -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(5); ^
Write-Host 'Certificate Thumbprint:' -NoNewline; Write-Host $cert.Thumbprint -ForegroundColor Green; ^
Export-Certificate -Cert $cert -FilePath 'C:\Users\andre.darby\Ops\O365-Automation.cer' | Out-Null; ^
$cert.Thumbprint | Out-File 'C:\Users\andre.darby\Ops\cert-thumbprint.txt'; ^
Write-Host 'Certificate created and exported to O365-Automation.cer' -ForegroundColor Green"
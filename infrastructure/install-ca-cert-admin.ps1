# Run this script as Administrator to install CA cert system-wide
# Right-click this file and select "Run with PowerShell"

$certPath = "C:\Users\Fred\projects\infrastructure\Homelab-Root-CA.crt"

Write-Host "Installing Homelab CA Certificate (System-Wide)..." -ForegroundColor Cyan
Write-Host ""

try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($certPath)
    
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root','LocalMachine')
    $store.Open('ReadWrite')
    $store.Add($cert)
    $store.Close()
    
    Write-Host "SUCCESS! CA certificate installed system-wide!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Certificate Details:" -ForegroundColor Cyan
    Write-Host "  Subject: $($cert.Subject)" -ForegroundColor White
    Write-Host "  Issuer: $($cert.Issuer)" -ForegroundColor White
    Write-Host "  Valid Until: $($cert.NotAfter)" -ForegroundColor White
    Write-Host ""
    Write-Host "Close and reopen your browser, then visit:" -ForegroundColor Yellow
    Write-Host "  https://10.0.10.24:8123" -ForegroundColor White
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you ran this script as Administrator!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

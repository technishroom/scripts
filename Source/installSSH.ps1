# Funkcja do sprawdzenia, czy skrypt działa z uprawnieniami administratora
function Test-IsAdministrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Jeśli skrypt nie jest uruchomiony jako administrator, uruchom go ponownie z uprawnieniami administratora
if (-not (Test-IsAdministrator)) {
    Write-Host "Uruchamianie skryptu z uprawnieniami administratora..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Sprawdzamy, czy OpenSSH jest już zainstalowane
$sshFeature = Get-WindowsCapability -Online | Where-Object {$_.Name -like 'OpenSSH.Server*'}

# Instalujemy OpenSSH Server, jeśli nie jest zainstalowane
if ($sshFeature.State -ne 'Installed') {
    Write-Host "Instalowanie OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "Instalacja zakończona."
} else {
    Write-Host "OpenSSH Server jest już zainstalowane."
}

# Uruchamiamy usługę OpenSSH Server
Write-Host "Uruchamianie usługi OpenSSH Server..."
Start-Service sshd

# Ustawiamy, aby usługa uruchamiała się automatycznie przy starcie systemu
Set-Service -Name sshd -StartupType 'Automatic'

# Sprawdzamy status usługi
Write-Host "Sprawdzanie statusu usługi OpenSSH..."
Get-Service sshd

# Dodajemy regułę zapory, aby umożliwić połączenia SSH w sieci publicznej
Write-Host "Dodawanie reguły zapory dla SSH w sieci publicznej..."
New-NetFirewallRule -Name "Allow_SSH_Public" -DisplayName "Allow OpenSSH In Public Network" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Public

Write-Host "Reguła zapory została dodana."
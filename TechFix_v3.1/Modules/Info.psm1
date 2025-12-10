# ==========================================
# Info.psm1
# Modulo: Informacion del sistema
# ==========================================

function Show-InfoMenu {
    while ($true) {
        Clear-Host
        Show-TechFixLogo
        Show-Title "MENU - INFORMACION DEL SISTEMA"

        Write-Host "1) Informacion general del sistema" -ForegroundColor White
        Write-Host "2) Informacion de hardware detallada" -ForegroundColor White
        Write-Host "3) Informacion de red y conectividad" -ForegroundColor White
        Write-Host "4) Espacio en disco y almacenamiento" -ForegroundColor White
        Write-Host "5) Estado de servicios criticos" -ForegroundColor White
        Write-Host "6) Software instalado y updates" -ForegroundColor White
        Write-Host "0) Volver al menu principal" -ForegroundColor Gray
        Write-Host ""

        $opc = Get-UserChoice "Ingrese una opcion"

        switch ($opc) {
            "1" { Get-SystemInfo }
            "2" { Get-DetailedHardwareInfo }
            "3" { Get-NetworkConnectivityInfo }
            "4" { Get-StorageDetailedInfo }
            "5" { Get-CriticalServicesStatus }
            "6" { Get-SoftwareUpdatesInfo }
            "0" { return }
            default {
                Write-Host "Opcion invalida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        Pause
    }
}

function Get-SystemInfo {
    Show-Title "INFORMACION GENERAL DEL SISTEMA"
    
    try {
        Write-Host "=== INFORMACION BASICA ===" -ForegroundColor Yellow
        $computerInfo = Get-ComputerInfo
        Write-Host "Nombre del equipo: $($computerInfo.CsName)" -ForegroundColor Cyan
        Write-Host "Usuario actual: $($computerInfo.CsUserName)" -ForegroundColor Cyan
        Write-Host "Dominio: $($computerInfo.CsDomain)" -ForegroundColor Cyan
        Write-Host "Fabricante: $($computerInfo.CsManufacturer)" -ForegroundColor Cyan
        Write-Host "Modelo: $($computerInfo.CsModel)" -ForegroundColor Cyan
        
        Write-Host "`n=== SISTEMA OPERATIVO ===" -ForegroundColor Yellow
        Write-Host "SO: $($computerInfo.WindowsProductName)" -ForegroundColor Cyan
        Write-Host "Version: $($computerInfo.WindowsVersion)" -ForegroundColor Cyan
        Write-Host "Edicion: $($computerInfo.WindowsEditionId)" -ForegroundColor Cyan
        Write-Host "Arquitectura: $($computerInfo.OsArchitecture)" -ForegroundColor Cyan
        Write-Host "Tiempo activo: $([math]::Round($computerInfo.OsUptime.TotalHours, 2)) horas" -ForegroundColor Cyan
        
        Write-Host "`n=== BIOS ===" -ForegroundColor Yellow
        Write-Host "Fabricante: $($computerInfo.BiosManufacturer)" -ForegroundColor Cyan
        Write-Host "Version: $($computerInfo.BiosVersion)" -ForegroundColor Cyan
        Write-Host "Fecha: $($computerInfo.BiosReleaseDate)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "Error al obtener informacion del sistema: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-DetailedHardwareInfo {
    Show-Title "INFORMACION DETALLADA DE HARDWARE"

    try {
        Write-Host "=== PROCESADOR ===" -ForegroundColor Yellow
        $processors = Get-CimInstance Win32_Processor
        foreach ($cpu in $processors) {
            Write-Host "Procesador: $($cpu.Name)" -ForegroundColor Cyan
            Write-Host "Nucleos: $($cpu.NumberOfCores) fisicos, $($cpu.NumberOfLogicalProcessors) logicos" -ForegroundColor Cyan
            Write-Host "Velocidad: $($cpu.MaxClockSpeed) MHz" -ForegroundColor Cyan
            Write-Host "Socket: $($cpu.SocketDesignation)" -ForegroundColor Cyan
            Write-Host ""
        }

        Write-Host "=== MEMORIA RAM ===" -ForegroundColor Yellow
        $memory = Get-CimInstance Win32_PhysicalMemory
        $totalMemory = 0
        foreach ($mem in $memory) {
            $sizeGB = [math]::Round($mem.Capacity / 1GB, 2)
            $totalMemory += $sizeGB
            Write-Host "Modulo: $sizeGB GB - $($mem.Speed) MHz - $($mem.Manufacturer)" -ForegroundColor Cyan
        }
        Write-Host "Total RAM: $totalMemory GB" -ForegroundColor Green

        Write-Host "`n=== ALMACENAMIENTO ===" -ForegroundColor Yellow
        $disks = Get-CimInstance Win32_DiskDrive
        foreach ($disk in $disks) {
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            Write-Host "Disco: $($disk.Model)" -ForegroundColor Cyan
            Write-Host "Tamano: $sizeGB GB - Interface: $($disk.InterfaceType)" -ForegroundColor Cyan
            Write-Host ""
        }

        Write-Host "=== TARJETAS DE VIDEO ===" -ForegroundColor Yellow
        $gpus = Get-CimInstance Win32_VideoController
        foreach ($gpu in $gpus) {
            if ($gpu.Name -notlike "*Remote*" -and $gpu.Name -notlike "*Mirror*") {
                $vramMB = if ($gpu.AdapterRAM -gt 0) { [math]::Round($gpu.AdapterRAM / 1MB, 2) } else { "Desconocido" }
                Write-Host "GPU: $($gpu.Name)" -ForegroundColor Cyan
                Write-Host "VRAM: $vramMB MB - Driver: $($gpu.DriverVersion)" -ForegroundColor Cyan
                Write-Host ""
            }
        }

    } catch {
        Write-Host "Error al obtener informacion de hardware: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-NetworkConnectivityInfo {
    Show-Title "INFORMACION DE RED Y CONECTIVIDAD"

    try {
        Write-Host "=== ADAPTADORES DE RED ===" -ForegroundColor Yellow
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            Write-Host "Adaptador: $($adapter.Name)" -ForegroundColor Cyan
            Write-Host "Estado: $($adapter.Status) - Velocidad: $($adapter.LinkSpeed)" -ForegroundColor Cyan
            Write-Host "MAC: $($adapter.MacAddress)" -ForegroundColor Cyan
            
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($ipConfig) {
                Write-Host "IP: $($ipConfig.IPAddress)" -ForegroundColor Cyan
            }
            Write-Host ""
        }

        Write-Host "=== CONECTIVIDAD INTERNET ===" -ForegroundColor Yellow
        Write-Host "Probando conectividad a internet..." -ForegroundColor Gray
        $pingResult = Test-Connection 8.8.8.8 -Count 2 -Quiet
        if ($pingResult) {
            Write-Host "Conectividad internet: OK" -ForegroundColor Green
        } else {
            Write-Host "Conectividad internet: FALLIDO" -ForegroundColor Red
        }

        Write-Host "`n=== DNS CONFIGURADO ===" -ForegroundColor Yellow
        Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses } | 
            Select-Object InterfaceAlias, ServerAddresses | Format-Table -AutoSize

    } catch {
        Write-Host "Error al obtener informacion de red: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-StorageDetailedInfo {
    Show-Title "INFORMACION DETALLADA DE ALMACENAMIENTO"

    try {
        $drives = Get-PSDrive -PSProvider FileSystem
        Write-Host "=== UNIDADES DE ALMACENAMIENTO ===" -ForegroundColor Yellow
        
        foreach ($drive in $drives) {
            $freeGB = [math]::Round($drive.Free / 1GB, 2)
            $usedGB = [math]::Round($drive.Used / 1GB, 2)
            $totalGB = $freeGB + $usedGB
            $freePercent = [math]::Round(($freeGB / $totalGB) * 100, 2)
            
            $color = if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 20) { "Yellow" } else { "Green" }
            
            Write-Host "Unidad $($drive.Name):" -ForegroundColor Cyan
            Write-Host "  Total: $totalGB GB" -ForegroundColor White
            Write-Host "  Usado: $usedGB GB" -ForegroundColor White
            Write-Host "  Libre: $freeGB GB ($freePercent porciento)" -ForegroundColor $color
            Write-Host "  Root: $($drive.Root)" -ForegroundColor Gray
            Write-Host ""
        }

    } catch {
        Write-Host "Error al obtener informacion de almacenamiento: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-CriticalServicesStatus {
    Show-Title "ESTADO DE SERVICIOS CRITICOS"

    $criticalServices = @(
        @{Name="Winmgmt"; DisplayName="Windows Management Instrumentation"},
        @{Name="EventLog"; DisplayName="Windows Event Log"},
        @{Name="CryptSvc"; DisplayName="Cryptographic Services"},
        @{Name="DcomLaunch"; DisplayName="DCOM Server Process Launcher"},
        @{Name="RpcSs"; DisplayName="Remote Procedure Call"},
        @{Name="LanmanWorkstation"; DisplayName="Client for Networks"},
        @{Name="LanmanServer"; DisplayName="Server Service"},
        @{Name="Themes"; DisplayName="Themes"},
        @{Name="AudioSrv"; DisplayName="Windows Audio"}
    )

    Write-Host "=== SERVICIOS ESENCIALES ===" -ForegroundColor Yellow
    
    foreach ($service in $criticalServices) {
        $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
        if ($svc) {
            $statusColor = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
            $startTypeColor = if ($svc.StartType -eq "Automatic") { "Cyan" } else { "Yellow" }
            
            Write-Host "OK $($service.DisplayName)" -ForegroundColor White
            Write-Host "  Estado: $($svc.Status)" -ForegroundColor $statusColor
            Write-Host "  Inicio: $($svc.StartType)" -ForegroundColor $startTypeColor
            Write-Host ""
        }
    }
}

function Get-SoftwareUpdatesInfo {
    Show-Title "SOFTWARE INSTALADO Y UPDATES"

    try {
        Write-Host "=== ULTIMOS UPDATES INSTALADOS ===" -ForegroundColor Yellow
        $updates = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
        $updates | Format-Table HotFixID, Description, InstalledOn, InstalledBy -AutoSize

        Write-Host "`n=== SOFTWARE INSTALADO (Aplicaciones principales) ===" -ForegroundColor Yellow
        $software = Get-CimInstance Win32_Product | 
                    Select-Object -First 15 Name, Version, Vendor, InstallDate |
                    Sort-Object Name
        
        $software | Format-Table -AutoSize

    } catch {
        Write-Host "Error al obtener informacion de software: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Show-InfoMenu, Get-*
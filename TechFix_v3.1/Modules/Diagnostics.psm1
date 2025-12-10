# ==========================================
# Diagnostics.psm1
# Modulo: Diagnosticos del sistema
# ==========================================

function Show-DiagnosticsMenu {
    while ($true) {
		Clear-Host
        Show-TechFixLogo
        Show-Title "MENU - DIAGNOSTICOS DEL SISTEMA"

        Write-Host "1) Diagnostico de rendimiento del sistema" -ForegroundColor White
        Write-Host "2) Verificar eventos criticos" -ForegroundColor White
        Write-Host "3) Informacion completa de discos" -ForegroundColor White
        Write-Host "4) Test de memoria RAM" -ForegroundColor White
        Write-Host "5) Ver servicios problematicos" -ForegroundColor White
        Write-Host "6) Diagnostico de arranque" -ForegroundColor White
        Write-Host "7) Generar informe HTML del sistema" -ForegroundColor White
        Write-Host "0) Volver al menu principal" -ForegroundColor Gray
        Write-Host ""

        $opc = Get-UserChoice "Ingrese una opcion"

        switch ($opc) {
            "1" { Test-SystemPerformance }
            "2" { Get-CriticalEvents }
            "3" { Test-DiskHealth }
            "4" { Test-MemoryRAM }
            "5" { Get-ProblematicServices }
            "6" { Test-BootPerformance }
            "7" { Generate-SystemHtmlReport }
            "0" { return }
            default {
                Write-Host "Opcion invalida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        Pause
    }
}

function Test-SystemPerformance {
    Show-Title "DIAGNOSTICO DE RENDIMIENTO DEL SISTEMA"
    
    Write-Host "Analizando rendimiento del sistema..." -ForegroundColor Cyan
    Write-Host ""
    
    # Uso del CPU - Con manejo mejorado de errores
    Write-Host "=== USO DEL CPU ===" -ForegroundColor Yellow
    try {
        # Metodo alternativo si Get-Counter falla
        $cpuUsage = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
        if ($cpuUsage.Average -ne $null) {
            $usage = [math]::Round($cpuUsage.Average, 2)
            $color = if ($usage -gt 80) { "Red" } else { "Green" }
            Write-Host "CPU: $usage porciento" -ForegroundColor $color
        } else {
            # Metodo de respaldo usando WMI
            $cpu = Get-CimInstance Win32_Processor
            $usage = [math]::Round(($cpu | Measure-Object -Property LoadPercentage -Average).Average, 2)
            $color = if ($usage -gt 80) { "Red" } else { "Green" }
            Write-Host "CPU: $usage porciento" -ForegroundColor $color
        }
    } catch {
        Write-Host "CPU: No disponible - Contadores de rendimiento deshabilitados" -ForegroundColor Yellow
        Write-Host "Sugerencia: Ejecute 'lodctr /r' como administrador para reconstruir contadores" -ForegroundColor Gray
    }
    
    # Uso de memoria
    Write-Host "`n=== USO DE MEMORIA ===" -ForegroundColor Yellow
    try {
        $mem = Get-CimInstance Win32_OperatingSystem
        $totalMem = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
        $freeMem = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
        $usedMem = $totalMem - $freeMem
        $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 2)
        
        Write-Host "Memoria Total: $totalMem GB" -ForegroundColor White
        Write-Host "Memoria Usada: $usedMem GB" -ForegroundColor White
        Write-Host "Memoria Libre: $freeMem GB" -ForegroundColor White
        Write-Host "Porcentaje de uso: $memPercent porciento" -ForegroundColor $(if ($memPercent -gt 85) { "Red" } elseif ($memPercent -gt 70) { "Yellow" } else { "Green" })
    } catch {
        Write-Host "No se pudo obtener uso de memoria" -ForegroundColor Yellow
    }
    
    # Procesos que mas consumen CPU
    Write-Host "`n=== TOP 5 PROCESOS CONSUMO CPU ===" -ForegroundColor Yellow
    try {
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | 
            Format-Table Name, 
                        @{Name="CPU(s)"; Expression={[math]::Round($_.CPU, 2)}}, 
                        @{Name="Memoria(MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}} -AutoSize
    } catch {
        Write-Host "No se pudieron obtener procesos" -ForegroundColor Yellow
    }
    
    # Procesos que mas consumen memoria
    Write-Host "`n=== TOP 5 PROCESOS CONSUMO MEMORIA ===" -ForegroundColor Yellow
    try {
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 | 
            Format-Table Name, 
                        @{Name="Memoria(MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}, 
                        @{Name="CPU(s)"; Expression={[math]::Round($_.CPU, 2)}} -AutoSize
    } catch {
        Write-Host "No se pudieron obtener procesos" -ForegroundColor Yellow
    }
    
    # Informacion adicional del sistema
    Write-Host "`n=== INFORMACION ADICIONAL ===" -ForegroundColor Yellow
    try {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        Write-Host "Tiempo activo: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Cyan
        
        $processCount = (Get-Process).Count
        Write-Host "Procesos activos: $processCount" -ForegroundColor Cyan
        
        $handleCount = (Get-Process | Measure-Object -Property Handles -Sum).Sum
        Write-Host "Handles totales: $handleCount" -ForegroundColor Cyan
    } catch {
        Write-Host "No se pudo obtener informacion adicional" -ForegroundColor Yellow
    }
    
    Write-Log "Diagnostico de rendimiento ejecutado" "INFO"
}

function Get-CriticalEvents {
    Show-Title "EVENTOS CRITICOS DEL SISTEMA"
    
    Write-Host "Recopilando eventos criticos (ultimas 24 horas)..." -ForegroundColor Cyan
    Write-Host ""
    
    $startTime = (Get-Date).AddHours(-24)
    $systemEvents = @()
    $appEvents = @()
    
    # Eventos de Sistema
    Write-Host "=== EVENTOS DE SISTEMA (Error/Critico) ===" -ForegroundColor Yellow
    try {
        # Metodo usando Get-WinEvent (mas moderno)
        $systemEvents = Get-WinEvent -LogName 'System' -ErrorAction SilentlyContinue | 
                       Where-Object { $_.TimeCreated -ge $startTime -and ($_.LevelDisplayName -eq 'Error' -or $_.Level -eq 1) } |
                       Sort-Object TimeCreated -Descending |
                       Select-Object -First 20
        
        if ($systemEvents) {
            $systemEvents | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, 
                                         @{Name="Message"; Expression={$_.Message.Substring(0, [math]::Min(100, $_.Message.Length))}} | 
                Format-Table -AutoSize
        } else {
            Write-Host "No se encontraron eventos criticos en Sistema (ultimas 24h)" -ForegroundColor Green
        }
    } catch {
        # Metodo alternativo usando Get-EventLog
        try {
            Write-Host "Intentando metodo alternativo..." -ForegroundColor Gray
            $systemEvents = Get-EventLog -LogName System -EntryType Error -After $startTime -ErrorAction SilentlyContinue
            if ($systemEvents) {
                $systemEvents | Select-Object TimeGenerated, Source, InstanceId, 
                                             @{Name="Message"; Expression={$_.Message.Substring(0, [math]::Min(100, $_.Message.Length))}} | 
                    Format-Table -AutoSize
            } else {
                Write-Host "No se encontraron eventos criticos en Sistema" -ForegroundColor Green
            }
        } catch {
            Write-Host "No se pudieron obtener eventos del sistema" -ForegroundColor Yellow
            Write-Host "Posible causa: Servicio de registro de eventos no disponible" -ForegroundColor Gray
        }
    }
    
    # Eventos de Aplicacion
    Write-Host "`n=== EVENTOS DE APLICACION (Error/Critico) ===" -ForegroundColor Yellow
    try {
        $appEvents = Get-WinEvent -LogName 'Application' -ErrorAction SilentlyContinue | 
                    Where-Object { $_.TimeCreated -ge $startTime -and ($_.LevelDisplayName -eq 'Error' -or $_.Level -eq 1) } |
                    Sort-Object TimeCreated -Descending |
                    Select-Object -First 20
        
        if ($appEvents) {
            $appEvents | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, 
                                      @{Name="Message"; Expression={$_.Message.Substring(0, [math]::Min(100, $_.Message.Length))}} | 
                Format-Table -AutoSize
        } else {
            Write-Host "No se encontraron eventos criticos en Aplicacion (ultimas 24h)" -ForegroundColor Green
        }
    } catch {
        # Metodo alternativo
        try {
            Write-Host "Intentando metodo alternativo..." -ForegroundColor Gray
            $appEvents = Get-EventLog -LogName Application -EntryType Error -After $startTime -ErrorAction SilentlyContinue
            if ($appEvents) {
                $appEvents | Select-Object TimeGenerated, Source, InstanceId, 
                                          @{Name="Message"; Expression={$_.Message.Substring(0, [math]::Min(100, $_.Message.Length))}} | 
                    Format-Table -AutoSize
            } else {
                Write-Host "No se encontraron eventos criticos en Aplicacion" -ForegroundColor Green
            }
        } catch {
            Write-Host "No se pudieron obtener eventos de aplicacion" -ForegroundColor Yellow
        }
    }
    
    # Resumen
    Write-Host "`n=== RESUMEN ===" -ForegroundColor Yellow
    $systemCount = if ($systemEvents) { $systemEvents.Count } else { 0 }
    $appCount = if ($appEvents) { $appEvents.Count } else { 0 }
    
    Write-Host "Eventos de Sistema: $systemCount" -ForegroundColor $(if ($systemCount -gt 0) { "Red" } else { "Green" })
    Write-Host "Eventos de Aplicacion: $appCount" -ForegroundColor $(if ($appCount -gt 0) { "Red" } else { "Green" })
    
    # Informacion adicional sobre el estado del servicio de eventos
    Write-Host "`n=== ESTADO DEL SERVICIO DE EVENTOS ===" -ForegroundColor Yellow
    try {
        $eventLogService = Get-Service -Name "EventLog" -ErrorAction SilentlyContinue
        if ($eventLogService) {
            Write-Host "Servicio EventLog: $($eventLogService.Status)" -ForegroundColor $(if ($eventLogService.Status -eq 'Running') { 'Green' } else { 'Red' })
        } else {
            Write-Host "Servicio EventLog: No encontrado" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "No se pudo verificar el servicio de eventos" -ForegroundColor Gray
    }
    
    Write-Log "Eventos criticos consultados. Sistema: $systemCount, App: $appCount" "INFO"
}

function Test-DiskHealth {
    Show-Title "INFORMACION COMPLETA DE DISCOS Y ALMACENAMIENTO"
    
    Write-Host "Analizando discos fisicos y volumenes..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # ==========================================
        # 1. DISCOS FISICOS (Win32_DiskDrive)
        # ==========================================
        Write-Host "=== DISCOS FISICOS DETECTADOS ===" -ForegroundColor Yellow
        $physicalDisks = Get-CimInstance Win32_DiskDrive
        
        if (-not $physicalDisks) {
            Write-Host "No se detectaron discos fisicos." -ForegroundColor Red
        } else {
            foreach ($disk in $physicalDisks) {
                $sizeGB = [math]::Round($disk.Size / 1GB, 2)
                $mediaType = switch ($disk.MediaType) {
                    "Fixed hard disk media" { "Disco duro interno" }
                    "Removable media" { "Medio removible (USB)" }
                    "External hard disk media" { "Disco duro externo" }
                    "SSD" { "Unidad de estado solido" }
                    default { $disk.MediaType }
                }
                
                Write-Host "`nDisco Fisico #$($disk.Index)" -ForegroundColor Cyan
                Write-Host "  Modelo: $($disk.Model.Trim())" -ForegroundColor White
                Write-Host "  Fabricante: $($disk.Manufacturer)" -ForegroundColor White
                Write-Host "  Serial: $($disk.SerialNumber.Trim())" -ForegroundColor White
                Write-Host "  Tamano: $sizeGB GB" -ForegroundColor White
                Write-Host "  Tipo: $mediaType" -ForegroundColor White
                Write-Host "  Interface: $($disk.InterfaceType)" -ForegroundColor White
                Write-Host "  Particiones: $($disk.Partitions)" -ForegroundColor White
            }
        }
        
        Write-Host ""
        
        # ==========================================
        # 2. VOLUMENES LOGICOS (Win32_LogicalDisk)
        # ==========================================
        Write-Host "=== VOLUMENES LOGICOS (UNIDADES) ===" -ForegroundColor Yellow
        
        $logicalDisks = Get-CimInstance Win32_LogicalDisk | Where-Object {
            $_.DriveType -in @(2, 3, 4)  # 2=Removable, 3=Fixed, 4=Network
        }
        
        if ($logicalDisks) {
            foreach ($disk in $logicalDisks) {
                $driveType = switch ($disk.DriveType) {
                    2 { "Removible (USB, SD)" }
                    3 { "Disco fijo" }
                    4 { "Unidad de red" }
                    5 { "Unidad CD/DVD" }
                    default { "Desconocido" }
                }
                
                $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
                $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
                $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
                $percentFree = if ($totalSpaceGB -gt 0) { [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100, 2) } else { 0 }
                $percentUsed = if ($totalSpaceGB -gt 0) { [math]::Round(($usedSpaceGB / $totalSpaceGB) * 100, 2) } else { 0 }
                
                Write-Host "`nUnidad $($disk.DeviceID)" -ForegroundColor Cyan
                Write-Host "  Tipo: $driveType" -ForegroundColor White
                Write-Host "  Etiqueta: $($disk.VolumeName)" -ForegroundColor White
                Write-Host "  Sistema archivos: $($disk.FileSystem)" -ForegroundColor White
                Write-Host "  Tamano total: $totalSpaceGB GB" -ForegroundColor White
                Write-Host "  Espacio usado: $usedSpaceGB GB ($percentUsed %)" -ForegroundColor White
                Write-Host "  Espacio libre: $freeSpaceGB GB ($percentFree %)" -ForegroundColor White
                
                # Estado de espacio
                if ($totalSpaceGB -gt 0) {
                    if ($percentFree -lt 10) {
                        Write-Host "  ESTADO: CRITICO - Espacio insuficiente!" -ForegroundColor Red
                    } elseif ($percentFree -lt 20) {
                        Write-Host "  ESTADO: ADVERTENCIA - Espacio bajo" -ForegroundColor Yellow
                    } else {
                        Write-Host "  ESTADO: ADECUADO" -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Host "No se detectaron volumenes logicos." -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # ==========================================
        # 3. INFORMACION DE PARTITIONS (Win32_DiskPartition)
        # ==========================================
        Write-Host "=== INFORMACION DE PARTICIONES ===" -ForegroundColor Yellow
        
        $partitions = Get-CimInstance Win32_DiskPartition | Where-Object {
            $_.Type -notlike "*Reserved*" -and $_.Size -gt 0
        }
        
        if ($partitions) {
            foreach ($partition in $partitions) {
                $sizeGB = [math]::Round($partition.Size / 1GB, 2)
                
                Write-Host "`nParticion: $($partition.Name)" -ForegroundColor Cyan
                Write-Host "  Disco: $($partition.DiskIndex)" -ForegroundColor White
                Write-Host "  Tamano: $sizeGB GB" -ForegroundColor White
                Write-Host "  Tipo: $($partition.Type)" -ForegroundColor White
                Write-Host "  Booteable: $(if ($partition.Bootable) {'Si'} else {'No'})" -ForegroundColor White
                Write-Host "  Primaria: $(if ($partition.PrimaryPartition) {'Si'} else {'No'})" -ForegroundColor White
            }
        }
        
        Write-Host ""
        
        # ==========================================
        # 4. INFORMACION DE TABLA DE PARTICIONES (GPT/MBR)
        # ==========================================
        Write-Host "=== TABLAS DE PARTICION (GPT/MBR) ===" -ForegroundColor Yellow
        
        try {
            # Usar PowerShell Storage module si está disponible
            if (Get-Command Get-Disk -ErrorAction SilentlyContinue) {
                $disksInfo = Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, 
                                                      @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}},
                                                      IsBoot, IsSystem, IsOffline
                
                foreach ($diskInfo in $disksInfo) {
                    $partitionStyle = switch ($diskInfo.PartitionStyle) {
                        "GPT" { "GPT (GUID Partition Table)" }
                        "MBR" { "MBR (Master Boot Record)" }
                        "Raw" { "Sin particionar" }
                        default { $diskInfo.PartitionStyle }
                    }
                    
                    Write-Host "`nDisco #$($diskInfo.Number)" -ForegroundColor Cyan
                    Write-Host "  Nombre: $($diskInfo.FriendlyName)" -ForegroundColor White
                    Write-Host "  Tamano: $($diskInfo.SizeGB) GB" -ForegroundColor White
                    Write-Host "  Tabla particion: $partitionStyle" -ForegroundColor White
                    Write-Host "  Es de arranque: $(if ($diskInfo.IsBoot) {'Si'} else {'No'})" -ForegroundColor White
                    Write-Host "  Es de sistema: $(if ($diskInfo.IsSystem) {'Si'} else {'No'})" -ForegroundColor White
                    Write-Host "  Estado: $(if ($diskInfo.IsOffline) {'Offline'} else {'Online'})" -ForegroundColor White
                }
            } else {
                Write-Host "Modulo Storage no disponible para informacion detallada de GPT/MBR" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "No se pudo obtener informacion de tabla de particiones" -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # ==========================================
        # 5. VOLUMENES DEL SISTEMA ESPECIALES
        # ==========================================
        Write-Host "=== VOLUMENES DEL SISTEMA ESPECIALES ===" -ForegroundColor Yellow
        
        try {
            # Obtener volumen donde está instalado Windows
            $systemDrive = $env:SystemDrive
            $windowsPath = "$systemDrive\Windows"
            
            if (Test-Path $windowsPath) {
                Write-Host "`nVolumen del sistema Windows:" -ForegroundColor Cyan
                Write-Host "  Unidad: $systemDrive" -ForegroundColor White
                Write-Host "  Ruta Windows: $windowsPath" -ForegroundColor White
                
                # Espacio en volumen del sistema
                $sysVol = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
                if ($sysVol) {
                    $freeGB = [math]::Round($sysVol.FreeSpace / 1GB, 2)
                    $totalGB = [math]::Round($sysVol.Size / 1GB, 2)
                    $freePercent = if ($totalGB -gt 0) { [math]::Round(($freeGB / $totalGB) * 100, 2) } else { 0 }
                    
                    Write-Host "  Espacio libre: $freeGB GB ($freePercent %)" -ForegroundColor $(
                        if ($freePercent -lt 15) { "Red" } elseif ($freePercent -lt 25) { "Yellow" } else { "Green" }
                    )
                }
            }
            
            # Obtener volumen de arranque (puede ser diferente al sistema)
            $bootVolumes = Get-CimInstance Win32_Volume | Where-Object {
                $_.BootVolume -eq $true -or $_.SystemVolume -eq $true
            }
            
            foreach ($vol in $bootVolumes) {
                if ($vol.DriveLetter -and $vol.DriveLetter -ne $systemDrive) {
                    Write-Host "`nVolumen de arranque adicional:" -ForegroundColor Cyan
                    Write-Host "  Unidad: $($vol.DriveLetter)" -ForegroundColor White
                    Write-Host "  Etiqueta: $($vol.Label)" -ForegroundColor White
                    Write-Host "  Es de arranque: $(if ($vol.BootVolume) {'Si'} else {'No'})" -ForegroundColor White
                    Write-Host "  Es de sistema: $(if ($vol.SystemVolume) {'Si'} else {'No'})" -ForegroundColor White
                }
            }
        } catch {
            Write-Host "No se pudo obtener informacion de volumenes del sistema" -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # ==========================================
        # 6. RESUMEN Y RECOMENDACIONES
        # ==========================================
        Write-Host "=== RESUMEN Y RECOMENDACIONES ===" -ForegroundColor Magenta
        
        # Resumen de espacio crítico
        $criticalDrives = @()
        $warningDrives = @()
        
        foreach ($disk in $logicalDisks) {
            if ($disk.Size -gt 0) {
                $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                
                if ($freePercent -lt 10) {
                    $criticalDrives += $disk.DeviceID
                } elseif ($freePercent -lt 20) {
                    $warningDrives += $disk.DeviceID
                }
            }
        }
        
        if ($criticalDrives.Count -gt 0) {
            Write-Host "`nATENCION CRITICA:" -ForegroundColor Red
            Write-Host "  Las siguientes unidades tienen menos del 10% de espacio libre:" -ForegroundColor Red
            foreach ($drive in $criticalDrives) {
                Write-Host "  - $drive" -ForegroundColor Red
            }
            Write-Host "  Accion: Libere espacio inmediatamente!" -ForegroundColor Red
        }
        
        if ($warningDrives.Count -gt 0) {
            Write-Host "`nADVERTENCIA:" -ForegroundColor Yellow
            Write-Host "  Las siguientes unidades tienen menos del 20% de espacio libre:" -ForegroundColor Yellow
            foreach ($drive in $warningDrives) {
                Write-Host "  - $drive" -ForegroundColor Yellow
            }
            Write-Host "  Accion: Considere limpiar archivos innecesarios." -ForegroundColor Yellow
        }
        
        if ($criticalDrives.Count -eq 0 -and $warningDrives.Count -eq 0) {
            Write-Host "`nESTADO GENERAL:" -ForegroundColor Green
            Write-Host "  Todas las unidades tienen espacio adecuado." -ForegroundColor Green
        }
        
        # Informacion adicional
        Write-Host "`nINFORMACION ADICIONAL:" -ForegroundColor Cyan
        Write-Host "  Discos fisicos detectados: $($physicalDisks.Count)" -ForegroundColor White
        Write-Host "  Volumenes logicos detectados: $($logicalDisks.Count)" -ForegroundColor White
        if ($partitions) {
            Write-Host "  Particiones detectadas: $($partitions.Count)" -ForegroundColor White
        }
        
    } catch {
        Write-Host "Error al obtener informacion de discos: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Intentando metodo alternativo..." -ForegroundColor Yellow
        
        # Metodo alternativo basico
        try {
            Write-Host "`n=== INFORMACION BASICA DE DISCOS ===" -ForegroundColor Yellow
            Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                if ($_.Used -gt 0 -or $_.Free -gt 0) {
                    $freeGB = [math]::Round($_.Free / 1GB, 2)
                    $usedGB = [math]::Round($_.Used / 1GB, 2)
                    $totalGB = $freeGB + $usedGB
                    $freePercent = if ($totalGB -gt 0) { [math]::Round(($freeGB / $totalGB) * 100, 2) } else { 0 }
                    
                    Write-Host "`nUnidad $($_.Name):" -ForegroundColor Cyan
                    Write-Host "  Total: $totalGB GB" -ForegroundColor White
                    Write-Host "  Usado: $usedGB GB" -ForegroundColor White
                    Write-Host "  Libre: $freeGB GB ($freePercent %)" -ForegroundColor $(
                        if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 20) { "Yellow" } else { "Green" }
                    )
                }
            }
        } catch {
            Write-Host "No se pudo obtener informacion basica de discos" -ForegroundColor Red
        }
    }
    
    Write-Log "Informacion completa de discos ejecutada" "INFO"
}

function Test-MemoryRAM {
    Show-Title "TEST DE MEMORIA RAM"
    
    Write-Host "Analizando memoria RAM..." -ForegroundColor Cyan
    Write-Host ""
    
    # Informacion basica de memoria - CALCULOS CORREGIDOS
    try {
        $memory = Get-CimInstance Win32_ComputerSystem
        $physicalMemory = Get-CimInstance Win32_PhysicalMemory
        $osMemory = Get-CimInstance Win32_OperatingSystem
        
        # CORRECCION: TotalPhysicalMemory esta en BYTES
        $totalPhysicalMem = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        
        # CORRECCION: FreePhysicalMemory esta en KILOBYTES, no en MB
        # Convertir KB a GB: KB / (1024 * 1024) = KB / 1048576
        $availableMemKB = $osMemory.FreePhysicalMemory
        $availableMemGB = [math]::Round($availableMemKB / 1048576, 2)
        
        # Memoria usada CORREGIDA
        $usedMemGB = $totalPhysicalMem - $availableMemGB
        
        # Porcentaje de uso CORREGIDO
        $usagePercent = if ($totalPhysicalMem -gt 0) { 
            [math]::Round(($usedMemGB / $totalPhysicalMem) * 100, 2) 
        } else { 0 }
        
        Write-Host "=== INFORMACION DE MEMORIA ===" -ForegroundColor Yellow
        Write-Host "Memoria Total: $totalPhysicalMem GB" -ForegroundColor White
        Write-Host "Memoria Usada: $([math]::Round($usedMemGB, 2)) GB" -ForegroundColor White
        Write-Host "Memoria Disponible: $availableMemGB GB" -ForegroundColor White
        Write-Host "Porcentaje de Uso: $usagePercent %" -ForegroundColor $(if ($usagePercent -gt 85) { "Red" } elseif ($usagePercent -gt 70) { "Yellow" } else { "Green" })
        
        # Informacion de modulos
        Write-Host "`n=== MODULOS DE MEMORIA ===" -ForegroundColor Yellow
        $physicalMemory | ForEach-Object {
            $sizeGB = [math]::Round($_.Capacity / 1GB, 2)
            Write-Host "Modulo: $sizeGB GB - $($_.Speed) MHz - $($_.Manufacturer)" -ForegroundColor Cyan
        }
        
    } catch {
        Write-Host "Error al obtener informacion de memoria: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Diagnostico de memoria con mdsched (Windows Memory Diagnostic)
    Write-Host "`n=== DIAGNOSTICO AVANZADO ===" -ForegroundColor Yellow
    Write-Host "Para un diagnostico completo de memoria, ejecute Windows Memory Diagnostic." -ForegroundColor White
    $runDiagnostic = Read-Host "Ejecutar diagnostico de memoria ahora? (S/N)"
    
    if ($runDiagnostic -eq "S" -or $runDiagnostic -eq "s") {
        Write-Host "Iniciando Windows Memory Diagnostic..." -ForegroundColor Green
        try {
            Start-Process "mdsched.exe"
            Write-Host "El sistema se reiniciara para realizar el diagnostico." -ForegroundColor Yellow
        } catch {
            Write-Host "No se pudo iniciar el diagnostico de memoria" -ForegroundColor Red
        }
    }
    
    Write-Log "Test de memoria RAM ejecutado" "INFO"
}

function Get-ProblematicServices {
    Show-Title "SERVICIOS PROBLEMATICOS"
    
    Write-Host "Buscando servicios con problemas..." -ForegroundColor Cyan
    Write-Host ""
    
    # Servicios detenidos que deberian estar ejecutandose
    Write-Host "=== SERVICIOS DETENIDOS (Auto/Manual) ===" -ForegroundColor Yellow
    $stoppedServices = Get-Service | Where-Object { 
        $_.Status -eq "Stopped" -and $_.StartType -ne "Disabled" 
    }
    
    if ($stoppedServices) {
        $stoppedServices | Select-Object Name, DisplayName, StartType | 
            Format-Table -AutoSize
    } else {
        Write-Host "No hay servicios detenidos problematicos." -ForegroundColor Green
    }
    
    # Servicios esenciales para verificar
    Write-Host "`n=== VERIFICACION DE SERVICIOS ESENCIALES ===" -ForegroundColor Yellow
    $essentialServices = @(
        @{Name="Winmgmt"; DisplayName="Windows Management Instrumentation"},
        @{Name="EventLog"; DisplayName="Windows Event Log"},
        @{Name="CryptSvc"; DisplayName="Cryptographic Services"},
        @{Name="DcomLaunch"; DisplayName="DCOM Server Process Launcher"},
        @{Name="RpcSs"; DisplayName="Remote Procedure Call"}
    )
    
    foreach ($essential in $essentialServices) {
        $service = Get-Service -Name $essential.Name -ErrorAction SilentlyContinue
        if ($service) {
            $statusColor = if ($service.Status -eq "Running") { "Green" } else { "Red" }
            Write-Host "$($service.Name): $($service.Status)" -ForegroundColor $statusColor
        }
    }
    
    Write-Log "Servicios problematicos consultados" "INFO"
}

function Test-BootPerformance {
    Show-Title "DIAGNOSTICO DE ARRANQUE"
    
    Write-Host "Analizando rendimiento de arranque..." -ForegroundColor Cyan
    Write-Host ""
    
    # Tiempo de arranque desde el evento de inicio
    Write-Host "=== TIEMPO DE ARRANQUE ===" -ForegroundColor Yellow
    try {
        $bootEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ID=100} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($bootEvents) {
            $bootTime = $bootEvents.TimeCreated
            $uptime = (Get-Date) - $bootTime
            Write-Host "Ultimo arranque: $bootTime" -ForegroundColor White
            Write-Host "Tiempo activo: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor White
        }
    } catch {
        Write-Host "No se pudo obtener informacion de arranque." -ForegroundColor Yellow
    }
    
    # Programas de inicio
    Write-Host "`n=== PROGRAMAS DE INICIO ===" -ForegroundColor Yellow
    try {
        $startupPrograms = Get-CimInstance Win32_StartupCommand | 
            Select-Object Name, Command, Location, User | 
            Sort-Object Location
        
        if ($startupPrograms) {
            $startupPrograms | Format-Table -AutoSize
            Write-Host "Total de programas de inicio: $($startupPrograms.Count)" -ForegroundColor Cyan
        } else {
            Write-Host "No se encontraron programas de inicio" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "No se pudieron obtener programas de inicio" -ForegroundColor Yellow
    }
    
    # Servicios que afectan el arranque
    Write-Host "`n=== SERVICIOS DE ARRANQUE AUTOMATICO ===" -ForegroundColor Yellow
    $autoServices = Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Running" }
    Write-Host "Servicios automaticos ejecutandose: $($autoServices.Count)" -ForegroundColor Cyan
    
    # Recomendaciones
    Write-Host "`n=== RECOMENDACIONES ===" -ForegroundColor Magenta
    $startupCount = if ($startupPrograms) { $startupPrograms.Count } else { 0 }
    if ($startupCount -gt 15) {
        Write-Host "Muchos programas de inicio. Considerar deshabilitar algunos." -ForegroundColor Yellow
    } else {
        Write-Host "Cantidad de programas de inicio aceptable." -ForegroundColor Green
    }
    
    Write-Log "Diagnostico de arranque ejecutado" "INFO"
}

function Generate-SystemHtmlReport {
    Show-Title "GENERAR INFORME HTML DEL SISTEMA"

    Write-Host "Recolectando datos para el informe..." -ForegroundColor Cyan

    # Recolectar datos
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $memoryModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        $nics = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
        $servicesStopped = Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -ne "Disabled" } -ErrorAction SilentlyContinue
        
        # CORRECCION: Usar solo "Error" en lugar de "Error,Critical"
        $criticalEvents = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue
        
        $bootEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ID=100} -MaxEvents 1 -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Error al recolectar datos: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Construir nombre por defecto y abrir SaveFileDialog en %TEMP%
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $defaultName = "Reporte_Sistema_$timestamp.html"
    Add-Type -AssemblyName System.Windows.Forms

    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.InitialDirectory = $env:TEMP
    $dlg.FileName = $defaultName
    $dlg.Filter = "HTML files (*.html)|*.html"
    $dlg.Title = "Guardar informe HTML"
    $result = $dlg.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "Operacion cancelada por el usuario." -ForegroundColor Yellow
        return
    }

    $outPath = $dlg.FileName

    # Construir HTML (Estilo 1: profesional, fondo blanco, tablas azules)
    $html = @"
<!DOCTYPE html>
<html lang='es'>
<head>
<meta charset='utf-8'>
<title>Reporte del Sistema - $timestamp</title>
<style>
body { font-family: 'Segoe UI', Tahoma, Arial, sans-serif; background: #ffffff; color: #333333; margin:20px; }
.header { background:#0078d4; color:#ffffff; padding:20px; border-radius:6px; }
.subtitle { color:#f3f6f9; font-size:14px; margin-top:6px; }
.section { margin-top:20px; padding:15px; border:1px solid #e1e1e1; border-radius:6px; background:#ffffff; }
.section h2 { background:#e9f3ff; color:#004a7c; padding:8px; border-radius:4px; }
table { width:100%; border-collapse:collapse; margin-top:10px; }
th { background:#0078d4; color:#ffffff; text-align:left; padding:8px; }
td { padding:8px; border-bottom:1px solid #e9eef3; }
.row-alt { background:#fbfdff; }
.status-good { color:#107c10; font-weight:bold; }
.status-warn { color:#d97706; font-weight:bold; }
.status-bad { color:#a80000; font-weight:bold; }
.footer { margin-top:20px; font-size:12px; color:#666666; }
.traffic-light { display:inline-block; width:20px; height:20px; border-radius:50%; margin-right:10px; }
.traffic-green { background:#107c10; }
.traffic-yellow { background:#d97706; }
.traffic-red { background:#a80000; }
.health-score { font-size:24px; font-weight:bold; color:#0078d4; }
.recommendation { background:#f8f9fa; padding:15px; border-radius:6px; margin-top:10px; border-left:4px solid #0078d4; }
.semaphore-container { text-align:center; margin:20px 0; padding:20px; background:#f8f9fa; border-radius:10px; }
.semaphore-circle { display:inline-block; width:60px; height:60px; border-radius:50%; margin:10px; }
.semaphore-green { background:#107c10; box-shadow:0 0 15px rgba(16, 124, 16, 0.5); }
.semaphore-yellow { background:#d97706; box-shadow:0 0 15px rgba(217, 119, 6, 0.5); }
.semaphore-red { background:#a80000; box-shadow:0 0 15px rgba(168, 0, 0, 0.5); }
.legend { display:flex; justify-content:space-around; background:#e9f3ff; padding:10px; border-radius:6px; margin-top:15px; }
.legend-item { text-align:center; }
</style>
</head>
<body>
<div class='header'>
  <h1>Reporte del Sistema</h1>
  <div class='subtitle'>Generado: $timestamp</div>
</div>

<div class='section'>
  <h2>Informacion general</h2>
  <table>
    <tr><th>Campo</th><th>Valor</th></tr>
    <tr><td>Nombre equipo</td><td>$($env:COMPUTERNAME)</td></tr>
    <tr><td>Sistema operativo</td><td>$($os.Caption) $($os.Version)</td></tr>
    <tr><td>Fabricante</td><td>$($os.Manufacturer)</td></tr>
    <tr><td>CPU</td><td>$($cpu.Name)</td></tr>
  </table>
</div>

<div class='section'>
  <h2>Memoria</h2>
  <table>
    <tr><th>Modulo</th><th>Tamano (GB)</th><th>Velocidad (MHz)</th><th>Fabricante</th></tr>
"@

    if ($memoryModules) {
        foreach ($m in $memoryModules) {
            $sizeGB = [math]::Round($m.Capacity / 1GB, 2)
            $html += "<tr><td>Modulo</td><td>$sizeGB</td><td>$($m.Speed)</td><td>$($m.Manufacturer)</td></tr>`n"
        }
    } else {
        $html += "<tr><td colspan='4'>No se detectaron modulos de memoria</td></tr>`n"
    }

    $html += @"
  </table>
</div>

<div class='section'>
  <h2>Discos</h2>
  <table>
    <tr><th>Disco</th><th>Tamano (GB)</th><th>Libre (GB)</th><th>Estado</th></tr>
"@

    if ($disks) {
        foreach ($d in $disks) {
            $size = [math]::Round($d.Size / 1GB, 2)
            $free = [math]::Round($d.FreeSpace / 1GB, 2)
            $percentFree = if ($size -gt 0) { [math]::Round(($free / $size) * 100, 2) } else { 0 }
            $statusClass = if ($percentFree -lt 10) { 'status-bad' } elseif ($percentFree -lt 20) { 'status-warn' } else { 'status-good' }
            $html += "<tr><td>$($d.DeviceID)</td><td>$size</td><td>$free</td><td class='$statusClass'>$percentFree % libre</td></tr>`n"
        }
    } else {
        $html += "<tr><td colspan='4'>No se detectaron discos</td></tr>`n"
    }

    $html += @"
  </table>
</div>

<div class='section'>
  <h2>Red</h2>
  <table>
    <tr><th>Adaptador</th><th>Estado</th><th>MAC</th><th>IP</th></tr>
"@

    if ($nics) {
        foreach ($nic in $nics) {
            $ipAddr = ""
            try {
                $ipObj = Get-NetIPAddress -InterfaceIndex $nic.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($ipObj) { $ipAddr = $ipObj.IPAddress }
            } catch { $ipAddr = "" }
            $html += "<tr><td>$($nic.Name)</td><td>$($nic.Status)</td><td>$($nic.MacAddress)</td><td>$ipAddr</td></tr>`n"
        }
    } else {
        $html += "<tr><td colspan='4'>No se detectaron adaptadores de red activos</td></tr>`n"
    }

    $html += @"
  </table>
</div>

<div class='section'>
  <h2>Servicios detenidos</h2>
  <table>
    <tr><th>Nombre</th><th>DisplayName</th><th>Tipo inicio</th></tr>
"@

    if ($servicesStopped) {
        foreach ($s in $servicesStopped) {
            $html += "<tr><td>$($s.Name)</td><td>$($s.DisplayName)</td><td>$($s.StartType)</td></tr>`n"
        }
    } else {
        $html += "<tr><td colspan='3'>No se detectaron servicios detenidos importantes</td></tr>`n"
    }

    $html += @"
  </table>
</div>

<div class='section'>
  <h2>Eventos criticos (24h)</h2>
  <table>
    <tr><th>Fecha</th><th>ID</th><th>Fuente</th><th>Mensaje</th></tr>
"@

    if ($criticalEvents) {
        foreach ($e in $criticalEvents) {
            $msg = $e.Message -replace '[\r\n]+',' '
            $html += "<tr><td>$($e.TimeGenerated)</td><td>$($e.InstanceId)</td><td>$($e.Source)</td><td>$msg</td></tr>`n"
        }
    } else {
        $html += "<tr><td colspan='4'>No se encontraron eventos criticos en las ultimas 24 horas</td></tr>`n"
    }

    $html += @"
  </table>
</div>

<div class='section'>
  <h2>SALUD DEL SISTEMA - SEMAFORO DE ESTADO</h2>
"@

    # Calcular health score
    $healthScore = 100
    if ($disks) {
        Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            $freePercent = if ($_.Used -gt 0) { [math]::Round(($_.Free / $_.Used) * 100, 2) } else { 0 }
            if ($freePercent -lt 10) { $healthScore -= 20 }
            elseif ($freePercent -lt 20) { $healthScore -= 10 }
        }
    }

    $memPercent = 0
    if ($os) {
        try {
            $osInfo = Get-CimInstance Win32_OperatingSystem
            $totalMem = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
            $freeMem = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
            $usedMem = $totalMem - $freeMem
            $memPercent = if ($totalMem -gt 0) { [math]::Round(($usedMem / $totalMem) * 100, 2) } else { 0 }
        } catch { $memPercent = 0 }
    }

    if ($memPercent -gt 90) { $healthScore -= 15 } elseif ($memPercent -gt 80) { $healthScore -= 10 }
    $eventCount = if ($criticalEvents) { $criticalEvents.Count } else { 0 }
    if ($eventCount -gt 5) { $healthScore -= 15 } elseif ($eventCount -gt 0) { $healthScore -= 5 }
    $serviceCount = if ($servicesStopped) { $servicesStopped.Count } else { 0 }
    if ($serviceCount -gt 3) { $healthScore -= 10 } elseif ($serviceCount -gt 0) { $healthScore -= 5 }

    if ($healthScore -lt 0) { $healthScore = 0 }

    # Mostrar semaforo segun score
    $html += @"
  <div class='semaphore-container'>
"@

    if ($healthScore -ge 80) {
        $html += @"
    <div class='semaphore-circle semaphore-green'></div>
    <h3 style='color:#107c10; margin:10px 0;'>ESTADO OPTIMO (VERDE)</h3>
    <p>El sistema se encuentra en excelentes condiciones.</p>
"@
    } elseif ($healthScore -ge 60) {
        $html += @"
    <div class='semaphore-circle semaphore-yellow'></div>
    <h3 style='color:#d97706; margin:10px 0;'>MANTENIMIENTO RECOMENDADO (AMARILLO)</h3>
    <p>Se recomienda realizar mantenimiento preventivo.</p>
"@
    } else {
        $html += @"
    <div class='semaphore-circle semaphore-red'></div>
    <h3 style='color:#a80000; margin:10px 0;'>ATENCION INMEDIATA (ROJO)</h3>
    <p>El sistema requiere atencion y reparacion inmediata.</p>
"@
    }

    $html += @"
  </div>
  
  <table>
    <tr><th>Indicador</th><th>Valor</th><th>Estado</th></tr>
    <tr>
      <td>Puntuacion de salud</td>
      <td class='health-score'>$healthScore / 100</td>
      <td>
"@

    if ($healthScore -ge 80) {
        $html += "<span class='status-good'><span class='traffic-light traffic-green'></span> OPTIMO</span>"
    } elseif ($healthScore -ge 60) {
        $html += "<span class='status-warn'><span class='traffic-light traffic-yellow'></span> MANTENIMIENTO</span>"
    } else {
        $html += "<span class='status-bad'><span class='traffic-light traffic-red'></span> ATENCION</span>"
    }

    $html += @"
      </td>
    </tr>
    <tr>
      <td>Recomendacion</td>
      <td colspan='2' class='recommendation'>
"@

    if ($healthScore -ge 80) {
        $html += "Continue con mantenimiento preventivo regular.<br> El sistema funciona correctamente."
    } elseif ($healthScore -ge 60) {
        $html += "Ejecute reparaciones del sistema (menu 3).<br> Verifique espacio en disco y eventos criticos.<br> Considere limpieza de archivos temporales."
    } else {
        $html += "EJECUTE REPARACION COMPLETA DEL SISTEMA inmediatamente.<br> Verifique discos, memoria y eventos criticos.<br> Considere backup de datos importantes."
    }

    $html += @"
      </td>
    </tr>
  </table>
  
  <div class='legend'>
    <div class='legend-item'>
      <div class='traffic-light traffic-green' style='width:25px; height:25px;'></div>
      <small><strong>VERDE (80-100)</strong><br>Sistema optimo</small>
    </div>
    <div class='legend-item'>
      <div class='traffic-light traffic-yellow' style='width:25px; height:25px;'></div>
      <small><strong>AMARILLO (60-79)</strong><br>Mantenimiento recomendado</small>
    </div>
    <div class='legend-item'>
      <div class='traffic-light traffic-red' style='width:25px; height:25px;'></div>
      <small><strong>ROJO (0-59)</strong><br>Atencion inmediata</small>
    </div>
  </div>
</div>

<div class='footer'>
  Reporte generado por Sistema de Soporte Tecnico
</div>
</body>
</html>
"@

    # Guardar archivo
    try {
        $html | Out-File -FilePath $outPath -Encoding UTF8
        Write-Host "Informe guardado en: $outPath" -ForegroundColor Green
        Write-Log "Informe HTML generado: $outPath" "SUCCESS"
        # Abrir en navegador por defecto
        try { Start-Process $outPath } catch {}
    } catch {
        Write-Host "No se pudo guardar el informe: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error al guardar informe HTML: $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Show-DiagnosticsMenu, Test-*, Get-*, Test-*, Generate-SystemHtmlReport
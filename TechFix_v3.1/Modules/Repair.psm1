# ==========================================
# Repair.psm1
# Modulo: Reparacion del sistema
# ==========================================

function Show-RepairMenu {
    while ($true) {
		Clear-Host
        Show-TechFixLogo
        Show-Title "MENU - REPARACION DEL SISTEMA"
        
        if (-not (Test-AdminPrivileges)) {
            Write-Host "Todas las funciones requieren permisos de administrador" -ForegroundColor Yellow
            Write-Host ""
        }

        Write-Host "1) Reparar archivos del sistema (SFC)" -ForegroundColor White
        Write-Host "2) Reparar imagen de Windows (DISM)" -ForegroundColor White
        Write-Host "3) Reparar Windows Update" -ForegroundColor White
        Write-Host "4) Reparar servicios basicos" -ForegroundColor White
        Write-Host "5) Resetear cache de red" -ForegroundColor White
        Write-Host "6) Restaurar configuraciones predeterminadas" -ForegroundColor White
        Write-Host "7) Reparar discos (CHKDSK)" -ForegroundColor White
        Write-Host "8) Reparacion completa del sistema" -ForegroundColor White
        Write-Host "0) Volver al menu principal" -ForegroundColor Gray
        Write-Host ""

        $opc = Get-UserChoice "Ingrese una opcion"

        switch ($opc) {
            "1" { Repair-SFC }
            "2" { Repair-DISM }
            "3" { Repair-WindowsUpdate }
            "4" { Repair-Services }
            "5" { Reset-NetworkCache }
            "6" { Reset-DefaultSettings }
            "7" { Repair-Disks }
            "8" { Complete-SystemRepair }
            "0" { return }
            default {
                Write-Host "Opcion invalida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        Pause
    }
}

function Repair-SFC {
    Show-Title "REPARAR ARCHIVOS DEL SISTEMA (SFC /SCANNOW)"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador para SFC" -ForegroundColor Red
        return
    }
    
    Write-Host "SFC (System File Checker) verificara y reparara archivos del sistema danados." -ForegroundColor Cyan
    Write-Host "Este proceso puede tomar varios minutos. No cierre la ventana." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Ejecutando: sfc /scannow" -ForegroundColor Green
        Write-Host "Por favor espere..." -ForegroundColor Gray
        
        $result = sfc /scannow
        Write-Host $result -ForegroundColor White
        
        Write-Host "SFC completado." -ForegroundColor Green
        Write-Log "SFC /scannow ejecutado" "SUCCESS"
        
    } catch {
        Write-Host "Error al ejecutar SFC: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en SFC: $($_.Exception.Message)" "ERROR"
    }
}

function Repair-DISM {
    Show-Title "REPARAR IMAGEN DE WINDOWS (DISM)"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador para DISM" -ForegroundColor Red
        return
    }
    
    Write-Host "DISM (Deployment Image Servicing and Management) reparara la imagen de Windows." -ForegroundColor Cyan
    Write-Host "Este proceso es recomendado si SFC encuentra archivos corruptos." -ForegroundColor Yellow
    Write-Host "Puede tomar 10-30 minutos. Mantenga la conexion a internet." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Paso 1/3: Verificando salud de la imagen..." -ForegroundColor Cyan
        Write-Host "Ejecutando: DISM /Online /Cleanup-Image /CheckHealth" -ForegroundColor Gray
        $checkResult = DISM /Online /Cleanup-Image /CheckHealth
        Write-Host "Verificacion completada" -ForegroundColor Green
        
        Write-Host "`nPaso 2/3: Escaneando imagen..." -ForegroundColor Cyan
        Write-Host "Ejecutando: DISM /Online /Cleanup-Image /ScanHealth" -ForegroundColor Gray
        $scanResult = DISM /Online /Cleanup-Image /ScanHealth
        Write-Host "Escaneo completado" -ForegroundColor Green
        
        Write-Host "`nPaso 3/3: Reparando imagen..." -ForegroundColor Cyan
        Write-Host "Ejecutando: DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor Gray
        Write-Host "Esto puede tomar varios minutos..." -ForegroundColor Yellow
        
        $repairResult = DISM /Online /Cleanup-Image /RestoreHealth
        
        Write-Host "DISM completado exitosamente." -ForegroundColor Green
        Write-Log "DISM ejecutado exitosamente" "SUCCESS"
        
        Write-Host "`nRecomendacion: Ejecute 'Reparar archivos del sistema (SFC)' para completar la reparacion." -ForegroundColor Magenta
        
    } catch {
        Write-Host "Error al ejecutar DISM: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en DISM: $($_.Exception.Message)" "ERROR"
    }
}

function Repair-WindowsUpdate {
    Show-Title "REPARAR WINDOWS UPDATE"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "Este proceso reseteara los componentes de Windows Update." -ForegroundColor Cyan
    Write-Host "Se detendran servicios y se renombraran carpetas de cache." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Paso 1/4: Deteniendo servicios de Windows Update..." -ForegroundColor Cyan
        $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
        
        foreach ($service in $services) {
            Write-Host "  Deteniendo $service..." -ForegroundColor Gray
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Paso 2/4: Renombrando carpetas de cache..." -ForegroundColor Cyan
        $folders = @(
            @{Path = "C:\Windows\SoftwareDistribution"; NewName = "SoftwareDistribution.old"},
            @{Path = "C:\Windows\System32\catroot2"; NewName = "catroot2.old"}
        )
        
        foreach ($folder in $folders) {
            if (Test-Path $folder.Path) {
                Write-Host "  Renombrando $(Split-Path $folder.Path -Leaf)..." -ForegroundColor Gray
                Rename-Item -Path $folder.Path -NewName $folder.NewName -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "Paso 3/4: Reiniciando servicios..." -ForegroundColor Cyan
        foreach ($service in $services) {
            Write-Host "  Iniciando $service..." -ForegroundColor Gray
            Start-Service -Name $service -ErrorAction SilentlyContinue
        }
        
        Write-Host "Paso 4/4: Reconstruyendo componentes..." -ForegroundColor Cyan
        Write-Host "  Reinicializando componentes de Windows Update..." -ForegroundColor Gray
        
        Write-Host "Windows Update reparado exitosamente." -ForegroundColor Green
        Write-Host "Recomendacion: Reinicie el sistema y verifique Windows Update." -ForegroundColor Magenta
        Write-Log "Reparacion de Windows Update completada" "SUCCESS"
        
    } catch {
        Write-Host "Error al reparar Windows Update: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en reparacion Windows Update: $($_.Exception.Message)" "ERROR"
    }
}

function Repair-Services {
    Show-Title "REPARAR SERVICIOS BASICOS"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    $criticalServices = @(
        @{Name="wuauserv"; DisplayName="Windows Update"},
        @{Name="bits"; DisplayName="Background Intelligent Transfer"},
        @{Name="cryptsvc"; DisplayName="Cryptographic Services"},
        @{Name="msiserver"; DisplayName="Windows Installer"},
        @{Name="Dhcp"; DisplayName="DHCP Client"},
        @{Name="Dnscache"; DisplayName="DNS Client"},
        @{Name="LanmanWorkstation"; DisplayName="Workstation"},
        @{Name="LanmanServer"; DisplayName="Server"},
        @{Name="Themes"; DisplayName="Themes"},
        @{Name="AudioSrv"; DisplayName="Windows Audio"}
    )
    
    Write-Host "Reiniciando servicios criticos..." -ForegroundColor Cyan
    $restartedCount = 0
    
    foreach ($service in $criticalServices) {
        try {
            Write-Host "  Procesando $($service.DisplayName)..." -ForegroundColor Gray
            $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            
            if ($svc -and $svc.Status -eq "Running") {
                Restart-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                $restartedCount++
                Write-Host "    Reiniciado" -ForegroundColor Green
            } elseif ($svc -and $svc.Status -eq "Stopped") {
                Start-Service -Name $service.Name -ErrorAction SilentlyContinue
                $restartedCount++
                Write-Host "    Iniciado" -ForegroundColor Green
            }
        } catch {
            Write-Host "    No se pudo reiniciar" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nServicios reparados: $restartedCount de $($criticalServices.Count) servicios" -ForegroundColor Green
    Write-Log "Reparacion de servicios completada. Servicios reiniciados: $restartedCount" "SUCCESS"
}

function Reset-NetworkCache {
    Show-Title "RESETEO DE CACHE DE RED"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "Este proceso reseteara todas las configuraciones de red y cache." -ForegroundColor Cyan
    Write-Host "Se perderan configuraciones de red temporalmente." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Paso 1/5: Liberando configuraciones IP..." -ForegroundColor Cyan
        ipconfig /release 2>$null
        Write-Host "  IP liberada" -ForegroundColor Green

        Write-Host "Paso 2/5: Limpiando cache DNS..." -ForegroundColor Cyan
        ipconfig /flushdns 2>$null
        Write-Host "  Cache DNS limpiada" -ForegroundColor Green

        Write-Host "Paso 3/5: Registrando DNS..." -ForegroundColor Cyan
        ipconfig /registerdns 2>$null
        Write-Host "  DNS registrado" -ForegroundColor Green

        Write-Host "Paso 4/5: Reseteando Winsock..." -ForegroundColor Cyan
        netsh winsock reset 2>$null
        Write-Host "  Winsock reseteado" -ForegroundColor Green

        Write-Host "Paso 5/5: Reseteando TCP/IP..." -ForegroundColor Cyan
        netsh int ip reset 2>$null
        Write-Host "  TCP/IP reseteado" -ForegroundColor Green

        Write-Host "`nCache de red reseteada exitosamente." -ForegroundColor Green
        Write-Host "Recomendacion: Reinicie el sistema para completar la reparacion." -ForegroundColor Magenta
        Write-Log "Reseteo de cache de red completado" "SUCCESS"

    } catch {
        Write-Host "Error al resetear cache de red: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en reseteo de red: $($_.Exception.Message)" "ERROR"
    }
}

function Reset-DefaultSettings {
    Show-Title "RESTAURAR CONFIGURACIONES PREDETERMINADAS"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "Este proceso restaurara configuraciones del sistema a valores predeterminados." -ForegroundColor Cyan
    Write-Host "Afecta: Politicas de grupo, firewall, y configuraciones basicas." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Restaurando politicas de grupo..." -ForegroundColor Cyan
        gpupdate /force 2>$null
        Write-Host "  Politicas actualizadas" -ForegroundColor Green
        
        Write-Host "Restaurando firewall de Windows..." -ForegroundColor Cyan
        netsh advfirewall reset 2>$null
        Write-Host "  Firewall reseteado" -ForegroundColor Green
        
        Write-Host "Restaurando configuraciones de energia..." -ForegroundColor Cyan
        powercfg -restoredefaultschemes 2>$null
        Write-Host "  Configuraciones de energia restauradas" -ForegroundColor Green
        
        Write-Host "`nConfiguraciones predeterminadas restauradas." -ForegroundColor Green
        Write-Log "Configuraciones predeterminadas restauradas" "SUCCESS"
        
    } catch {
        Write-Host "Error al restaurar configuraciones: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error al restaurar configuraciones: $($_.Exception.Message)" "ERROR"
    }
}

function Repair-Disks {
    Show-Title "REPARACION DE DISCOS (CHKDSK)"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "CHKDSK verificara y reparara errores del sistema de archivos." -ForegroundColor Cyan
    Write-Host "ADVERTENCIA: Este proceso requiere reinicio y puede tomar mucho tiempo." -ForegroundColor Red
    Write-Host ""
    
    Write-Host "Unidades disponibles:" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Write-Host "  $($_.Name): $([math]::Round($_.Used / 1GB, 2)) GB usados" -ForegroundColor Cyan
    }
    Write-Host ""
    
    $drive = Read-Host "Ingrese la letra de la unidad a verificar (ej: C)"
    if (-not $drive) {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    $confirm = Read-Host "Ejecutar CHKDSK en unidad $drive? Esto reiniciara el sistema (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Programando CHKDSK para el proximo reinicio..." -ForegroundColor Cyan
        chkdsk $drive /f /r
        
        Write-Host "CHKDSK programado exitosamente." -ForegroundColor Green
        Write-Host "El proceso se ejecutara en el proximo reinicio del sistema." -ForegroundColor Magenta
        Write-Log "CHKDSK programado para unidad $drive en proximo reinicio" "SUCCESS"
        
    } catch {
        Write-Host "Error al programar CHKDSK: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error al programar CHKDSK: $($_.Exception.Message)" "ERROR"
    }
}

function Complete-SystemRepair {
    Show-Title "REPARACION COMPLETA DEL SISTEMA"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "Este proceso ejecutara una reparacion completa del sistema en modo automatizado." -ForegroundColor Cyan
    Write-Host "Incluye: DISM, SFC, Windows Update, servicios, y red." -ForegroundColor Yellow
    Write-Host "ADVERTENCIA: Puede tomar 30-60 minutos. No interrumpa el proceso." -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Iniciando reparacion completa..." -ForegroundColor Green
        Write-Host ""
        
        # 1. DISM
        Write-Host "Fase 1/5: Reparando imagen de Windows (DISM)..." -ForegroundColor Cyan
        Repair-DISM
        
        # 2. SFC
        Write-Host "Fase 2/5: Verificando archivos del sistema (SFC)..." -ForegroundColor Cyan
        Repair-SFC
        
        # 3. Windows Update
        Write-Host "Fase 3/5: Reparando Windows Update..." -ForegroundColor Cyan
        Repair-WindowsUpdate
        
        # 4. Servicios
        Write-Host "Fase 4/5: Reiniciando servicios criticos..." -ForegroundColor Cyan
        Repair-Services
        
        # 5. Red
        Write-Host "Fase 5/5: Reseteando configuraciones de red..." -ForegroundColor Cyan
        Reset-NetworkCache
        
        Write-Host "`nREPARACION COMPLETA FINALIZADA" -ForegroundColor Green
        Write-Host "Recomendacion: Reinicie el sistema para aplicar todos los cambios." -ForegroundColor Magenta
        Write-Log "Reparacion completa del sistema ejecutada exitosamente" "SUCCESS"
        
    } catch {
        Write-Host "Error en reparacion completa: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en reparacion completa: $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Show-RepairMenu, Repair-*, Reset-*, Complete-*
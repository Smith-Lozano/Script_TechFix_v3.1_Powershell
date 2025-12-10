# ==========================================
# Maintenance.psm1
# Modulo: Limpieza y Mantenimiento
# ==========================================

function Show-MaintenanceMenu {
    while ($true) {
		Clear-Host
        Show-TechFixLogo
        Show-Title "MENU - LIMPIEZA Y MANTENIMIENTO"
        
        if (-not (Test-AdminPrivileges)) {
            Write-Host "Algunas funciones requieren permisos de administrador" -ForegroundColor Yellow
            Write-Host ""
        }

        Write-Host "1) Limpiar Temp del sistema" -ForegroundColor White
        Write-Host "2) Limpiar %temp% del usuario" -ForegroundColor White
        Write-Host "3) Limpiar Prefetch" -ForegroundColor White
        Write-Host "4) Limpiar caches basicas" -ForegroundColor White
        Write-Host "5) Limpiar logs del sistema" -ForegroundColor White
        Write-Host "6) Limpiar Papelera de Reciclaje" -ForegroundColor White
        Write-Host "7) Limpiar cache del navegador" -ForegroundColor White
        Write-Host "8) Desfragmentar disco" -ForegroundColor White
        Write-Host "9) Ejecutar liberador de espacio" -ForegroundColor White
        Write-Host "0) Volver al menu principal" -ForegroundColor Gray
        Write-Host ""

        $opc = Get-UserChoice "Ingrese una opcion"

        switch ($opc) {
            "1" { Clean-Temp }
            "2" { Clean-UserTemp }
            "3" { Clean-Prefetch }
            "4" { Clean-Cache }
            "5" { Clean-SystemLogs }
            "6" { Clean-RecycleBin }
            "7" { Clean-BrowserCache }
            "8" { Defrag-Drive }
            "9" { Run-DiskCleanup }
            "0" { return }
            default {
                Write-Host "Opcion invalida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        Pause
    }
}

function Clean-Temp {
    Show-Title "LIMPIAR TEMP DEL SISTEMA"
    
    $paths = @("C:\Windows\Temp", "C:\Temp")
    $totalFreed = 0
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Limpiando: $path" -ForegroundColor Cyan
            try {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                $before = ($items | Measure-Object -Property Length -Sum).Sum / 1MB
                
                $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
                $afterItems = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                $after = ($afterItems | Measure-Object -Property Length -Sum).Sum / 1MB
                
                $freed = [math]::Round(($before - $after), 2)
                $totalFreed += $freed
                
                Write-Host "Liberados: $freed MB" -ForegroundColor Green
            } catch {
                Write-Host "No se pudo limpiar completamente $path" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Ruta no encontrada: $path" -ForegroundColor Gray
        }
    }
    
    Write-Log "Limpieza de Temp del sistema completada. Liberados: $totalFreed MB" "SUCCESS"
}

function Clean-UserTemp {
    Show-Title "LIMPIAR %TEMP% DEL USUARIO"
    
    $paths = @($env:TEMP, "$env:LOCALAPPDATA\Temp")
    $totalFreed = 0
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Limpiando: $path" -ForegroundColor Cyan
            try {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                $before = ($items | Measure-Object -Property Length -Sum).Sum / 1MB
                
                $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
                $afterItems = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                $after = ($afterItems | Measure-Object -Property Length -Sum).Sum / 1MB
                
                $freed = [math]::Round(($before - $after), 2)
                $totalFreed += $freed
                
                Write-Host "Liberados: $freed MB" -ForegroundColor Green
            } catch {
                Write-Host "Algunos archivos estaban en uso" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Log "Limpieza de Temp de usuario completada. Liberados: $totalFreed MB" "SUCCESS"
}

function Clean-Prefetch {
    Show-Title "LIMPIAR PREFETCH"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    $path = "C:\Windows\Prefetch"
    if (Test-Path $path) {
        Write-Host "Limpiando Prefetch..." -ForegroundColor Cyan
        try {
            $items = Get-ChildItem $path -Filter "*.pf" -ErrorAction SilentlyContinue
            $before = ($items | Measure-Object -Property Length -Sum).Sum / 1MB
            
            $items | Remove-Item -Force -ErrorAction SilentlyContinue
            
            $afterItems = Get-ChildItem $path -Filter "*.pf" -ErrorAction SilentlyContinue
            $after = ($afterItems | Measure-Object -Property Length -Sum).Sum / 1MB
            
            $freed = [math]::Round(($before - $after), 2)
            Write-Host "Prefetch limpiado. Liberados: $freed MB" -ForegroundColor Green
            Write-Log "Limpieza de Prefetch completada. Liberados: $freed MB" "SUCCESS"
        } catch {
            Write-Host "Error al limpiar Prefetch" -ForegroundColor Red
            Write-Log "Error al limpiar Prefetch: $($_.Exception.Message)" "ERROR"
        }
    }
}

function Clean-Cache {
    Show-Title "LIMPIEZA DE CACHES BASICAS"
    
    $cachePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
        "$env:APPDATA\Microsoft\Windows\Recent",
        "$env:LOCALAPPDATA\Microsoft\Windows\History"
    )
    
    $totalFreed = 0
    
    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            Write-Host "Limpiando: $(Split-Path $path -Leaf)" -ForegroundColor Cyan
            try {
                # Obtener solo archivos con propiedad Length (evitar errores)
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $false -and $_.Length -gt 0 }
                
                if ($items) {
                    $before = ($items | Measure-Object -Property Length -Sum).Sum / 1MB
                    
                    # Eliminar archivos de forma segura
                    $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    
                    # Calcular espacio liberado
                    $afterItems = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $false -and $_.Length -gt 0 }
                    $after = if ($afterItems) { ($afterItems | Measure-Object -Property Length -Sum).Sum / 1MB } else { 0 }
                    
                    $freed = [math]::Round(($before - $after), 2)
                    $totalFreed += $freed
                    
                    Write-Host "Liberados: $freed MB" -ForegroundColor Green
                } else {
                    Write-Host "No se encontraron archivos para limpiar" -ForegroundColor Gray
                }
            } catch {
                Write-Host "No se pudo limpiar completamente" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Ruta no encontrada: $(Split-Path $path -Leaf)" -ForegroundColor Gray
        }
    }
    
    Write-Log "Limpieza de caches completada. Liberados: $totalFreed MB" "SUCCESS"
}

function Clean-SystemLogs {
    Show-Title "LIMPIAR LOGS DEL SISTEMA"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "Limpiando logs de eventos..." -ForegroundColor Cyan
    try {
        $logs = wevtutil el
        $clearedCount = 0
        
        foreach ($log in $logs) {
            try {
                wevtutil cl $log 2>$null
                $clearedCount++
            } catch {
                # Ignorar logs que no se pueden limpiar
            }
        }
        
        Write-Host "Logs limpiados: $clearedCount de $($logs.Count) logs" -ForegroundColor Green
        Write-Log "Limpieza de logs del sistema completada. Logs limpiados: $clearedCount" "SUCCESS"
    } catch {
        Write-Host "Error al limpiar logs" -ForegroundColor Red
        Write-Log "Error al limpiar logs: $($_.Exception.Message)" "ERROR"
    }
}

function Clean-RecycleBin {
    Show-Title "LIMPIAR PAPELERA DE RECICLAJE"
    
    Write-Host "Vaciando papelera de reciclaje..." -ForegroundColor Cyan
    try {
        $result = Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "Papelera vaciada correctamente" -ForegroundColor Green
        Write-Log "Papelera de reciclaje vaciada" "SUCCESS"
    } catch {
        Write-Host "Error al vaciar la papelera" -ForegroundColor Red
        Write-Log "Error al vaciar papelera: $($_.Exception.Message)" "ERROR"
    }
}

function Clean-BrowserCache {
    Show-Title "LIMPIAR CACHE DEL NAVEGADOR"
    
    $browserPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    )
    
    $totalFreed = 0
    
    foreach ($path in $browserPaths) {
        if (Test-Path $path) {
            Write-Host "Limpiando: $(Split-Path $path -Leaf)" -ForegroundColor Cyan
            try {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                $before = ($items | Measure-Object -Property Length -Sum).Sum / 1MB
                
                $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
                $afterItems = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                $after = ($afterItems | Measure-Object -Property Length -Sum).Sum / 1MB
                
                $freed = [math]::Round(($before - $after), 2)
                $totalFreed += $freed
                
                Write-Host "Liberados: $freed MB" -ForegroundColor Green
            } catch {
                Write-Host "No se pudo limpiar completamente" -ForegroundColor Yellow
            }
        }
    }
    
    if ($totalFreed -gt 0) {
        Write-Log "Limpieza de cache de navegadores completada. Liberados: $totalFreed MB" "SUCCESS"
    } else {
        Write-Host "No se encontraron caches de navegadores para limpiar" -ForegroundColor Yellow
    }
}

function Defrag-Drive {
    Show-Title "DESFRAGMENTACION DE DISCOS"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }
    
    Write-Host "Unidades disponibles:" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Write-Host "  $($_.Name): $([math]::Round($_.Used / 1GB, 2)) GB usados" -ForegroundColor Cyan
    }
    
    Write-Host ""
    $drive = Read-Host "Ingrese la letra de la unidad a desfragmentar (ej: C) o Enter para todas"
    
    try {
        if ($drive -eq "") {
            Write-Host "Iniciando desfragmentacion de todas las unidades..." -ForegroundColor Cyan
            Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
                if ($_.DriveLetter) {
                    Write-Host "Desfragmentando unidad $($_.DriveLetter)..." -ForegroundColor Gray
                    Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
                }
            }
            Write-Host "Desfragmentacion completada" -ForegroundColor Green
        } else {
            Write-Host "Desfragmentando unidad $drive..." -ForegroundColor Cyan
            Optimize-Volume -DriveLetter $drive -Defrag -Verbose
            Write-Host "Unidad $drive desfragmentada" -ForegroundColor Green
        }
        Write-Log "Desfragmentacion completada" "SUCCESS"
    } catch {
        Write-Host "Error en desfragmentacion: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en desfragmentacion: $($_.Exception.Message)" "ERROR"
    }
}

function Run-DiskCleanup {
    Show-Title "LIBERADOR DE ESPACIO EN DISCO"
    
    Write-Host "Iniciando Liberador de Espacio de Windows..." -ForegroundColor Cyan
    try {
        Start-Process cleanmgr.exe
        Write-Host "Liberador de espacio ejecutado correctamente" -ForegroundColor Green
        Write-Log "Liberador de espacio (cleanmgr) ejecutado" "SUCCESS"
    } catch {
        Write-Host "Error al ejecutar cleanmgr" -ForegroundColor Red
        Write-Log "Error al ejecutar cleanmgr: $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Show-MaintenanceMenu, Clean-*, Defrag-*, Run-*
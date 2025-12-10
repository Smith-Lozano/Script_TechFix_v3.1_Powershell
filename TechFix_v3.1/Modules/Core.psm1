# ==========================================
# Core.psm1
# Funciones base del sistema de soporte
# ==========================================

function Clear-Screen {
    Clear-Host
}

function Show-Title {
    param([string]$Text)
    Clear-Screen
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "$Text" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
}

function Pause {
    Write-Host ""
    Write-Host "Presione ENTER para continuar..." -ForegroundColor Gray -NoNewline
    $null = Read-Host
}

function Get-UserChoice {
    param([string]$Message = "Seleccione una opcion")
    Write-Host ""
    Write-Host "$Message : " -ForegroundColor Cyan -NoNewline
    $opc = Read-Host
    return $opc.Trim()
}

function Show-Welcome {
    Show-Title "SISTEMA DE SOPORTE TECNICO - PC MAINTENANCE"
    Write-Host "Version: 3.1" -ForegroundColor Green
    Write-Host "Modulos cargados: Core, Info, Maintenance, Repair, Network, Diagnostics" -ForegroundColor Green
    Write-Host "Estado: OK Sistema listo" -ForegroundColor Green
    Write-Host ""
    Write-Host "Desarrollado para mantenimiento y diagnostico de sistemas Windows" -ForegroundColor Gray
    Write-Host ""
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-AdminWarning {
    if (-not (Test-AdminPrivileges)) {
        Write-Host "ADVERTENCIA: Algunas funciones requieren permisos de administrador" -ForegroundColor Yellow
        Write-Host "   Ejecute el script como administrador para acceso completo" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Write-Log {
    param(
        [string]$Message, 
        [string]$Type = "INFO"
    )
    
    # ==========================================
    # LOG EN TEMP
    # ==========================================
    
    # 1. Usar TEMP del sistema
    $tempDir = $env:TEMP
    $logDir = Join-Path $tempDir "TechFix_Logs"
    
    # 2. Crear carpeta si no existe (silencio)
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # 3. Archivo de log ÚNICO por ejecución
    $logFile = "TechFix.log"  # Un solo archivo, siempre el mismo
    $logPath = Join-Path $logDir $logFile
    
    # 4. Crear entrada de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    
    # 5. Escribir en archivo (APPEND)
    try {
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    } catch {
        # Si falla, solo mostrar en pantalla
        Write-Host "[ERROR-LOG] No se pudo escribir en log" -ForegroundColor Red
    }
    
    # 6. Mostrar en consola (opcional)
    switch ($Type) {
        "ERROR"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        default   { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

# ==========================================
# Menu Principal
# ==========================================

function Show-MainMenu {
    while ($true) {
        Clear-Host
        Show-TechFixLogo
        Show-MenuTitle "MENU PRINCIPAL"
        Show-AdminWarning
        
        Write-Host "1) Informacion del sistema" -ForegroundColor White
        Write-Host "2) Limpieza y mantenimiento" -ForegroundColor White
        Write-Host "3) Reparacion del sistema" -ForegroundColor White
        Write-Host "4) Herramientas de red" -ForegroundColor White
        Write-Host "5) Diagnosticos avanzados" -ForegroundColor White
        Write-Host "6) Ver log de actividades" -ForegroundColor White
        Write-Host "0) Salir" -ForegroundColor Red
        Write-Host ""

        $opc = Get-UserChoice "Ingrese una opcion"

        switch ($opc) {
            "1" { 
                Write-Log "Usuario accedio a Informacion del sistema" "INFO"
                if (Get-Command -Name "Show-InfoMenu" -ErrorAction SilentlyContinue) {
                    Show-InfoMenu 
                } else {
                    Write-Host "Modulo de Informacion no disponible" -ForegroundColor Red
                    Pause
                }
            }
            "2" { 
                Write-Log "Usuario accedio a Limpieza y mantenimiento" "INFO"
                if (Get-Command -Name "Show-MaintenanceMenu" -ErrorAction SilentlyContinue) {
                    Show-MaintenanceMenu 
                } else {
                    Write-Host "Modulo de Mantenimiento no disponible" -ForegroundColor Red
                    Pause
                }
            }
            "3" { 
                Write-Log "Usuario accedio a Reparacion del sistema" "INFO"
                if (Get-Command -Name "Show-RepairMenu" -ErrorAction SilentlyContinue) {
                    Show-RepairMenu 
                } else {
                    Write-Host "Modulo de Reparacion no disponible" -ForegroundColor Red
                    Pause
                }
            }
            "4" { 
                Write-Log "Usuario accedio a Herramientas de red" "INFO"
                if (Get-Command -Name "Show-NetworkMenu" -ErrorAction SilentlyContinue) {
                    Show-NetworkMenu 
                } else {
                    Write-Host "Modulo de Red no disponible" -ForegroundColor Red
                    Pause
                }
            }
            "5" { 
                Write-Log "Usuario accedio a Diagnosticos avanzados" "INFO"
                if (Get-Command -Name "Show-DiagnosticsMenu" -ErrorAction SilentlyContinue) {
                    Show-DiagnosticsMenu 
                } else {
                    Write-Host "Modulo de Diagnosticos no disponible" -ForegroundColor Red
                    Pause
                }
            }
            "6" { 
                Show-ActivityLog 
            }
            "0" { 
                Write-Log "Usuario salio del sistema" "INFO"
                Clear-Host
                Show-TechFixLogo
                Write-Host ""
                Write-Host "Saliendo del sistema de soporte..." -ForegroundColor Yellow
                Write-Host "Hasta pronto!" -ForegroundColor Green
                Start-Sleep -Seconds 2
                return
            }
            default {
                Write-Log "Opcion invalida seleccionada: $opc" "WARNING"
                Write-Host "Opcion invalida. Intente nuevamente." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Show-ActivityLog {
    Show-Title "LOG DE ACTIVIDADES (CARPETA TEMP)"
    
    # ==========================================
    # MOSTRAR LOG DESDE TEMP
    # ==========================================
    
    # Ruta del log en TEMP
    $logPath = Join-Path $env:TEMP "TechFix_Logs\TechFix.log"
    
    Write-Host "Ubicacion del log: $logPath" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $logPath) {
        Write-Host "=== ULTIMAS ENTRADAS DEL LOG ===" -ForegroundColor Yellow
        Write-Host ""
        
        try {
            # Leer últimas 100 líneas (o todo si es menos)
            $lines = Get-Content $logPath -ErrorAction Stop
            $startLine = [math]::Max(0, $lines.Count - 100)
            
            for ($i = $startLine; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                
                # Colores según tipo
                if ($line -match "\[ERROR\]") {
                    Write-Host $line -ForegroundColor Red
                } elseif ($line -match "\[WARNING\]") {
                    Write-Host $line -ForegroundColor Yellow
                } elseif ($line -match "\[SUCCESS\]") {
                    Write-Host $line -ForegroundColor Green
                } else {
                    Write-Host $line -ForegroundColor Gray
                }
            }
            
            Write-Host ""
            Write-Host "=== RESUMEN ===" -ForegroundColor Yellow
            Write-Host "Total de lineas en log: $($lines.Count)" -ForegroundColor White
            Write-Host "Mostrando ultimas: $([math]::Min(100, $lines.Count)) lineas" -ForegroundColor White
            
        } catch {
            Write-Host "Error leyendo el log: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "No hay archivo de log todavia." -ForegroundColor Yellow
        Write-Host "Se creara al ejecutar funciones del sistema." -ForegroundColor Gray
    }
    
    Write-Host ""
    $openFolder = Read-Host "Abrir carpeta de logs en TEMP? (S/N)"
    if ($openFolder -match '^[Ss]') {
        $logDir = Split-Path $logPath -Parent
        if (Test-Path $logDir) {
            explorer.exe $logDir
        } else {
            explorer.exe $env:TEMP
        }
    }
    
    Pause
}

# ==========================================
# Mostrar arte ASCII TechFix
# ==========================================
function Show-TechFixLogo {
    Write-Host ""
	Write-Host '**************************************************************************************************'-ForegroundColor Cyan
	Write-Host ""
    Write-Host '$$$$$$$$                   $$        $$$$$$$$  $$                              $$$$$$        $$'   -ForegroundColor Yellow 
    Write-Host '   $$                      $$        $$                                       $$    $$     $$$$'   -ForegroundColor Yellow  
    Write-Host '   $$   $$$$$$    $$$$$$$  $$$$$$$   $$        $$  $$    $$        $$     $$        $$       $$'   -ForegroundColor Yellow  
    Write-Host '   $$  $$    $$  $$        $$    $$  $$$$$     $$   $$  $$          $$   $$     $$$$$        $$'   -ForegroundColor Yellow  
    Write-Host '   $$  $$$$$$$$  $$        $$    $$  $$        $$    $$$$            $$ $$          $$       $$'   -ForegroundColor Yellow  
    Write-Host '   $$  $$        $$        $$    $$  $$        $$   $$  $$            $$$     $$    $$       $$'   -ForegroundColor Yellow  
    Write-Host '   $$   $$$$$$$   $$$$$$$  $$    $$  $$        $$  $$    $$            $       $$$$$$  $$  $$$$$$' -ForegroundColor Yellow
	Write-Host ""
	Write-Host '**************************************************************************************************'-ForegroundColor Cyan
    Write-Host '          Herramienta Integral de Diagnostico, Mantenimiento y Reparacion de Sistemas'             -ForegroundColor Yellow
	Write-Host '                               Windows 10/11/Server 2016,2019,2022'                                -ForegroundColor Yellow
    Write-Host ""
    Write-Host '                                         by Smith Lozano'                                          -ForegroundColor Cyan
    Write-Host '                                              2025'                                                -ForegroundColor Green
    Write-Host ""
}

# ==========================================
# Función para mostrar título
# ==========================================
function Show-MenuTitle {
    param([string]$Text)
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}


Export-ModuleMember -Function Show-*, Get-*, Clear-*, Pause, Test-*, Write-Log, Show-TechFixLogo, Show-MenuTitle
# ==========================================
# SoportePC.ps1
# Sistema de Soporte Tecnico - Punto de Entrada
# ==========================================

# ==========================================
# Auto-elevacion a administrador
# ==========================================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Reiniciando el script con privilegios de administrador..." -ForegroundColor Yellow

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"

    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        exit
    }
    catch {
        Write-Host "No se otorgaron permisos de administrador." -ForegroundColor Red
        exit
    }
}

# ==========================================
# Configuracion inicial
# ==========================================
$ScriptVersion = "3.1"
$ExecutionPolicyBypass = $false

# Verificar y configurar politica de ejecucion
function Test-ExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    if ($currentPolicy -eq "Restricted") {
        Write-Host "Configurando politica de ejecucion..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
            $script:ExecutionPolicyBypass = $true
            Write-Host "Politica de ejecucion configurada temporalmente" -ForegroundColor Green
        } catch {
            Write-Host "No se pudo configurar la politica de ejecucion" -ForegroundColor Red
            Write-Host "Ejecute como administrador o configure manualmente:" -ForegroundColor Yellow
            Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
            return $false
        }
    }
    return $true
}

# Importar modulos
function Import-SupportModules {
    Write-Host "Cargando modulos del sistema..." -ForegroundColor Cyan
    
    $modulePath = Join-Path $PSScriptRoot "Modules"
    
    if (-not (Test-Path $modulePath)) {
        Write-Host "No se encuentra la carpeta Modules" -ForegroundColor Red
        Write-Host "Asegurese de que la estructura de archivos es correcta" -ForegroundColor Yellow
        return $false
    }

    $modules = @(
        "Core.psm1",
        "Info.psm1", 
        "Maintenance.psm1",
        "Repair.psm1",
        "Network.psm1",
        "Diagnostics.psm1"
    )

    $loadedModules = 0
    $failedModules = 0

    foreach ($module in $modules) {
        $moduleFullPath = Join-Path $modulePath $module
        
        if (Test-Path $moduleFullPath) {
            try {
                $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
                Remove-Module -Name $moduleName -ErrorAction SilentlyContinue
                
                Import-Module $moduleFullPath -Force -ErrorAction Stop
                $loadedModules++
                Write-Host "   OK  $moduleName" -ForegroundColor Green
            }
            catch {
                $failedModules++
                Write-Host "   ERROR $module - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            $failedModules++
            Write-Host "   ERROR $module - No encontrado" -ForegroundColor Red
        }
    }

    Write-Host "`nResumen: $loadedModules modulos cargados, $failedModules fallos" -ForegroundColor Cyan
    
    if ($failedModules -eq 0) {
        Write-Host "Todos los modulos cargados correctamente" -ForegroundColor Green
        return $true
    } elseif ($loadedModules -gt 0) {
        Write-Host "Algunos modulos no se cargaron, pero el sistema puede funcionar" -ForegroundColor Yellow
        return $true
    } else {
        Write-Host "No se pudieron cargar los modulos necesarios" -ForegroundColor Red
        return $false
    }
}

# Mostrar informacion del sistema
function Show-SystemInfo {
    Write-Host "`n=== INFORMACION DEL SISTEMA ===" -ForegroundColor Yellow
    Write-Host "Script: SoportePC v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "Ejecutando como: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor Cyan
    Write-Host "Directorio: $PSScriptRoot" -ForegroundColor Cyan
    
    if (Test-AdminPrivileges) {
        Write-Host "Permisos: Administrador" -ForegroundColor Green
    } else {
        Write-Host "Permisos: Usuario estandar" -ForegroundColor Yellow
    }
}

# Funcion principal de inicio
function Start-SupportSystem {
    Clear-Host
    
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "          SCRIPT DE SOPORTE TECNICO PC - by Smith Lozano" -ForegroundColor Yellow
    Write-Host "                 Version $ScriptVersion" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-ExecutionPolicy)) {
        Write-Host "`nPresione cualquier tecla para salir..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    if (-not (Import-SupportModules)) {
        Write-Host "`nPresione cualquier tecla para salir..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Show-SystemInfo
    
    try {
        if (Get-Command -Name "Show-Welcome" -ErrorAction SilentlyContinue) {
            Show-Welcome
        }
        
        if (Get-Command -Name "Show-MainMenu" -ErrorAction SilentlyContinue) {
            Write-Log "Sistema de soporte iniciado correctamente" "SUCCESS"
            Show-MainMenu
        } else {
            throw "No se encuentra la funcion Show-MainMenu"
        }
    }
    catch {
        Write-Host "Error al iniciar el sistema: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPresione cualquier tecla para salir..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Cierre del sistema
function Stop-SupportSystem {
    Write-Host "`nCerrando sistema de soporte..." -ForegroundColor Cyan
    
    if ($ExecutionPolicyBypass) {
        Write-Host "Restaurando politica de ejecucion..." -ForegroundColor Yellow
        Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope Process -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "Sistema de soporte cerrado" "INFO"
    Write-Host "Hasta pronto!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# Manejar Ctrl+C
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-SupportSystem
}

# Punto de entrada principal
try {
    Start-SupportSystem
}
catch {
    Write-Host "Error critico: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
finally {
    Stop-SupportSystem
}

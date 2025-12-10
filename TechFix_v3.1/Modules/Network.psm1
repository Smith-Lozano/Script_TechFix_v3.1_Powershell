# ==========================================
# Network.psm1
# Modulo: Herramientas de red
# ==========================================

function Show-NetworkMenu {
    while ($true) {
		Clear-Host
        Show-TechFixLogo
        Show-Title "MENU - HERRAMIENTAS DE RED"
        
        if (-not (Test-AdminPrivileges)) {
            Write-Host "Algunas funciones requieren permisos de administrador" -ForegroundColor Yellow
            Write-Host ""
        }

        Write-Host "1) Informacion detallada de red" -ForegroundColor White
        Write-Host "2) Reiniciar adaptadores de red" -ForegroundColor White
        Write-Host "3) Test de conectividad" -ForegroundColor White
        Write-Host "4) Reparar stack de red" -ForegroundColor White
        Write-Host "5) Ver estadisticas de red" -ForegroundColor White
        Write-Host "6) Escanear puertos locales" -ForegroundColor White
        Write-Host "7) Diagnostico de DNS" -ForegroundColor White
        Write-Host "8) Informacion de conexiones activas" -ForegroundColor White
        Write-Host "9) Optimizar configuracion de red" -ForegroundColor White
        Write-Host "0) Volver al menu principal" -ForegroundColor Gray
        Write-Host ""

        $opc = Get-UserChoice "Ingrese una opcion"

        switch ($opc) {
            "1" { Get-DetailedNetworkInfo }
            "2" { Restart-NetworkAdapters }
            "3" { Test-NetworkConnectivity }
            "4" { Repair-NetworkStack }
            "5" { Get-NetworkStatistics }
            "6" { Scan-LocalPorts }
            "7" { Test-DNSResolution }
            "8" { Get-ActiveConnections }
            "9" { Optimize-NetworkSettings }
            "0" { return }
            default {
                Write-Host "Opcion invalida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        Pause
    }
}

function Get-DetailedNetworkInfo {
    Show-Title "INFORMACION DETALLADA DE RED"

    try {
        Write-Host "=== ADAPTADORES DE RED ACTIVOS ===" -ForegroundColor Yellow
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        
        if (-not $adapters) {
            Write-Host "No se encontraron adaptadores de red activos" -ForegroundColor Red
            return
        }

        foreach ($adapter in $adapters) {
            Write-Host "`n$($adapter.Name)" -ForegroundColor Cyan
            Write-Host "   Estado: $($adapter.Status)" -ForegroundColor $(if($adapter.Status -eq 'Up'){'Green'}else{'Red'})
            Write-Host "   Velocidad: $($adapter.LinkSpeed)" -ForegroundColor White
            Write-Host "   MAC: $($adapter.MacAddress)" -ForegroundColor White
            Write-Host "   Interface: $($adapter.InterfaceDescription)" -ForegroundColor White

            # Información IP
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($ipConfig) {
                Write-Host "   IPv4: $($ipConfig.IPAddress)/$($ipConfig.PrefixLength)" -ForegroundColor Green
            }

            $ipv6Config = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue
            if ($ipv6Config) {
                Write-Host "   IPv6: $($ipv6Config.IPAddress)" -ForegroundColor Green
            }

            # Gateway por defecto
            $gateway = Get-NetRoute -InterfaceIndex $adapter.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
            if ($gateway) {
                Write-Host "   Gateway: $($gateway.NextHop)" -ForegroundColor Magenta
            }

            # DNS Servers
            $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
            if ($dnsServers -and $dnsServers.ServerAddresses) {
                Write-Host "   DNS: $($dnsServers.ServerAddresses -join ', ')" -ForegroundColor Magenta
            }
        }

        Write-Host "`n=== CONECTIVIDAD INTERNET ===" -ForegroundColor Yellow
        Test-NetworkConnectivity -Quick

    } catch {
        Write-Host "Error al obtener informacion de red: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en Get-DetailedNetworkInfo: $($_.Exception.Message)" "ERROR"
    }
}

function Restart-NetworkAdapters {
    Show-Title "REINICIAR ADAPTADORES DE RED"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }

    try {
        Write-Host "Adaptadores de red encontrados:" -ForegroundColor Yellow
        $adapters = Get-NetAdapter | Select-Object Name, Status, InterfaceDescription
        $adapters | Format-Table -AutoSize

        Write-Host ""
        $confirm = Read-Host "Reiniciar todos los adaptadores de red? (S/N)"
        if ($confirm -notmatch '^[Ss]') {
            Write-Host "Operacion cancelada." -ForegroundColor Yellow
            return
        }

        Write-Host "Reiniciando adaptadores de red..." -ForegroundColor Cyan
        $restartedCount = 0
        
        foreach ($adapter in $adapters) {
            try {
                Write-Host "  Reiniciando $($adapter.Name)..." -ForegroundColor Gray
                Restart-NetAdapter -Name $adapter.Name -Confirm:$false
                $restartedCount++
                Write-Host "    Reiniciado" -ForegroundColor Green
            } catch {
                Write-Host "    No se pudo reiniciar $($adapter.Name)" -ForegroundColor Yellow
            }
        }

        Write-Host "`nAdaptadores reiniciados: $restartedCount de $($adapters.Count)" -ForegroundColor Green
        Write-Host "Los adaptadores pueden tomar unos segundos en reconectarse." -ForegroundColor Magenta
        Write-Log "Adaptadores de red reiniciados: $restartedCount" "SUCCESS"

    } catch {
        Write-Host "Error al reiniciar adaptadores: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error al reiniciar adaptadores: $($_.Exception.Message)" "ERROR"
    }
}

function Test-NetworkConnectivity {
    param([switch]$Quick)
    
    if (-not $Quick) {
        Show-Title "TEST DE CONECTIVIDAD DE RED"
    }

    try {
        $testHosts = @(
            @{Name="Google DNS"; Address="8.8.8.8"},
            @{Name="Cloudflare DNS"; Address="1.1.1.1"},
            @{Name="Router Local"; Address="192.168.1.1"},
            @{Name="Google.com"; Address="google.com"}
        )

        $results = @()
        
        foreach ($host in $testHosts) {
            Write-Host "Probando $($host.Name) ($($host.Address))..." -ForegroundColor Cyan -NoNewline
            
            try {
                $pingResult = Test-Connection -ComputerName $host.Address -Count 2 -Quiet -ErrorAction Stop
                
                if ($pingResult) {
                    Write-Host " CONECTADO" -ForegroundColor Green
                    $results += @{Host=$host.Name; Status="Conectado"; Color="Green"}
                } else {
                    Write-Host " SIN CONEXION" -ForegroundColor Red
                    $results += @{Host=$host.Name; Status="Sin conexion"; Color="Red"}
                }
            } catch {
                Write-Host " ERROR" -ForegroundColor Red
                $results += @{Host=$host.Name; Status="Error"; Color="Red"}
            }
        }

        # Resumen
        if (-not $Quick) {
            Write-Host "`n=== RESUMEN DE CONECTIVIDAD ===" -ForegroundColor Yellow
            $connectedCount = ($results | Where-Object { $_.Status -eq "Conectado" }).Count
            $totalCount = $results.Count
            
            Write-Host "Conectados: $connectedCount/$totalCount" -ForegroundColor $(if($connectedCount -eq $totalCount){'Green'}elseif($connectedCount -gt 0){'Yellow'}else{'Red'})
            
            if ($connectedCount -eq 0) {
                Write-Host "No hay conectividad de red. Verifique cableado y configuracion." -ForegroundColor Red
            } elseif ($connectedCount -lt $totalCount) {
                Write-Host "Conectividad limitada. Puede haber problemas de DNS o routing." -ForegroundColor Yellow
            } else {
                Write-Host "Conectividad completa. Red funcionando correctamente." -ForegroundColor Green
            }
        }

        Write-Log "Test de conectividad ejecutado. Resultado: $connectedCount/$totalCount conectados" "INFO"

    } catch {
        Write-Host "Error en test de conectividad: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en test de conectividad: $($_.Exception.Message)" "ERROR"
    }
}

function Repair-NetworkStack {
    Show-Title "REPARAR STACK DE RED COMPLETO"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }

    Write-Host "Este proceso reparara completamente el stack de red de Windows." -ForegroundColor Cyan
    Write-Host "Incluye: DNS, TCP/IP, Winsock, y configuraciones de red." -ForegroundColor Yellow
    Write-Host "Se perderan configuraciones de red temporalmente." -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Paso 1/6: Liberando IP actual..." -ForegroundColor Cyan
        ipconfig /release 2>$null
        Write-Host "  IP liberada" -ForegroundColor Green

        Write-Host "Paso 2/6: Limpiando cache DNS..." -ForegroundColor Cyan
        ipconfig /flushdns 2>$null
        Write-Host "  Cache DNS limpiada" -ForegroundColor Green

        Write-Host "Paso 3/6: Registrando DNS..." -ForegroundColor Cyan
        ipconfig /registerdns 2>$null
        Write-Host "  DNS registrado" -ForegroundColor Green

        Write-Host "Paso 4/6: Reseteando Winsock..." -ForegroundColor Cyan
        netsh winsock reset 2>$null
        Write-Host "  Winsock reseteado" -ForegroundColor Green

        Write-Host "Paso 5/6: Reseteando TCP/IP..." -ForegroundColor Cyan
        netsh int ip reset 2>$null
        Write-Host "  TCP/IP reseteado" -ForegroundColor Green

        Write-Host "Paso 6/6: Renovando IP..." -ForegroundColor Cyan
        ipconfig /renew 2>$null
        Write-Host "  IP renovada" -ForegroundColor Green

        Write-Host "`nStack de red reparado exitosamente." -ForegroundColor Green
        Write-Host "Recomendacion: Reinicie el sistema para completar la reparacion." -ForegroundColor Magenta
        Write-Log "Reparacion completa del stack de red ejecutada" "SUCCESS"

    } catch {
        Write-Host "Error al reparar stack de red: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en reparacion de stack de red: $($_.Exception.Message)" "ERROR"
    }
}

function Get-NetworkStatistics {
    Show-Title "ESTADISTICAS DE RED Y TRAFICO"

    try {
        Write-Host "=== CONEXIONES DE RED ACTIVAS ===" -ForegroundColor Yellow
        $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' } | 
                      Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess |
                      Sort-Object LocalPort
        
        if ($connections) {
            $connections | Format-Table -AutoSize
        } else {
            Write-Host "No hay conexiones establecidas" -ForegroundColor Yellow
        }

        Write-Host "`n=== ESTADISTICAS DE INTERFAZ ===" -ForegroundColor Yellow
        $interfaces = Get-NetAdapterStatistics | Where-Object { $_.ReceivedBytes -gt 0 -or $_.SentBytes -gt 0 }
        
        foreach ($interface in $interfaces) {
            Write-Host "$($interface.Name)" -ForegroundColor Cyan
            Write-Host "   Recibido: $([math]::Round($interface.ReceivedBytes / 1MB, 2)) MB" -ForegroundColor Green
            Write-Host "   Enviado: $([math]::Round($interface.SentBytes / 1MB, 2)) MB" -ForegroundColor Blue
            Write-Host "   Paquetes recibidos: $($interface.ReceivedPackets)" -ForegroundColor White
            Write-Host "   Paquetes enviados: $($interface.SentPackets)" -ForegroundColor White
            Write-Host ""
        }

        Write-Log "Estadisticas de red consultadas" "INFO"

    } catch {
        Write-Host "Error al obtener estadisticas: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en Get-NetworkStatistics: $($_.Exception.Message)" "ERROR"
    }
}

function Scan-LocalPorts {
    Show-Title "ESCANEO DE PUERTOS LOCALES"

    try {
        Write-Host "Escaneando puertos locales abiertos..." -ForegroundColor Cyan
        Write-Host "Esto puede tomar unos segundos..." -ForegroundColor Yellow
        Write-Host ""

        $openPorts = @()
        $commonPorts = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080)

        foreach ($port in $commonPorts) {
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $result = $tcp.BeginConnect("127.0.0.1", $port, $null, $null)
                $success = $result.AsyncWaitHandle.WaitOne(100, $false)
                
                if ($success) {
                    $tcp.EndConnect($result)
                    $openPorts += $port
                    Write-Host "  Puerto $port : ABIERTO" -ForegroundColor Green
                } else {
                    Write-Host "  Puerto $port : CERRADO" -ForegroundColor Gray
                }
                $tcp.Close()
            } catch {
                Write-Host "  Puerto $port : CERRADO" -ForegroundColor Gray
            }
        }

        if ($openPorts.Count -gt 0) {
            Write-Host "`n=== RESUMEN DE PUERTOS ABIERTOS ===" -ForegroundColor Yellow
            Write-Host "Puertos abiertos: $($openPorts -join ', ')" -ForegroundColor Green
            Write-Host "Total: $($openPorts.Count) puertos abiertos de $($commonPorts.Count) escaneados" -ForegroundColor Cyan
        } else {
            Write-Host "`nNo se encontraron puertos abiertos en los puertos comunes escaneados." -ForegroundColor Yellow
        }

        Write-Log "Escaneo de puertos locales completado. Puertos abiertos: $($openPorts.Count)" "INFO"

    } catch {
        Write-Host "Error en escaneo de puertos: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en escaneo de puertos: $($_.Exception.Message)" "ERROR"
    }
}

function Test-DNSResolution {
    Show-Title "DIAGNOSTICO DE RESOLUCION DNS"

    try {
        $testDomains = @(
            "google.com",
            "microsoft.com", 
            "github.com",
            "facebook.com",
            "localhost"
        )

        Write-Host "Probando resolucion DNS para dominios comunes..." -ForegroundColor Cyan
        Write-Host ""

        foreach ($domain in $testDomains) {
            Write-Host "Resolviendo: $domain" -ForegroundColor White -NoNewline
            
            try {
                $resolution = Resolve-DnsName -Name $domain -ErrorAction Stop -Type A
                $ipAddress = $resolution.IPAddress -join ', '
                Write-Host " - $ipAddress" -ForegroundColor Green
            } catch {
                Write-Host " - NO RESUELTO" -ForegroundColor Red
            }
        }

        Write-Host "`n=== CONFIGURACION DNS ACTUAL ===" -ForegroundColor Yellow
        $dnsClients = Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses }
        
        foreach ($client in $dnsClients) {
            Write-Host "$($client.InterfaceAlias)" -ForegroundColor Cyan
            Write-Host "   DNS: $($client.ServerAddresses -join ', ')" -ForegroundColor White
        }

        Write-Log "Diagnostico DNS ejecutado" "INFO"

    } catch {
        Write-Host "Error en diagnostico DNS: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en diagnostico DNS: $($_.Exception.Message)" "ERROR"
    }
}

function Get-ActiveConnections {
    Show-Title "CONEXIONES DE RED ACTIVAS Y PROCESOS"

    try {
        Write-Host "=== CONEXIONES TCP ESTABLECIDAS ===" -ForegroundColor Yellow
        $tcpConnections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' } |
                         Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess |
                         Sort-Object LocalPort

        $connectionData = @()
        foreach ($conn in $tcpConnections) {
            try {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                $processName = if ($process) { $process.ProcessName } else { "Unknown" }
                
                $connectionData += [PSCustomObject]@{
                    LocalAddress = $conn.LocalAddress
                    LocalPort = $conn.LocalPort
                    RemoteAddress = $conn.RemoteAddress
                    RemotePort = $conn.RemotePort
                    Process = $processName
                    PID = $conn.OwningProcess
                }
            } catch {
                # Ignorar procesos que no se pueden acceder
            }
        }

        if ($connectionData) {
            $connectionData | Format-Table -AutoSize
        } else {
            Write-Host "No hay conexiones TCP establecidas" -ForegroundColor Yellow
        }

        Write-Host "`n=== RESUMEN POR PROCESO ===" -ForegroundColor Yellow
        $processSummary = $connectionData | Group-Object Process | 
                         Select-Object Name, Count | 
                         Sort-Object Count -Descending
        
        $processSummary | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count) conexiones" -ForegroundColor Cyan
        }

        Write-Log "Conexiones activas consultadas. Total: $($connectionData.Count)" "INFO"

    } catch {
        Write-Host "Error al obtener conexiones: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en Get-ActiveConnections: $($_.Exception.Message)" "ERROR"
    }
}

function Optimize-NetworkSettings {
    Show-Title "OPTIMIZAR CONFIGURACIONES DE RED"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }

    Write-Host "=== OPCIONES DE OPTIMIZACION ===" -ForegroundColor Yellow
    Write-Host "1) Optimizar solo parametros TCP (recomendado para empresas)" -ForegroundColor White
    Write-Host "2) Optimizar todo incluyendo DNS (para uso domestico)" -ForegroundColor White
    Write-Host "3) Restaurar DNS a DHCP (solucionar problemas de acceso)" -ForegroundColor White
    Write-Host "0) Cancelar" -ForegroundColor Gray
    Write-Host ""
    
    $opcion = Get-UserChoice "Seleccione una opcion"
    
    switch ($opcion) {
        "1" { Optimize-TCPOnly }
        "2" { Optimize-FullNetwork }
        "3" { Restore-DHCPDNS }
        "0" { 
            Write-Host "Operacion cancelada." -ForegroundColor Yellow
            return 
        }
        default {
            Write-Host "Opcion invalida" -ForegroundColor Red
            return
        }
    }
}

function Optimize-TCPOnly {
    Show-Title "OPTIMIZAR SOLO PARAMETROS TCP"
    
    Write-Host "Optimizando solo parametros TCP (sin modificar DNS)..." -ForegroundColor Cyan
    Write-Host "Recomendado para redes corporativas con DNS internos." -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Paso 1/2: Optimizando parametros TCP..." -ForegroundColor Cyan
        netsh int tcp set global autotuninglevel=normal 2>$null
        Write-Host "  Parametros TCP optimizados" -ForegroundColor Green
        
        Write-Host "Paso 2/2: Aplicando configuraciones de rendimiento..." -ForegroundColor Cyan
        netsh int ip set global taskoffload=enabled 2>$null
        Write-Host "  Configuraciones aplicadas" -ForegroundColor Green
        
        Write-Host "`nParametros TCP optimizados (DNS no modificado)." -ForegroundColor Green
        Write-Host "Los cambios pueden requerir reinicio para efecto completo." -ForegroundColor Magenta
        Write-Log "Optimizacion TCP (sin DNS) completada" "SUCCESS"

    } catch {
        Write-Host "Error al optimizar parametros TCP: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en optimizacion TCP: $($_.Exception.Message)" "ERROR"
    }
}

function Optimize-FullNetwork {
    Show-Title "OPTIMIZACION COMPLETA DE RED (CON DNS)"
    
    Write-Host "ADVERTENCIA: Esto cambiara los DNS a servidores publicos" -ForegroundColor Red
    Write-Host "No recomendado para redes corporativas con DNS internos" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Paso 1/4: Optimizando parametros TCP..." -ForegroundColor Cyan
        netsh int tcp set global autotuninglevel=normal 2>$null
        Write-Host "  Parametros TCP optimizados" -ForegroundColor Green
        
        Write-Host "Paso 2/4: Configurando DNS optimo..." -ForegroundColor Cyan
        $dnsServers = @("8.8.8.8", "1.1.1.1", "8.8.4.4", "1.0.0.1")
        
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike "*Virtual*" }
        $configuredCount = 0
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers -ErrorAction SilentlyContinue
                $configuredCount++
                Write-Host "  $($adapter.Name): DNS configurado" -ForegroundColor Green
            } catch {
                Write-Host "  $($adapter.Name): No se pudo configurar DNS" -ForegroundColor Yellow
            }
        }
        
        Write-Host "  DNS configurado en $configuredCount adaptadores" -ForegroundColor Green
        
        Write-Host "Paso 3/4: Limpiando cache de red..." -ForegroundColor Cyan
        ipconfig /flushdns 2>$null
        Write-Host "  Cache limpiada" -ForegroundColor Green
        
        Write-Host "Paso 4/4: Aplicando configuraciones de rendimiento..." -ForegroundColor Cyan
        netsh int ip set global taskoffload=enabled 2>$null
        Write-Host "  Configuraciones aplicadas" -ForegroundColor Green
        
        Write-Host "`nConfiguraciones de red optimizadas." -ForegroundColor Green
        Write-Host "Nota: Los DNS se cambiaron a servidores publicos." -ForegroundColor Magenta
        Write-Host "Los cambios pueden requerir reinicio para efecto completo." -ForegroundColor Magenta
        Write-Log "Optimizacion completa de red con DNS completada" "SUCCESS"

    } catch {
        Write-Host "Error al optimizar configuraciones: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error en optimizacion de red: $($_.Exception.Message)" "ERROR"
    }
}

function Restore-DHCPDNS {
    Show-Title "RESTAURAR DNS A CONFIGURACION DHCP"
    
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Se requieren permisos de administrador" -ForegroundColor Red
        return
    }

    Write-Host "Este proceso restaurara la configuracion DNS a DHCP en todos los adaptadores." -ForegroundColor Cyan
    Write-Host "Util para resolver problemas de acceso en redes corporativas." -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "Desea continuar? (S/N)"
    if ($confirm -notmatch '^[Ss]') {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Restaurando DNS a configuracion DHCP..." -ForegroundColor Cyan
        
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        $restoredCount = 0
        
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
                $restoredCount++
                Write-Host "  $($adapter.Name): DNS restaurado a DHCP" -ForegroundColor Green
            } catch {
                Write-Host "  $($adapter.Name): No se pudo restaurar" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`nDNS restaurado a DHCP en $restoredCount adaptadores." -ForegroundColor Green
        Write-Host "Los cambios aplicaran despues de reiniciar o ejecutar 'ipconfig /renew'" -ForegroundColor Magenta
        Write-Log "DNS restaurado a DHCP en $restoredCount adaptadores" "SUCCESS"

    } catch {
        Write-Host "Error al restaurar DNS a DHCP: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error al restaurar DNS a DHCP: $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Show-NetworkMenu, Get-*, Test-*, Repair-*, Restart-*, Scan-*, Optimize-*, Restore-DHCPDNS
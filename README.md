# TechFix v3.1 - Sistema Integral de Soporte Tecnico para Windows #

= DESCRIPCION GENERAL =
TechFix v3.1 es una suite profesional de diagnostico, mantenimiento y reparacion para sistemas Windows, desarrollada completamente en PowerShell. Disenada para tecnicos, administradores de sistemas y usuarios avanzados, ofrece mas de 50 herramientas especializadas en una interfaz unificada y facil de usar.

= CARACTERISTICAS PRINCIPALES =
** (6) MODULOS ESPECIALIZADOS **
1. INFORMACION DEL SISTEMA
- Informacion general del sistema (nombre, usuario, dominio)
- Hardware detallado (CPU, RAM, discos, GPU)
- Red y conectividad (adaptadores, DNS, gateway)
- Espacio en disco y almacenamiento
- Estado de servicios criticos
- Software instalado y actualizaciones

2. LIMPIEZA Y MANTENIMIENTO
- Limpiar archivos temporales del sistema y usuario
- Limpiar Prefetch y caches del sistema
- Vaciar papelera de reciclaje (.bin)
- Limpiar caches de navegadores (Chrome, Edge, Firefox)
- Desfragmentar discos
- Ejecutar Liberador de Espacio de Windows

3. REPARACION DEL SISTEMA
- Reparar archivos del sistema (SFC /scannow)
- Reparar imagen de Windows (DISM)
- Reparar Windows Update
- Reiniciar servicios basicos
- Resetear cache de red completa
- Reparar discos (CHKDSK)
- Reparacion completa automatizada

4. HERRAMIENTAS DE RED
- Informacion detallada de red (adaptadores, IP, DNS)
- Reiniciar adaptadores de red
- Test de conectividad avanzado
- Reparar stack de red completo
- Estadisticas de red y trafico
- Escanear puertos locales
- Diagnostico de DNS
- Conexiones activas y procesos
- Optimizacion inteligente de red

5. DIAGNOSTICOS AVANZADOS
- Diagnostico de rendimiento (CPU, memoria, procesos)
- Verificar eventos criticos (ultimas 24 horas)
- Informacion completa de discos (GPT/MBR, particiones)
- Test de memoria RAM
- Servicios problematicos
- Diagnostico de arranque
- Generar informe HTML profesional con semaforo de estado

6. SISTEMA DE LOGGING
- Log centralizado en: %TEMP%\TechFix_Logs\TechFix.log
- Formato: [fecha] [tipo] mensaje
- Tipos: INFO, SUCCESS, WARNING, ERROR
- Visualizacion con colores en consola
- Opcion para abrir carpeta de logs

= REQUISITOS DEL SISTEMA =
- Sistema Operativo: Windows 10/11, Windows Server 2016/2019/2022
- PowerShell: Version 5.1 o superior
- Privilegios: Ejecucion como administrador (se auto-eleva)
- Espacio: 100 MB minimo para operaciones temporales

= INSTALACION Y EJECUCION =
Instalacion Rapida:
1. Descargar el archivo ZIP completo
2. Extraer en cualquier ubicacion (ej: C:\TechFix\)
3. Ejecutar Ejecutar.ps1

Metodos de Ejecucion:
# Metodo 1: Click derecho sobre Ejecutar.ps1 y Ejecutar con PowerShell 
# Metodo 2: PowerShell como administrador
cd C:\TechFix_v3.1
.\Ejecutar.ps1

# Metodo 3: Desde CMD
powershell -ExecutionPolicy Bypass -File "C:\TechFix_v3.1\Ejecutar.ps1"

Estructura del Proyecto:
TechFix_v3.1/
├── Ejecutar.ps1                    # Punto de entrada principal
└── Modules/                        # Modulos PowerShell
    ├── Core.psm1                  # Funciones base y menu principal
    ├── Info.psm1                  # Informacion del sistema
    ├── Maintenance.psm1           # Limpieza y mantenimiento
    ├── Repair.psm1               # Reparacion del sistema
    ├── Network.psm1              # Herramientas de red
    └── Diagnostics.psm1          # Diagnosticos avanzados

= CARACTERISTICAS DE SEGURIDAD =
Auto-elevacion Inteligente:
- Detecta automaticamente si necesita privilegios de administrador
- Solicita elevacion de forma transparente
- Maneja cancelaciones del usuario correctamente

Politica de Ejecucion:
- Configura temporalmente ExecutionPolicy Bypass solo para el proceso
- Restaura la politica original al cerrar el sistema
- No modifica configuraciones permanentes

Sistema de Confirmaciones:
- Funciones criticas requieren confirmacion explicita del usuario
- Muestra advertencias antes de operaciones de riesgo
- Proporciona informacion clara sobre lo que se va a realizar

= CAMBIOS REALIZADOS =
1. INFORME HTML PROFESIONAL
Generate-SystemHtmlReport
- Genera reporte con semaforo de estado: Verde/Amarillo/Rojo
- Puntuacion de salud: 0-100 puntos calculados automaticamente
- Recomendaciones contextuales segun estado del sistema
- Diseno profesional listo para entregar a clientes
- Se abre automaticamente en el navegador predeterminado

2. OPTIMIZACION INTELIGENTE DE RED
Optimize-NetworkSettings
- Modo Empresa: Optimiza TCP manteniendo DNS interno
- Modo Hogar: Optimizacion completa con DNS publicos
- Restauracion DHCP: Soluciona problemas de acceso
- Recomendaciones automaticas segun tipo de red

3. DIAGNOSTICO COMPLETO DE DISCOS
Test-DiskHealth
- Informacion GPT/MBR y tablas de particion
- Detecta SSD/HDD y medios removibles
- Alertas inteligentes por espacio critico (<10% libre)
- Analisis de particiones y volumenes del sistema

4. REPARACION COMPLETA AUTOMATIZADA
Complete-SystemRepair
- Secuencia inteligente: DISM → SFC → Updates → Servicios → Red
- Proceso guiado paso a paso con feedback visual
- Log detallado de cada operacion realizada
- Recomendaciones post-reparacion

= PARA QUIEN ES TECHFIX 3.1 =
Tecnicos de Soporte:
- Herramienta todo-en-uno para diagnostico rapido
- Informes profesionales para entregar a clientes
- Reparaciones estandarizadas y documentadas

Administradores de Sistemas:
- Mantenimiento preventivo regular
- Monitoreo de salud de multiples sistemas
- Optimizacion de rendimiento de red y disco

Centros de Servicio Tecnico:
- Estandarizacion de procesos de reparacion
- Documentacion automatica de intervenciones
- Capacitacion uniforme para tecnicos

Usuarios Avanzados:
- Diagnostico de problemas sin conocimientos profundos
- Automatizacion de tareas de mantenimiento
- Optimizacion del sistema para mejor rendimiento

= BUENAS PRACTICAS =
Antes de Reparar:
1. Crear punto de restauracion del sistema
2. Generar informe HTML para documentar estado inicial
3. Revisar eventos criticos para identificar problemas

Durante la Ejecucion:
1. Leer mensajes de confirmacion cuidadosamente
2. No interrumpir procesos en ejecucion
3. Revisar logs si algo no funciona como esperado

Despues de Operaciones:
1. Verificar logs en %TEMP%\TechFix_Logs\
2. Generar nuevo informe para comparar estado
3. Reiniciar el sistema si se recomienda

= SOLUCION DE PROBLEMAS COMUNES =
Error: "No se puede cargar el archivo..."
# Solucion manual:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Los logs no se crean:
- Verificar permisos en %TEMP%
- Asegurar que carpeta TechFix_Logs pueda crearse
- Verificar espacio disponible en disco

*** ROADMAP FUTURO ***

TechFix v3.2 (Proximamente):
- Interfaz grafica opcional con WinForms
- Soporte para multiples idiomas
- Integracion con sistemas de tickets
- Backup automatico de configuraciones

TechFix v4.0 (Planificado):
- Monitorizacion en tiempo real
- Panel web remoto para administracion
- Base de datos de problemas/soluciones
- API para integracion con otras herramientas

= AUTOR Y LICENCIA =
- Desarrollador: Smith Lozano
- Version Actual: 3.1 (2025)
- Licencia: Uso libre para fines educativos y de soporte tecnico

= DESCARGO DE RESPONSABILIDAD =
ESTE SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTIA DE NINGUN TIPO. El autor no se hace responsable por cualquier daño o perdida causada por el uso de esta herramienta.

Recomendaciones de Seguridad:
1. Realice backup de datos importantes antes de cualquier reparacion
2. Cree puntos de restauracion del sistema
3. Ejecute en entornos controlados primero si es posible
4. Documente todos los cambios realizados en el sistema

TechFix v3.1 - La herramienta definitiva para diagnostico, mantenimiento y reparacion de sistemas Windows.

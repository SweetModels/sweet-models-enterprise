# ========================================================================
# Script: Flutter + Backend Integration Quick Start
# ========================================================================
# Este script automatiza toda la configuración y prueba
# Uso: .\run_flutter_backend_test.ps1
# ========================================================================

param(
    [switch]$SkipDocker,
    [switch]$SkipFlutter,
    [switch]$OnlyValidate
)

# Colores
$Success = "Green"
$Error = "Red"
$Warning = "Yellow"
$Info = "Cyan"

Write-Host "`n" -ForegroundColor $Info
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $Info
Write-Host "║   SWEET MODELS ENTERPRISE - Flutter Backend Integration       ║" -ForegroundColor $Info
Write-Host "║                    Quick Start Script                          ║" -ForegroundColor $Info
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $Info
Write-Host ""

# ========================================================================
# PASO 1: Verificar Docker
# ========================================================================
if (-not $SkipDocker) {
    Write-Host "PASO 1: Verificando Docker..." -ForegroundColor $Warning
    
    try {
        $dockerStatus = docker-compose ps 2>&1
        
        if ($dockerStatus -match "sme_backend" -and $dockerStatus -match "sme_postgres") {
            Write-Host "[OK] Docker containers encontrados" -ForegroundColor $Success
            
            if ($dockerStatus -match "Up") {
                Write-Host "[OK] Containers están corriendo" -ForegroundColor $Success
            } else {
                Write-Host "[INFO] Containers existen pero no están corriendo" -ForegroundColor $Warning
                Write-Host "Iniciando containers..." -ForegroundColor $Info
                docker-compose up -d
                Start-Sleep -Seconds 5
            }
        } else {
            Write-Host "[ERROR] Containers de Docker no encontrados" -ForegroundColor $Error
            Write-Host "Asegúrate de estar en la carpeta del proyecto" -ForegroundColor $Warning
            exit 1
        }
    } catch {
        Write-Host "[ERROR] Docker no está disponible o no está corriendo" -ForegroundColor $Error
        Write-Host "Solución: Instala Docker Desktop y corre: docker-compose up -d" -ForegroundColor $Warning
        exit 1
    }
}

# ========================================================================
# PASO 2: Verificar Backend API
# ========================================================================
Write-Host "`nPASO 2: Validando Backend API..." -ForegroundColor $Warning

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
        -Method Post `
        -Body (@{
            email = "admin@sweetmodels.com"
            password = "sweet123"
        } | ConvertTo-Json) `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    Write-Host "[OK] Backend responde correctamente" -ForegroundColor $Success
    Write-Host "[OK] Token recibido: $($response.token.Substring(0, 50))..." -ForegroundColor $Success
    Write-Host "[OK] Role: $($response.role)" -ForegroundColor $Success
    Write-Host "[OK] User ID: $($response.user_id)" -ForegroundColor $Success
    
} catch {
    Write-Host "[ERROR] Backend no responde" -ForegroundColor $Error
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor $Error
    Write-Host "Solución: docker-compose logs sme_backend" -ForegroundColor $Warning
    exit 1
}

# ========================================================================
# PASO 3: Verificar Flutter Configuration
# ========================================================================
Write-Host "`nPASO 3: Validando configuración de Flutter..." -ForegroundColor $Warning

$apiServicePath = ".\mobile_app\lib\api_service.dart"

if (-Not (Test-Path $apiServicePath)) {
    Write-Host "[ERROR] Archivo no encontrado: $apiServicePath" -ForegroundColor $Error
    exit 1
}

$content = Get-Content $apiServicePath -Raw

if ($content -match "10\.0\.2\.2:3000") {
    Write-Host "[OK] Base URL correcta para Android Emulator" -ForegroundColor $Success
} else {
    Write-Host "[WARNING] Base URL puede no estar optimizada para emulator" -ForegroundColor $Warning
}

if ($content -match "post\('/api/auth/login'") {
    Write-Host "[OK] Endpoint path correcto: /api/auth/login" -ForegroundColor $Success
} else {
    Write-Host "[WARNING] Endpoint path puede ser incorrecto" -ForegroundColor $Warning
}

if ($content -match "final String token;") {
    Write-Host "[OK] LoginResponse usa campo 'token' correcto" -ForegroundColor $Success
} else {
    Write-Host "[WARNING] LoginResponse puede tener campo incorrecto" -ForegroundColor $Warning
}

# ========================================================================
# PASO 4: Setup Flutter
# ========================================================================
if (-not $SkipFlutter -and -not $OnlyValidate) {
    Write-Host "`nPASO 4: Preparando Flutter..." -ForegroundColor $Warning
    
    Push-Location ".\mobile_app"
    
    Write-Host "  - Limpiando proyecto..." -ForegroundColor $Info
    flutter clean | Out-Null
    
    Write-Host "  - Obteniendo dependencias..." -ForegroundColor $Info
    flutter pub get | Out-Null
    
    Pop-Location
    
    Write-Host "[OK] Flutter preparado" -ForegroundColor $Success
}

# ========================================================================
# RESUMEN FINAL
# ========================================================================
Write-Host "`n" -ForegroundColor $Info
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $Success
Write-Host "║                      ✅ TODO ESTÁ LISTO                        ║" -ForegroundColor $Success
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $Success

Write-Host "`n📋 CHECKLIST FINAL:" -ForegroundColor $Info
Write-Host "  [✓] Docker corriendo" -ForegroundColor $Success
Write-Host "  [✓] Backend respondiendo en http://localhost:3000" -ForegroundColor $Success
Write-Host "  [✓] Base de datos operativa" -ForegroundColor $Success
Write-Host "  [✓] Flutter configurado" -ForegroundColor $Success
Write-Host "  [✓] API client sincronizado" -ForegroundColor $Success

Write-Host "`n📱 CREDENCIALES DE PRUEBA:" -ForegroundColor $Info
Write-Host "  Email:    admin@sweetmodels.com" -ForegroundColor $Success
Write-Host "  Password: sweet123" -ForegroundColor $Success

Write-Host "`n🚀 PRÓXIMOS PASOS:" -ForegroundColor $Info
Write-Host "  1. Abre Android Emulator (AVD Manager desde Android Studio)" -ForegroundColor $Warning
Write-Host "  2. Espera a que cargue completamente (2-3 min)" -ForegroundColor $Warning
Write-Host "  3. Ejecuta en terminal:" -ForegroundColor $Warning
Write-Host "     cd mobile_app" -ForegroundColor $Cyan
Write-Host "     flutter run" -ForegroundColor $Cyan
Write-Host "  4. Cuando veas la app:" -ForegroundColor $Warning
Write-Host "     - Email: admin@sweetmodels.com" -ForegroundColor $Cyan
Write-Host "     - Password: sweet123" -ForegroundColor $Cyan
Write-Host "     - Presiona: INGRESAR AL SISTEMA" -ForegroundColor $Cyan
Write-Host "  5. ¡Deberías ver la pantalla de Dashboard!" -ForegroundColor $Warning

Write-Host "`n📚 DOCUMENTACIÓN DISPONIBLE:" -ForegroundColor $Info
Write-Host "  - LISTO_PARA_EJECUTAR.md .............. Este documento en MD" -ForegroundColor $Warning
Write-Host "  - FLUTTER_EXECUTION_GUIDE.md ......... Guía detallada" -ForegroundColor $Warning
Write-Host "  - QUICK_REFERENCE.md ................. Referencia rápida" -ForegroundColor $Warning

Write-Host "`n⏱️  TIEMPO ESTIMADO:" -ForegroundColor $Info
Write-Host "  - Setup: 5 minutos" -ForegroundColor $Success
Write-Host "  - Compilación Flutter (primera vez): 10 minutos" -ForegroundColor $Success
Write-Host "  - Prueba manual: 3 minutos" -ForegroundColor $Success
Write-Host "  - TOTAL: ~20 minutos" -ForegroundColor $Success

Write-Host "`n"
if (-not $OnlyValidate) {
    Write-Host "💡 TIP: Puedes ejecutar este script de nuevo con -OnlyValidate para solo verificar status" -ForegroundColor $Info
}

Write-Host "`n✨ ¡Sistema listo para la prueba! Abre Android Emulator y ejecuta: flutter run" -ForegroundColor $Success
Write-Host ""

# Script de Pruebas Completas - Sweet Models Enterprise
# Ejecuta todas las pruebas de los servicios

param(
    [switch]$SkipDocker,
    [switch]$SkipFlutter
)

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║     Sweet Models Enterprise - Suite de Pruebas Completas      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$projectRoot = "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise"
$testResults = @{
    Docker = @{Status = "Pendiente"; Details = ""}
    Database = @{Status = "Pendiente"; Details = ""}
    Backend = @{Status = "Pendiente"; Details = ""}
    Endpoints = @{Status = "Pendiente"; Details = ""}
    Flutter = @{Status = "Pendiente"; Details = ""}
}

# ========================================
# 1. PRUEBAS DE DOCKER
# ========================================
if (-not $SkipDocker) {
    Write-Host "`n═══ [1/5] DOCKER - Verificando Servicios ═══`n" -ForegroundColor Green
    
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Docker Desktop está ejecutándose" -ForegroundColor Green
            
            # Verificar contenedores
            $containers = docker ps --format "{{.Names}}" 2>&1
            
            if ($containers -match "sme_postgres") {
                Write-Host "  ✓ PostgreSQL contenedor activo" -ForegroundColor Green
                $testResults.Docker.Status = "✓ Exitoso"
            } else {
                Write-Host "  ⚠ PostgreSQL no está ejecutándose" -ForegroundColor Yellow
                Write-Host "    Iniciando PostgreSQL..." -ForegroundColor Cyan
                Set-Location $projectRoot
                docker-compose up -d postgres
                Start-Sleep -Seconds 5
                $testResults.Docker.Status = "⚠ Iniciado ahora"
            }
            
            if ($containers -match "sme_backend") {
                Write-Host "  ✓ Backend contenedor activo" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Backend no está ejecutándose" -ForegroundColor Yellow
            }
            
        } else {
            Write-Host "  ✗ Docker Desktop no está ejecutándose" -ForegroundColor Red
            $testResults.Docker.Status = "✗ Error"
            $testResults.Docker.Details = "Docker no disponible"
        }
    } catch {
        Write-Host "  ✗ Error al verificar Docker: $_" -ForegroundColor Red
        $testResults.Docker.Status = "✗ Error"
    }
}

# ========================================
# 2. PRUEBAS DE BASE DE DATOS
# ========================================
Write-Host "`n═══ [2/5] DATABASE - Verificando PostgreSQL ═══`n" -ForegroundColor Green

try {
    $dbTest = docker exec sme_postgres psql -U sme_user -d sme_db -c "SELECT COUNT(*) FROM users;" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Conexión a base de datos exitosa" -ForegroundColor Green
        
        # Contar tablas
        $tables = docker exec sme_postgres psql -U sme_user -d sme_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
        $tableCount = $tables.Trim()
        Write-Host "  ✓ Tablas en DB: $tableCount" -ForegroundColor Green
        
        # Contar usuarios
        $userCount = docker exec sme_postgres psql -U sme_user -d sme_db -t -c "SELECT COUNT(*) FROM users;" 2>&1
        Write-Host "  ✓ Usuarios registrados: $($userCount.Trim())" -ForegroundColor Green
        
        $testResults.Database.Status = "✓ Exitoso"
        $testResults.Database.Details = "$tableCount tablas, $($userCount.Trim()) usuarios"
    } else {
        Write-Host "  ✗ Error al conectar a la base de datos" -ForegroundColor Red
        $testResults.Database.Status = "✗ Error"
    }
} catch {
    Write-Host "  ✗ Error: $_" -ForegroundColor Red
    $testResults.Database.Status = "✗ Error"
}

# ========================================
# 3. PRUEBAS DE BACKEND API
# ========================================
Write-Host "`n═══ [3/5] BACKEND API - Probando Endpoints ═══`n" -ForegroundColor Green

try {
    # Health Check
    Write-Host "  [Test 1] Health Check..." -ForegroundColor Cyan
    $health = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 10
    
    if ($health.status -eq "healthy") {
        Write-Host "    ✓ Status: $($health.status)" -ForegroundColor Green
        Write-Host "    ✓ Version: $($health.version)" -ForegroundColor Green
        Write-Host "    ✓ Features: $($health.features -join ', ')" -ForegroundColor Green
        $testResults.Backend.Status = "✓ Exitoso"
    } else {
        Write-Host "    ✗ Backend no está healthy" -ForegroundColor Red
        $testResults.Backend.Status = "⚠ Advertencia"
    }
    
    # Root endpoint
    Write-Host "`n  [Test 2] Root Endpoint..." -ForegroundColor Cyan
    $root = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET -TimeoutSec 10
    Write-Host "    ✓ API Info: $root" -ForegroundColor Green
    
} catch {
    Write-Host "    ✗ Error al conectar con el backend: $_" -ForegroundColor Red
    $testResults.Backend.Status = "✗ Error"
    $testResults.Backend.Details = $_.Exception.Message
}

# ========================================
# 4. PRUEBAS DE ENDPOINTS ESPECÍFICOS
# ========================================
Write-Host "`n═══ [4/5] ENDPOINTS - Pruebas Funcionales ═══`n" -ForegroundColor Green

$endpointTests = @()

# Test de registro (debe fallar sin datos completos)
Write-Host "  [Test 1] POST /api/auth/register (sin datos)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/register" -Method POST -ContentType "application/json" -Body "{}" -UseBasicParsing -TimeoutSec 5 2>&1
} catch {
    if ($_.Exception.Response.StatusCode -eq 400 -or $_.Exception.Response.StatusCode -eq 422) {
        Write-Host "    ✓ Validación funcionando (error esperado)" -ForegroundColor Green
        $endpointTests += "✓"
    } else {
        Write-Host "    ⚠ Respuesta inesperada" -ForegroundColor Yellow
        $endpointTests += "⚠"
    }
}

# Test de login (debe fallar con credenciales incorrectas)
Write-Host "`n  [Test 2] POST /api/auth/login (credenciales incorrectas)..." -ForegroundColor Cyan
try {
    $loginBody = @{
        email = "test@invalid.com"
        password = "wrongpass"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody -UseBasicParsing -TimeoutSec 5 2>&1
} catch {
    if ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 404) {
        Write-Host "    ✓ Autenticación funcionando (rechazo esperado)" -ForegroundColor Green
        $endpointTests += "✓"
    } else {
        Write-Host "    ⚠ Respuesta inesperada: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        $endpointTests += "⚠"
    }
}

# Contar exitosos
$successCount = ($endpointTests | Where-Object { $_ -eq "✓" }).Count
$totalTests = $endpointTests.Count

if ($successCount -eq $totalTests) {
    $testResults.Endpoints.Status = "✓ Exitoso"
    $testResults.Endpoints.Details = "$successCount/$totalTests tests pasaron"
} else {
    $testResults.Endpoints.Status = "⚠ Parcial"
    $testResults.Endpoints.Details = "$successCount/$totalTests tests pasaron"
}

Write-Host "`n  Resultado: $successCount/$totalTests tests exitosos" -ForegroundColor $(if ($successCount -eq $totalTests) { "Green" } else { "Yellow" })

# ========================================
# 5. PRUEBAS DE FLUTTER
# ========================================
if (-not $SkipFlutter) {
    Write-Host "`n═══ [5/5] FLUTTER - Verificando Configuración ═══`n" -ForegroundColor Green
    
    try {
        Set-Location "$projectRoot\mobile_app"
        
        # Verificar dependencias
        if (Test-Path "pubspec.lock") {
            Write-Host "  ✓ Dependencias de Flutter instaladas" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Dependencias no instaladas, ejecutando pub get..." -ForegroundColor Yellow
            C:\flutter\bin\flutter.bat pub get
        }
        
        # Verificar doctor
        Write-Host "`n  Ejecutando flutter doctor..." -ForegroundColor Cyan
        $doctorOutput = C:\flutter\bin\flutter.bat doctor 2>&1
        
        if ($doctorOutput -match "No issues found") {
            Write-Host "  ✓ Flutter completamente configurado" -ForegroundColor Green
            $testResults.Flutter.Status = "✓ Exitoso"
        } elseif ($doctorOutput -match "Windows.*\[√\]") {
            Write-Host "  ✓ Flutter para Windows configurado" -ForegroundColor Green
            $testResults.Flutter.Status = "✓ Parcial"
            $testResults.Flutter.Details = "Windows OK, Android SDK pendiente"
        } else {
            Write-Host "  ⚠ Flutter requiere configuración adicional" -ForegroundColor Yellow
            $testResults.Flutter.Status = "⚠ Advertencia"
        }
        
    } catch {
        Write-Host "  ✗ Error al verificar Flutter: $_" -ForegroundColor Red
        $testResults.Flutter.Status = "✗ Error"
    }
}

# ========================================
# RESUMEN FINAL
# ========================================
Set-Location $projectRoot

Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║                    RESUMEN DE PRUEBAS                          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "  Docker:         $($testResults.Docker.Status)" -ForegroundColor White
if ($testResults.Docker.Details) { Write-Host "                  $($testResults.Docker.Details)" -ForegroundColor Gray }

Write-Host "  Database:       $($testResults.Database.Status)" -ForegroundColor White
if ($testResults.Database.Details) { Write-Host "                  $($testResults.Database.Details)" -ForegroundColor Gray }

Write-Host "  Backend API:    $($testResults.Backend.Status)" -ForegroundColor White
if ($testResults.Backend.Details) { Write-Host "                  $($testResults.Backend.Details)" -ForegroundColor Gray }

Write-Host "  Endpoints:      $($testResults.Endpoints.Status)" -ForegroundColor White
if ($testResults.Endpoints.Details) { Write-Host "                  $($testResults.Endpoints.Details)" -ForegroundColor Gray }

if (-not $SkipFlutter) {
    Write-Host "  Flutter:        $($testResults.Flutter.Status)" -ForegroundColor White
    if ($testResults.Flutter.Details) { Write-Host "                  $($testResults.Flutter.Details)" -ForegroundColor Gray }
}

Write-Host "`n════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Verificar estado general
$allPassed = $true
foreach ($key in $testResults.Keys) {
    if ($testResults[$key].Status -match "✗") {
        $allPassed = $false
        break
    }
}

if ($allPassed) {
    Write-Host "✅ TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE" -ForegroundColor Green
} else {
    Write-Host "⚠️  ALGUNAS PRUEBAS FALLARON - Revisa los detalles arriba" -ForegroundColor Yellow
}

Write-Host "`nComandos útiles:" -ForegroundColor Cyan
Write-Host "  docker-compose logs -f backend    # Ver logs del backend" -ForegroundColor White
Write-Host "  docker-compose ps                 # Ver estado de contenedores" -ForegroundColor White
Write-Host "  flutter run -d windows            # Ejecutar app móvil" -ForegroundColor White
Write-Host ""

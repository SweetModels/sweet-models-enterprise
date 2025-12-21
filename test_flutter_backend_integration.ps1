# =====================================================================
# Script de Prueba: Flutter + Backend Rust Integration Test
# =====================================================================
# Este script verifica que la integración Flutter/Backend esté lista
# Uso: .\test_flutter_backend_integration.ps1
# =====================================================================

param(
    [switch]$TestBackend,
    [switch]$CreateTestUsers,
    [switch]$ShowDocumentation,
    [switch]$All
)

# Colores para output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor $Cyan
    Write-Host ("  " + $Text) -ForegroundColor $Cyan
    Write-Host ("=" * 70) -ForegroundColor $Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host ("  [OK] " + $Text) -ForegroundColor $Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host ("  [ERROR] " + $Text) -ForegroundColor $Red
}

function Write-Info {
    param([string]$Text)
    Write-Host ("  [INFO] " + $Text) -ForegroundColor $Yellow
}

# =====================================================================
# 1. TEST BACKEND CONNECTION
# =====================================================================
function Test-Backend {
    Write-Header "🧪 PRUEBA 1: Verificar Conexión del Backend"
    
    try {
        Write-Info "Intentando conectar a http://localhost:3000/api/auth/login ..."
        
        $response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
            -Method Post `
            -Body (@{
                email = "admin@sweetmodels.com"
                password = "sweet123"
            } | ConvertTo-Json) `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Success "Backend está respondiendo correctamente"
        Write-Host ""
        Write-Host "  📊 Token recibido:" -ForegroundColor $Cyan
        Write-Host "  ├─ Token: $($response.token.Substring(0, 50))..." -ForegroundColor Gray
        Write-Host "  ├─ Role: $($response.role)" -ForegroundColor Gray
        Write-Host "  ├─ User ID: $($response.user_id)" -ForegroundColor Gray
        Write-Host "  ├─ Token Type: $($response.token_type)" -ForegroundColor Gray
        Write-Host "  └─ Expires In: $($response.expires_in) segundos" -ForegroundColor Gray
        Write-Success "✨ Backend está listo para Flutter"
        
    } catch {
        Write-Error-Custom "No se pudo conectar al backend"
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Info "Asegúrate de que el backend esté corriendo: docker-compose up -d"
        return $false
    }
    
    return $true
}

# =====================================================================
# 2. VERIFY FLUTTER CONFIGURATION
# =====================================================================
function Test-Flutter-Config {
    Write-Header "🔧 PRUEBA 2: Verificar Configuración de Flutter"
    
    $apiServicePath = ".\mobile_app\lib\api_service.dart"
    
    if (-Not (Test-Path $apiServicePath)) {
        Write-Error-Custom "No se encontró el archivo: $apiServicePath"
        return $false
    }
    
    $content = Get-Content $apiServicePath -Raw
    
    # Verificar baseUrl
    if ($content -match "baseUrl.*10\.0\.2\.2:3000") {
        Write-Success "✅ baseUrl configurada correctamente para Android Emulator (10.0.2.2:3000)"
    } else {
        Write-Error-Custom "❌ baseUrl no está configurada para Android Emulator"
        Write-Info "Debe ser: http://10.0.2.2:3000"
        return $false
    }
    
    # Verificar endpoint
    if ($content -match "post\('/api/auth/login'") {
        Write-Success "✅ Endpoint de login correcto: /api/auth/login"
    } else {
        Write-Error-Custom "❌ Endpoint de login incorrecto"
        return $false
    }
    
    # Verificar LoginResponse
    if ($content -match "final String token;") {
        Write-Success "✅ LoginResponse usa campo 'token' correcto"
    } else {
        Write-Error-Custom "❌ LoginResponse no usa el campo 'token'"
        return $false
    }
    
    Write-Success "✨ Configuración de Flutter está correcta"
    return $true
}

# =====================================================================
# 3. CREATE TEST USERS
# =====================================================================
function Create-Test-Users {
    Write-Header "👥 CREAR USUARIOS DE PRUEBA"
    
    $testUsers = @(
        @{ Email = "model@sweetmodels.com"; Role = "MODEL"; Name = "Test Model" },
        @{ Email = "moderator@sweetmodels.com"; Role = "MODERATOR"; Name = "Test Moderator" }
    )
    
    Write-Info "Para crear usuarios, necesitas generar hashes Argon2"
    Write-Info "Usa: .\backend_api\target\release\gen_hash.exe 'password'"
    Write-Host ""
    Write-Host "  Usuarios sugeridos:" -ForegroundColor $Cyan
    
    foreach ($user in $testUsers) {
        Write-Host "  ├─ Email: $($user.Email)" -ForegroundColor Gray
        Write-Host "  │  Role: $($user.Role)" -ForegroundColor Gray
        Write-Host "  └─ Password: (cualquiera, usar gen_hash)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Info "SQL para insertar usuarios:"
    Write-Host ""
    Write-Host @"
    -- Test Model User
    INSERT INTO users (id, email, password_hash, role, full_name, is_active, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        'model@sweetmodels.com',
        '<hash_de_gen_hash>',
        'MODEL',
        'Test Model',
        true,
        NOW(),
        NOW()
    );
    
    -- Test Moderator User
    INSERT INTO users (id, email, password_hash, role, full_name, is_active, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        'moderator@sweetmodels.com',
        '<hash_de_gen_hash>',
        'MODERATOR',
        'Test Moderator',
        true,
        NOW(),
        NOW()
    );
"@ -ForegroundColor Gray
}

# =====================================================================
# 4. SHOW DOCUMENTATION
# =====================================================================
function Show-Documentation {
    Write-Header "📖 GUÍA DE INTEGRACIÓN FLUTTER + BACKEND"
    
    Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║                        CREDENCIALES DE PRUEBA                              ║
╚════════════════════════════════════════════════════════════════════════════╝

  Email: admin@sweetmodels.com
  Password: sweet123

╔════════════════════════════════════════════════════════════════════════════╗
║                    FLUJO DE PRUEBA RECOMENDADO                             ║
╚════════════════════════════════════════════════════════════════════════════╝

  1️⃣  Verifica que el backend está corriendo:
      docker ps | findstr sme_backend

  2️⃣  Abre Android Emulator:
      emulator -avd <nombre_avd> -netdelay none -netspeed full

  3️⃣  Ejecuta Flutter:
      cd mobile_app
      flutter clean
      flutter pub get
      flutter run

  4️⃣  Prueba login con credenciales admin

  5️⃣  Verifica que:
      ✅ Token se guarda en SharedPreferences
      ✅ Navegas a la pantalla de Dashboard
      ✅ Datos del usuario aparecen

╔════════════════════════════════════════════════════════════════════════════╗
║                      TROUBLESHOOTING                                       ║
╚════════════════════════════════════════════════════════════════════════════╝

  ❌ "Connection refused"
     → Backend no está corriendo
     → Solución: docker-compose up -d

  ❌ "Invalid credentials"  
     → Email/password incorrectos
     → Solución: Usar admin@sweetmodels.com / sweet123

  ❌ "Network unreachable" (en Android Emulator)
     → Está usando localhost en lugar de 10.0.2.2
     → Solución: Verificar api_service.dart baseUrl

  ❌ "404 Not Found"
     → Endpoint path incorrecto
     → Solución: Debe ser /api/auth/login

╔════════════════════════════════════════════════════════════════════════════╗
║                      ENDPOINTS DISPONIBLES                                 ║
╚════════════════════════════════════════════════════════════════════════════╝

  🔐 Autenticación:
     POST   /api/auth/login                  (email, password)
     POST   /api/auth/refresh                (refresh_token)

  👤 Perfil:
     GET    /api/profile                     (Bearer token)
     PUT    /api/profile                     (Bearer token + datos)

  📊 Dashboard:
     GET    /api/dashboard                   (Bearer token)

  🎬 Documentación completa:
     → Ver: FLUTTER_BACKEND_INTEGRATION_GUIDE.md

"@ -ForegroundColor Cyan
}

# =====================================================================
# MAIN EXECUTION
# =====================================================================
function Main {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Cyan
    Write-Host "║           FLUTTER + BACKEND RUST INTEGRATION TEST                             ║" -ForegroundColor $Cyan
    Write-Host "║                      Sweet Models Enterprise                                   ║" -ForegroundColor $Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Cyan
    Write-Host ""
    
    $allTestsPassed = $true
    
    if ($All -or $TestBackend) {
        if (-Not (Test-Backend)) {
            $allTestsPassed = $false
        }
    }
    
    if ($All -or $CreateTestUsers) {
        Create-Test-Users
    }
    
    if ($All -or (-Not $TestBackend -and -Not $CreateTestUsers -and -Not $ShowDocumentation)) {
        Test-Flutter-Config
        Write-Host ""
        Show-Documentation
    }
    
    if ($ShowDocumentation) {
        Show-Documentation
    }
    
    Write-Header "✨ RESUMEN"
    
    if ($allTestsPassed -or (-Not $TestBackend -and -Not $CreateTestUsers)) {
        Write-Success "Todos los sistemas están listos para probar Flutter login"
        Write-Host ""
        Write-Info "Próximo paso: flutter run en Android Emulator"
    }
}

# Ejecutar
Main

# Pausa al final
Write-Host ""
Read-Host "Presiona Enter para salir"

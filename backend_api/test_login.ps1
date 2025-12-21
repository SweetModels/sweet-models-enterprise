# =====================================================
# Sweet Models Enterprise - Test de Login
# =====================================================
#
# Este script prueba el endpoint de autenticación
# POST /api/auth/login

Write-Host "🧪 Testing Sweet Models Enterprise - Login Endpoint" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# URL del servidor
$baseUrl = "http://localhost:3000"

# Función para hacer request POST
function Test-Login {
    param(
        [string]$Email,
        [string]$Password,
        [string]$Description
    )
    
    Write-Host "📍 Test: $Description" -ForegroundColor Yellow
    Write-Host "   Email: $Email" -ForegroundColor Gray
    
    $body = @{
        email = $Email
        password = $Password
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "✅ Login exitoso!" -ForegroundColor Green
        Write-Host "   Token: $($response.token.Substring(0, 30))..." -ForegroundColor Gray
        Write-Host "   Role: $($response.role)" -ForegroundColor Gray
        Write-Host "   Name: $($response.name)" -ForegroundColor Gray
        Write-Host "   User ID: $($response.user_id)" -ForegroundColor Gray
        Write-Host ""
        
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
        
        Write-Host "❌ Login fallido (HTTP $statusCode)" -ForegroundColor Red
        Write-Host "   Error: $($errorBody.error)" -ForegroundColor Gray
        Write-Host "   Message: $($errorBody.message)" -ForegroundColor Gray
        Write-Host ""
        
        return $null
    }
}

# Verificar que el servidor esté corriendo
Write-Host "🔍 Verificando que el servidor esté corriendo..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Servidor activo!" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "❌ Error: El servidor no está corriendo en $baseUrl" -ForegroundColor Red
    Write-Host "   Ejecuta primero: cargo run --bin main_auth" -ForegroundColor Yellow
    exit 1
}

# Test 1: Login con usuario existente (modelo@sweet.com)
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
$result1 = Test-Login -Email "modelo@sweet.com" -Password "modelo123" -Description "Login con usuario existente"

# Test 2: Login con credenciales incorrectas
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
$result2 = Test-Login -Email "modelo@sweet.com" -Password "wrong_password" -Description "Login con contraseña incorrecta (debe fallar)"

# Test 3: Login con usuario inexistente
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
$result3 = Test-Login -Email "noexiste@sweet.com" -Password "cualquiera" -Description "Login con usuario inexistente (debe fallar)"

# Test 4: Login con campos vacíos
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
$result4 = Test-Login -Email "" -Password "" -Description "Login con campos vacíos (debe fallar)"

# Resumen
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "📊 Resumen de pruebas:" -ForegroundColor Cyan

$tests = @(
    @{ Name = "Login exitoso"; Result = ($null -ne $result1) }
    @{ Name = "Contraseña incorrecta rechazada"; Result = ($null -eq $result2) }
    @{ Name = "Usuario inexistente rechazado"; Result = ($null -eq $result3) }
    @{ Name = "Campos vacíos rechazados"; Result = ($null -eq $result4) }
)

foreach ($test in $tests) {
    $icon = if ($test.Result) { "✅" } else { "❌" }
    $color = if ($test.Result) { "Green" } else { "Red" }
    Write-Host "  $icon $($test.Name)" -ForegroundColor $color
}

Write-Host ""
Write-Host "🎯 Tests completados!" -ForegroundColor Cyan

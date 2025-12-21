#!/usr/bin/env pwsh
# security-audit.ps1
# Audita el código para asegurar que no hay credenciales hardcodeadas

Write-Host "`n🔒 SECURITY AUDIT - Verificando código para secretos hardcodeados`n" -ForegroundColor Cyan

$issues = 0

# Patrones peligrosos a buscar
$patterns = @(
    @{ Pattern = "const.*SECRET.*=.*b?`""; Name = "JWT_SECRET hardcodeado" },
    @{ Pattern = "const.*PASSWORD.*="; Name = "PASSWORD hardcodeado" },
    @{ Pattern = "const.*API_KEY.*="; Name = "API_KEY hardcodeado" },
    @{ Pattern = "AKIA[0-9A-Z]{16}"; Name = "AWS Access Key hardcodeado" },
    @{ Pattern = "aws_secret_access_key\s*="; Name = "AWS Secret Key hardcodeado" },
    @{ Pattern = """your-secret-key-change""; Name = "Placeholder secret en código" },
    @{ Pattern = "Bearer\s+[A-Za-z0-9._-]{100,}"; Name = "Token hardcodeado" }
)

Write-Host "Buscando patrones peligrosos en archivos Rust..." -ForegroundColor Yellow

foreach ($pattern in $patterns) {
    $results = Select-String -Path "backend_api/src/**/*.rs" -Pattern $pattern.Pattern -ErrorAction SilentlyContinue
    
    if ($results) {
        Write-Host "`n❌ ENCONTRADO: $($pattern.Name)" -ForegroundColor Red
        foreach ($result in $results) {
            Write-Host "   Archivo: $($result.Path)" -ForegroundColor Red
            Write-Host "   Línea $($result.LineNumber): $($result.Line.Trim())" -ForegroundColor Red
        }
        $issues++
    }
}

# Verificar que JWT_SECRET se lee desde env var
Write-Host "`n✅ Verificando que JWT_SECRET se lee desde variable de entorno..." -ForegroundColor Yellow
$jwt_env_check = Select-String -Path "backend_api/src/services/jwt.rs" -Pattern "std::env::var.*JWT_SECRET"

if ($jwt_env_check) {
    Write-Host "   ✓ JWT_SECRET se lee correctamente desde variable de entorno" -ForegroundColor Green
} else {
    Write-Host "   ✗ PROBLEMA: JWT_SECRET no se lee desde variable de entorno" -ForegroundColor Red
    $issues++
}

# Verificar .env en .gitignore
Write-Host "`n✅ Verificando que .env está ignorado en Git..." -ForegroundColor Yellow
$gitignore = Get-Content ".gitignore" -ErrorAction SilentlyContinue
if ($gitignore -match "\.env") {
    Write-Host "   ✓ .env está en .gitignore" -ForegroundColor Green
} else {
    Write-Host "   ✗ PROBLEMA: .env NO está en .gitignore" -ForegroundColor Red
    $issues++
}

# Verificar que no hay archivos .env en git
Write-Host "`n✅ Verificando histórico de Git..." -ForegroundColor Yellow
$git_check = git log --all -p -- "*.env" 2>$null | Select-String -Pattern "DATABASE_URL|JWT_SECRET|AWS_" -ErrorAction SilentlyContinue

if ($git_check) {
    Write-Host "   ⚠️  ADVERTENCIA: Se encontraron referencias a variables de entorno en el histórico de Git" -ForegroundColor Yellow
    Write-Host "   Esto puede ser un problema si contienen valores reales" -ForegroundColor Yellow
    $issues++
} else {
    Write-Host "   ✓ Histórico de Git limpio" -ForegroundColor Green
}

# Resumen
Write-Host "`n" -ForegroundColor White
Write-Host "=" * 60 -ForegroundColor Cyan

if ($issues -eq 0) {
    Write-Host "✅ SEGURIDAD: Todo está bien configurado" -ForegroundColor Green
    Write-Host "   Tu código está listo para hacer git push sin exponer secretos" -ForegroundColor Green
} else {
    Write-Host "❌ PROBLEMAS ENCONTRADOS: $issues" -ForegroundColor Red
    Write-Host "   Soluciona los problemas antes de hacer push" -ForegroundColor Red
}

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "`n"

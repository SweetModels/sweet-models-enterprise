# ============================================================================
# Test Local del Dockerfile para Railway
# ============================================================================
# Este script te permite probar el Dockerfile localmente antes de subirlo

Write-Host "`n"
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          🐳 TEST LOCAL DEL DOCKERFILE                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n"

# Verificar que Docker esté instalado
Write-Host "🔍 Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker encontrado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "   Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n"

# Verificar que el Dockerfile existe
if (-Not (Test-Path "Dockerfile")) {
    Write-Host "❌ Dockerfile no encontrado en la raíz del proyecto" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dockerfile encontrado" -ForegroundColor Green

Write-Host "`n"
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

# Opciones
Write-Host "📋 Selecciona una opción:" -ForegroundColor Yellow
Write-Host "`n"
Write-Host "  1. Build de la imagen (sin ejecutar)" -ForegroundColor White
Write-Host "  2. Build + Run (ejecutar contenedor)" -ForegroundColor White
Write-Host "  3. Ver logs del contenedor" -ForegroundColor White
Write-Host "  4. Detener contenedor" -ForegroundColor White
Write-Host "  5. Limpiar imágenes antiguas" -ForegroundColor White
Write-Host "`n"

$option = Read-Host "Opción (1-5)"

switch ($option) {
    "1" {
        Write-Host "`n🏗️  Construyendo imagen..." -ForegroundColor Yellow
        docker build -t sweet-models-backend:test .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Imagen construida exitosamente" -ForegroundColor Green
            Write-Host "`nPara ejecutar: docker run -p 8080:8080 --env-file backend_api/.env sweet-models-backend:test" -ForegroundColor Cyan
        } else {
            Write-Host "`n❌ Error al construir la imagen" -ForegroundColor Red
        }
    }
    
    "2" {
        Write-Host "`n🏗️  Construyendo imagen..." -ForegroundColor Yellow
        docker build -t sweet-models-backend:test .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Imagen construida" -ForegroundColor Green
            Write-Host "`n🚀 Ejecutando contenedor..." -ForegroundColor Yellow
            
            # Verificar si existe .env
            if (Test-Path "backend_api\.env") {
                docker run -d `
                    --name sweet-models-test `
                    -p 8080:8080 `
                    --env-file backend_api/.env `
                    sweet-models-backend:test
            } else {
                Write-Host "⚠️  No se encontró backend_api/.env" -ForegroundColor Yellow
                Write-Host "   Ejecutando sin variables de entorno (puede fallar)" -ForegroundColor Yellow
                docker run -d `
                    --name sweet-models-test `
                    -p 8080:8080 `
                    sweet-models-backend:test
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n✅ Contenedor ejecutándose" -ForegroundColor Green
                Write-Host "`nPrueba: http://localhost:8080" -ForegroundColor Cyan
                Write-Host "Logs:   docker logs -f sweet-models-test" -ForegroundColor Gray
                Write-Host "Detener: docker stop sweet-models-test" -ForegroundColor Gray
            } else {
                Write-Host "`n❌ Error al ejecutar contenedor" -ForegroundColor Red
            }
        }
    }
    
    "3" {
        Write-Host "`n📄 Logs del contenedor..." -ForegroundColor Yellow
        docker logs -f sweet-models-test
    }
    
    "4" {
        Write-Host "`n🛑 Deteniendo contenedor..." -ForegroundColor Yellow
        docker stop sweet-models-test
        docker rm sweet-models-test
        Write-Host "✅ Contenedor detenido y removido" -ForegroundColor Green
    }
    
    "5" {
        Write-Host "`n🧹 Limpiando imágenes antiguas..." -ForegroundColor Yellow
        docker system prune -f
        Write-Host "✅ Limpieza completada" -ForegroundColor Green
    }
    
    default {
        Write-Host "`n❌ Opción inválida" -ForegroundColor Red
    }
}

Write-Host "`n"
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

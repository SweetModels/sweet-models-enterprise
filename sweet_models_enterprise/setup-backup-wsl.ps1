#!/usr/bin/env powershell
# SETUP BACKUP PROTOCOL EN WSL
# Copia archivos a WSL e instala dependencias

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host " CONFIGURANDO BACKUP EN WSL" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

# Paso 1: Crear directorio
Write-Host "1. Creando directorio /opt/studios-dk..." -ForegroundColor Yellow
wsl mkdir -p "/opt/studios-dk"
Write-Host "   OK`n" -ForegroundColor Green

# Paso 2: Copiar archivos
Write-Host "2. Copiando archivos a WSL..." -ForegroundColor Yellow

$files = "backup_protocol.sh", "restore_protocol.sh", "backup_protocol.env", "BACKUP_PROTOCOL_GUIDE.md", "god_key_GENERATED.txt"

foreach ($file in $files) {
    if (Test-Path $file) {
        $winPath = (Get-Item $file).FullName -replace "C:\\", "/mnt/c\" -replace "\\", "/"
        wsl cp "$winPath" "/opt/studios-dk/$file" 2>$null
        Write-Host "   ✓ $file" -ForegroundColor Green
    }
}

Write-Host "`n"

# Paso 3: Permisos
Write-Host "3. Configurando permisos..." -ForegroundColor Yellow
wsl chmod 700 "/opt/studios-dk/backup_protocol.sh"
wsl chmod 700 "/opt/studios-dk/restore_protocol.sh"
wsl chmod 600 "/opt/studios-dk/backup_protocol.env"
Write-Host "   OK`n" -ForegroundColor Green

# Paso 4: Instalar dependencias
Write-Host "4. Instalando dependencias en WSL..." -ForegroundColor Yellow
Write-Host "   Esto puede tardar 1-2 minutos..." -ForegroundColor Gray

wsl apt-get update -qq 2>&1 | Out-Null
wsl apt-get install -y postgresql-client gnupg awscli coreutils 2>&1 | Select-String "Setting up" | ForEach-Object {
    Write-Host "   ✓ $_" -ForegroundColor Green
}

Write-Host "`n"

# Paso 5: Verificar dependencias
Write-Host "5. Verificando dependencias..." -ForegroundColor Yellow

$commands = "pg_dump", "gpg", "aws", "shred"
foreach ($cmd in $commands) {
    $check = wsl which $cmd 2>&1
    if ($check) {
        Write-Host "   ✓ $cmd" -ForegroundColor Green
    } else {
        Write-Host "   X $cmd" -ForegroundColor Red
    }
}

Write-Host "`n"

# Resumen
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " INSTALACION COMPLETADA" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nOK. Ahora puedes usar WSL directamente:`n" -ForegroundColor Yellow

Write-Host "  wsl" -ForegroundColor Gray
Write-Host "  cd /opt/studios-dk" -ForegroundColor Gray
Write-Host "  bash backup_protocol.sh" -ForegroundColor Gray

Write-Host "`n"

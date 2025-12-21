#!/bin/bash
# Script para iniciar el servidor

cd backend_api
Write-Host "🚀 Iniciando servidor Sweet Models Enterprise..." -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# Compilar y ejecutar
cargo run --bin backend_api --release

Write-Host "✅ Servidor iniciado" -ForegroundColor Green

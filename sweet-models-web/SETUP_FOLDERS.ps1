# ============================================================================
# SWEET MODELS WEB - CARPETA SETUP GUIDE
# Estructura Enterprise - Copia y pega en PowerShell
# ============================================================================

# Navega al directorio del proyecto
cd "C:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\sweet-models-web"

# ============================================================================
# 1️⃣ CREAR ESTRUCTURA CORE (API + HOOKS)
# ============================================================================

# Crear carpetas de API
mkdir -Force src\core\api | Out-Null
New-Item -Path "src\core\api\.gitkeep" -ItemType File -Force | Out-Null

# Crear carpetas de Hooks
mkdir -Force src\core\hooks | Out-Null
New-Item -Path "src\core\hooks\.gitkeep" -ItemType File -Force | Out-Null

# ============================================================================
# 2️⃣ CREAR ESTRUCTURA COMPONENTS (UI)
# ============================================================================

mkdir -Force src\components\ui | Out-Null
New-Item -Path "src\components\ui\.gitkeep" -ItemType File -Force | Out-Null

# ============================================================================
# 3️⃣ CREAR RUTAS AUTH (Login, Register, Forgot Password)
# ============================================================================

mkdir -Force "src\app\(auth)\login" | Out-Null
mkdir -Force "src\app\(auth)\register" | Out-Null
mkdir -Force "src\app\(auth)\forgot-password" | Out-Null

# Crear page.tsx placeholder en cada ruta
New-Item -Path "src\app\(auth)\login\page.tsx" -ItemType File -Force | Out-Null
New-Item -Path "src\app\(auth)\register\page.tsx" -ItemType File -Force | Out-Null
New-Item -Path "src\app\(auth)\forgot-password\page.tsx" -ItemType File -Force | Out-Null

# ============================================================================
# 4️⃣ CREAR RUTAS DASHBOARD (Panel Protegido)
# ============================================================================

mkdir -Force "src\app\(dashboard)\panel" | Out-Null
mkdir -Force "src\app\(dashboard)\settings" | Out-Null
mkdir -Force "src\app\(dashboard)\admin" | Out-Null

# Crear page.tsx placeholder
New-Item -Path "src\app\(dashboard)\panel\page.tsx" -ItemType File -Force | Out-Null
New-Item -Path "src\app\(dashboard)\settings\page.tsx" -ItemType File -Force | Out-Null
New-Item -Path "src\app\(dashboard)\admin\page.tsx" -ItemType File -Force | Out-Null

# ============================================================================
# 5️⃣ VERIFICAR ESTRUCTURA CREADA
# ============================================================================

Write-Host "`n✅ Estructura de carpetas creada exitosamente!" -ForegroundColor Green
Write-Host "`nEstructura generada:" -ForegroundColor Cyan
tree src /F 2>$null || ls -Recurse src

Write-Host "`n🎯 Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Copiar contenido de layout.tsx a src/app/layout.tsx"
Write-Host "2. Copiar contenido de page.tsx a src/app/page.tsx"
Write-Host "3. Rellenar archivos page.tsx en carpetas de rutas"
Write-Host "4. npm install (si no lo has hecho)"
Write-Host "5. npm run dev"

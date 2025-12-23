@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ════════════════════════════════════════════════════
echo  INSTALADOR DE DEPENDENCIAS - SWEET MODELS WEB
echo ════════════════════════════════════════════════════
echo.

set projectPath=C:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\sweet-models-web
set npmPath=C:\Program Files\nodejs\npm.cmd
set nodePath=C:\Program Files\nodejs\node.exe

echo. [INFO] Verificando instalaciones...
if not exist "%nodePath%" (
    echo. [ERROR] Node.js no encontrado en %nodePath%
    pause
    exit /b 1
)

echo. [OK] Node.js encontrado
echo. [INFO] Directorio: %projectPath%

cd /d "%projectPath%"

echo.
echo [PASO 1] Instalando dependencias...
echo.

call "%npmPath%" install --legacy-peer-deps --prefer-offline

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] La instalación falló. Intentando con --force...
    call "%npmPath%" install --legacy-peer-deps --force
)

if %ERRORLEVEL% equ 0 (
    echo.
    echo ════════════════════════════════════════════════════
    echo  ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE
    echo ════════════════════════════════════════════════════
    echo.
    echo [INFO] Próximos pasos:
    echo.
    echo 1. Ejecutar servidor de desarrollo:
    echo    npm run dev
    echo.
    echo 2. Abrir en navegador:
    echo    http://localhost:3000
    echo.
    echo 3. Probar login en:
    echo    http://localhost:3000/login
    echo.
) else (
    echo.
    echo [ERROR] La instalación tuvo problemas
    echo.
)

echo.
pause

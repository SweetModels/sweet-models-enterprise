# Configuración Automática de Android SDK para Flutter
# Este script configura Android SDK sin necesidad de Android Studio

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        Configuración de Android SDK para Flutter              ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n📌 SOBRE ANDROID STUDIO:" -ForegroundColor Yellow
Write-Host @"

Android Studio ESTÁ instalado en:
  C:\Program Files\Android\Android Studio

PERO el Android SDK es un componente SEPARADO que se descarga la primera vez
que abres Android Studio.

OPCIONES PARA CONTINUAR:

"@ -ForegroundColor White

Write-Host "  [1] Configurar Android SDK manualmente con Android Studio (RECOMENDADO)" -ForegroundColor Green
Write-Host "      - Abre Android Studio" -ForegroundColor Gray
Write-Host "      - Ve a Tools > SDK Manager" -ForegroundColor Gray
Write-Host "      - Instala Android SDK Platform 34 y Android SDK Build-Tools" -ForegroundColor Gray
Write-Host ""

Write-Host "  [2] Continuar solo con Windows (no requiere Android)" -ForegroundColor Cyan
Write-Host "      - La app Flutter funciona en Windows sin problemas" -ForegroundColor Gray
Write-Host "      - Para desarrollo es suficiente" -ForegroundColor Gray
Write-Host ""

Write-Host "  [3] Descargar Android SDK automáticamente (descarga ~800MB)" -ForegroundColor Yellow
Write-Host "      - Descarga solo las herramientas necesarias" -ForegroundColor Gray
Write-Host "      - Sin interfaz gráfica de Android Studio" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Elige una opción (1, 2, o 3)"

switch ($choice) {
    "1" {
        Write-Host "`n🚀 Abriendo Android Studio..." -ForegroundColor Cyan
        Start-Process "C:\Program Files\Android\Android Studio\bin\studio64.exe"
        
        Write-Host @"

═══════════════════════════════════════════════════════════════
  PASOS A SEGUIR EN ANDROID STUDIO:
═══════════════════════════════════════════════════════════════

1. Espera a que Android Studio abra completamente
2. En la pantalla de bienvenida:
   - Haz clic en "More Actions" (3 puntos verticales)
   - Selecciona "SDK Manager"

3. En la pestaña "SDK Platforms":
   ✓ Marca "Android 14.0 (API 34)" o superior
   ✓ Marca "Android SDK Platform-Tools"

4. En la pestaña "SDK Tools":
   ✓ Marca "Android SDK Build-Tools"
   ✓ Marca "Android SDK Command-line Tools"
   ✓ Marca "Android Emulator" (opcional)

5. Haz clic en "Apply" o "OK"
6. Espera a que descargue (~800MB - 15 minutos aprox)

7. Cuando termine, ejecuta:
   flutter doctor --android-licenses
   (acepta todas las licencias con 'y')

8. Finalmente ejecuta:
   .\test_all.ps1

═══════════════════════════════════════════════════════════════

"@ -ForegroundColor Yellow
    }
    
    "2" {
        Write-Host "`n✅ Perfecto! Vamos a usar solo Windows." -ForegroundColor Green
        
        Write-Host "`nConfigurando Flutter para ignorar Android..." -ForegroundColor Cyan
        C:\flutter\bin\flutter.bat config --no-analytics
        
        Write-Host "`nPuedes ejecutar la app con:" -ForegroundColor Yellow
        Write-Host "  cd mobile_app" -ForegroundColor White
        Write-Host "  flutter run -d windows" -ForegroundColor White
        Write-Host ""
        
        Write-Host "¿Quieres iniciar la app ahora? (S/N): " -ForegroundColor Yellow -NoNewline
        $runNow = Read-Host
        
        if ($runNow -eq 'S' -or $runNow -eq 's') {
            Write-Host "`n🚀 Iniciando app Flutter en Windows..." -ForegroundColor Cyan
            Set-Location "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\mobile_app"
            C:\flutter\bin\flutter.bat run -d windows
        }
    }
    
    "3" {
        Write-Host "`n📥 Descargando Android SDK command-line tools..." -ForegroundColor Cyan
        
        $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
        $cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
        $zipPath = "$env:TEMP\commandlinetools.zip"
        
        # Crear directorio
        if (!(Test-Path $sdkPath)) {
            New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null
            Write-Host "  ✓ Directorio SDK creado: $sdkPath" -ForegroundColor Green
        }
        
        # Descargar
        Write-Host "  Descargando desde Google... (esto puede tardar varios minutos)" -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $cmdlineToolsUrl -OutFile $zipPath
            Write-Host "  ✓ Descarga completa" -ForegroundColor Green
            
            # Extraer
            Write-Host "  Extrayendo archivos..." -ForegroundColor Cyan
            Expand-Archive -Path $zipPath -DestinationPath "$sdkPath\cmdline-tools" -Force
            Remove-Item $zipPath
            
            # Configurar variables de entorno
            Write-Host "  Configurando variables de entorno..." -ForegroundColor Cyan
            [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
            [System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
            
            $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -notlike "*Android\Sdk\platform-tools*") {
                [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$sdkPath\platform-tools;$sdkPath\cmdline-tools\latest\bin", "User")
            }
            
            Write-Host "  ✓ Variables de entorno configuradas" -ForegroundColor Green
            
            # Configurar Flutter
            Write-Host "`n  Configurando Flutter..." -ForegroundColor Cyan
            C:\flutter\bin\flutter.bat config --android-sdk $sdkPath
            
            Write-Host @"

✅ Android SDK instalado básicamente!

Para completar la configuración:
1. Cierra y reabre PowerShell
2. Ejecuta: sdkmanager "platform-tools" "platforms;android-34"
3. Ejecuta: flutter doctor --android-licenses
4. Ejecuta: flutter doctor

"@ -ForegroundColor Green
            
        } catch {
            Write-Host "  ✗ Error al descargar: $_" -ForegroundColor Red
            Write-Host "`nIntenta la opción 1 (Android Studio) en su lugar." -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "`n❌ Opción inválida. Ejecuta el script de nuevo." -ForegroundColor Red
    }
}

Write-Host "`n════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

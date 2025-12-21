# 📖 INSTRUCCIONES EXACTAS - Paso a Paso

**Lee esto para ejecutar la prueba correctamente**

---

## ✅ ANTES DE EMPEZAR - Verificación

Ejecuta esto en PowerShell:

```powershell
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise"
.\quick_validate.ps1
```

**Deberías ver:**
```
✓ Docker containers running
✓ Backend responding
✓ Base URL configured for Android Emulator
✓ Endpoint path correct
✓ LoginResponse model updated
```

Si ves errores, ejecuta: `docker-compose up -d`

---

## 🎯 PASO 1: Abrir Android Emulator (5 minutos)

### Opción A: Desde Android Studio (Recomendado)
1. Abre Android Studio
2. Click en `Tools` (menú superior)
3. Click en `Device Manager` o `AVD Manager`
4. Verás una lista de emuladores virtuales
5. Busca uno (ej: `Pixel 4 API 30`)
6. Click en el botón ▶️ (Play/Verde) para iniciar
7. Espera 2-3 minutos a que cargue (ves Android boot)

### Opción B: Desde línea de comandos
```bash
emulator -avd Pixel_4_API_30 -netdelay none -netspeed full
# Espera a que se abra la ventana del emulator
```

### Verificar que está listo
- Ves la pantalla de home del Android
- Puedes ver la hora actualizada
- La batería muestra porcentaje

**⏱️ Tiempo:** 2-3 minutos

---

## 🎯 PASO 2: Preparar Flutter (3 minutos)

Abre una **NUEVA terminal** en PowerShell o CMD:

```bash
# Navega a la carpeta de Flutter
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\mobile_app"

# Limpia el proyecto (elimina archivos temporales)
flutter clean

# Obtiene las dependencias (descarga librerías)
flutter pub get

# Verifica que todo compiló bien
flutter analyze
```

**Esperado:**
- Sin errores críticos
- "Analyzing..." termina
- Vuelve a línea de comandos normal

**⏱️ Tiempo:** 2-3 minutos

---

## 🎯 PASO 3: Ejecutar Flutter (5-10 minutos)

Misma terminal, ejecuta:

```bash
flutter run
```

**Verás:**
```
Building flutter app...
Compiling...
Installing and launching...
[blah blah mensajes de compilación]
```

**Espera 5-10 minutos** (primer build toma más tiempo)

**Cuando termina:**
- Se abre la app en el Android Emulator
- Ves la pantalla de login
- Las ondas rojas/doradas del logo de Sweet Models

---

## 🎯 PASO 4: Probar Login (1 minuto)

En la pantalla de login que ves en el emulator:

1. **Toca el campo de Email**
   ```
   Ingresa: admin@sweetmodels.com
   ```

2. **Toca el campo de Password**
   ```
   Ingresa: sweet123
   ```

3. **Presiona el botón INGRESAR AL SISTEMA**
   - Ves un círculo cargando
   - Esperas 2-3 segundos
   - ¡La app debe navegar a Dashboard!

---

## ✅ ÉXITO - Qué deberías ver

### Pantalla de Dashboard

Si todo funcionó, verás:
```
╔─────────────────────────────────╗
│  DASHBOARD - Sweet Models       │
│                                 │
│  👤 Admin User                  │
│  📧 admin@sweetmodels.com       │
│  👔 Role: ADMIN                 │
│                                 │
│  Balance: $0.00                 │
│  Models: 0                      │
│  Groups: 0                      │
│                                 │
│  [Perfil] [Configuración]       │
└─────────────────────────────────┘
```

Si ves esto: **¡LA INTEGRACIÓN FUNCIONÓ! ✅**

---

## ❌ Si FALLA

### Error: "Connection refused"
```
Causa: Backend no está corriendo
Solución: 
  docker-compose ps
  docker-compose up -d
```

### Error: "Invalid credentials"
```
Causa: Email/password incorrecto
Solución:
  Verifica exactamente:
  Email:    admin@sweetmodels.com
  Password: sweet123
```

### Error: "Network unreachable"
```
Causa: IP incorrecta en Android Emulator
Solución:
  Presiona CTRL+C en terminal
  Verifica que api_service.dart tenga:
  static const String baseUrl = 'http://10.0.2.2:3000';
  flutter run
```

### Error: "404 Not Found"
```
Causa: Endpoint path incorrecto
Solución:
  Verifica api_service.dart:
  _dio.post('/api/auth/login', ...)  ✓
```

### App se demora mucho o crashea
```
Solución:
  flutter run -v  (para ver logs)
  Busca "exception" o "error"
  Reporta el error
```

---

## 📊 Resumen de Tiempos

| Paso | Tiempo |
|------|--------|
| 1. Abrir Emulator | 5 min |
| 2. Preparar Flutter | 3 min |
| 3. Build + Instalar | 10 min |
| 4. Test Manual | 1 min |
| **TOTAL** | **~20 min** |

---

## 🎯 Resumen Rápido de Comandos

Copiar y pegar en orden:

```bash
# Terminal 1: Verificar backend
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise"
.\quick_validate.ps1

# Esperar confirmación "EVERYTHING IS READY"

# Terminal 2 (mientras esperas emulator): Preparar Flutter
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\mobile_app"
flutter clean && flutter pub get

# Después que emulator abre (Terminal 2): Ejecutar
flutter run

# En la app:
# Email: admin@sweetmodels.com
# Password: sweet123
# Presiona: INGRESAR AL SISTEMA
```

---

## 📝 Checklist Antes de Empezar

- [ ] ¿Viste el mensaje "EVERYTHING IS READY" de quick_validate.ps1?
- [ ] ¿Android Emulator está abierto y cargado?
- [ ] ¿Terminal está en carpeta mobile_app?
- [ ] ¿Ejecutaste flutter clean?
- [ ] ¿Ejecutaste flutter pub get?
- [ ] ¿Tienes a mano las credenciales?

---

## 🚨 Emergencias

### Si la terminal se congela
```
Presiona: CTRL + C para cancelar
Luego vuelve a ejecutar: flutter run
```

### Si el emulator se cierra
```
Vuelve a abrirlo (AVD Manager)
Espera a que cargue
flutter run (en terminal nueva)
```

### Si Flutter no compila
```
flutter clean
Cierra terminal y abre una nueva
cd mobile_app
flutter pub get
flutter run
```

---

## 💾 Información Útil

**Terminal te muestra:**
```
✓ El dispositivo que estás usando (emulator-5554)
✓ El progreso de compilación (%)
✓ Cualquier error que ocurra
```

**Si necesitas pausar:**
```
Presiona: r   - Reload hot (reinicia la app)
Presiona: R   - Full restart (reinicia Flutter)
Presiona: q   - Quit (cierra todo)
```

---

## 📞 Contacto si Hay Problemas

1. Ver qué dice la terminal (últimas 10 líneas)
2. Buscar el error en la sección "Si FALLA" arriba
3. Si no aparece, reportar el error exacto

---

## 🎊 Después del Éxito

1. ✅ Toma una captura de pantalla del Dashboard
2. ✅ Documenta que funcionó
3. ✅ Próximo: Crear usuarios adicionales
4. ✅ Luego: Probar otros endpoints

---

**¡BUENA SUERTE! 🚀**

Sigue estos pasos exactos y funcionará.


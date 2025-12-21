# 🎨 Guía de Generación de Íconos

## Requisitos

Necesitas crear 2 imágenes:

### 1. Ícono Principal (`app_icon.png`)
- **Tamaño**: 1024x1024 píxeles
- **Formato**: PNG con transparencia
- **Ubicación**: `assets/icon/app_icon.png`
- **Diseño**: Logo de Sweet Models con fondo transparente o sólido

### 2. Ícono Adaptive Foreground (Android) (`app_icon_foreground.png`)
- **Tamaño**: 1024x1024 píxeles
- **Formato**: PNG con transparencia
- **Ubicación**: `assets/icon/app_icon_foreground.png`
- **Diseño**: Solo el logo, sin fondo (para Android Adaptive Icons)

## Colores del Brand

Según tu tema actual:

```
Background: #09090B (negro oscuro)
Surface: #18181B (gris muy oscuro)
Accent Cyan: #00F5FF (cyan brillante)
Accent Pink: #EB1555 (rosa/rojo)
```

## Sugerencia de Diseño

**Opción 1: Minimalista**
- Fondo: Negro (#09090B)
- Logo/Texto: Cyan (#00F5FF)
- Acento: Rosa (#EB1555)

**Opción 2: Gradiente**
- Gradiente de cyan a rosa
- Texto blanco encima

**Opción 3: Simple**
- Iniciales "SM" en tipografía moderna
- Fondo degradado o sólido

## Cómo Crear los Íconos

### Opción A: Usar Figma/Adobe Illustrator
1. Crea un canvas de 1024x1024
2. Diseña tu logo
3. Exporta como PNG
4. Guarda en `assets/icon/`

### Opción B: Usar Canva (gratuito)
1. Ir a canva.com
2. Crear diseño personalizado 1024x1024
3. Diseñar el logo
4. Descargar como PNG
5. Guardar en `assets/icon/`

### Opción C: Usar un generador online
1. [IconKitchen](https://icon.kitchen/)
2. [AppIcon.co](https://appicon.co/)
3. [MakeAppIcon](https://makeappicon.com/)

## Estructura de Carpetas

Crea esta estructura:

```
assets/
└── icon/
    ├── app_icon.png (1024x1024, tu logo)
    └── app_icon_foreground.png (1024x1024, logo sin fondo)
```

## Generar los Íconos en Todos los Tamaños

Una vez que tengas las imágenes base, ejecuta:

```bash
flutter pub run flutter_launcher_icons
```

Esto generará automáticamente:

**Android:**
- `mipmap-hdpi/` (72x72)
- `mipmap-mdpi/` (48x48)
- `mipmap-xhdpi/` (96x96)
- `mipmap-xxhdpi/` (144x144)
- `mipmap-xxxhdpi/` (192x192)
- Adaptive icons con foreground y background

**iOS:**
- AppIcon en Assets.xcassets con todos los tamaños necesarios

## Verificar los Resultados

Después de generar, verifica:

1. **Android**: `android/app/src/main/res/mipmap-*/`
2. **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Ejemplo de Logo Placeholder

Si necesitas un placeholder temporal, puedes:

1. Crear un cuadrado negro (#09090B)
2. Agregar texto "SM" en fuente bold, color cyan (#00F5FF)
3. Agregar un borde rosa (#EB1555)
4. Exportar como PNG 1024x1024

## Herramientas Recomendadas

- **Figma** (gratis): https://figma.com
- **Canva** (gratis): https://canva.com
- **GIMP** (gratis, desktop): https://gimp.org
- **Photopea** (gratis, web): https://photopea.com

## ⚠️ Importante

- No uses imágenes con copyright
- Asegúrate de tener los derechos de cualquier logo que uses
- Para App Store, el ícono NO debe tener transparencia en el canal alpha
- Para Google Play, el ícono SÍ puede tener transparencia

## Próximos Pasos

1. ✅ Crear las 2 imágenes (app_icon.png y app_icon_foreground.png)
2. ✅ Guardarlas en `assets/icon/`
3. ✅ Ejecutar `flutter pub run flutter_launcher_icons`
4. ✅ Verificar que se generaron correctamente
5. ✅ Compilar la app y verificar el ícono

---

**¿No tienes tiempo para diseñar?**

Puedo ayudarte a crear un ícono simple usando caracteres y colores. Solo dime qué estilo prefieres:
- Iniciales "SM"
- Logo abstracto
- Ícono minimalista
- Gradiente de colores

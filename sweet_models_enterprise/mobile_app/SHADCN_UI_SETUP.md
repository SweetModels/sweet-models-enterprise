# 🎨 Sweet Models - Shadcn UI Integration

Sistema de diseño premium y minimalista implementado con **shadcn_ui** para Flutter.

## 📦 Instalación

### 1. Agregar el paquete

El paquete `shadcn_ui` ya está agregado en `pubspec.yaml`:

```yaml
dependencies:
  shadcn_ui: ^0.12.1
```

### 2. Instalar dependencias

```bash
cd mobile_app
flutter pub get
```

### 3. Configuración completada ✅

La configuración ya está lista en:
- `lib/theme/app_theme.dart` - Sistema de diseño completo
- `lib/main.dart` - ShadApp configurado con tema Zinc
- `lib/screens/login_screen_shadcn.dart` - Login rediseñado

## 🎨 Paleta de Colores Zinc

```dart
// Backgrounds
Color(0xFF09090B)  // zinc-950 - Fondo principal
Color(0xFF18181B)  // zinc-900 - Superficies
Color(0xFF27272A)  // zinc-800 - Superficies elevadas

// Borders
Color(0xFF3F3F46)  // zinc-700 - Bordes
Color(0xFF52525B)  // zinc-600 - Bordes claros

// Text
Color(0xFFFAFAFA)  // zinc-50  - Texto primario
Color(0xFFA1A1AA)  // zinc-400 - Texto secundario
Color(0xFF71717A)  // zinc-500 - Texto apagado

// Accent
Color(0xFFEB1555)  // Pink - Accent principal (Sweet Models brand)
Color(0xFF00D4FF)  // Cyan - Accent secundario
```

## 🖋️ Tipografía

**Fuente:** Inter (via Google Fonts)

```dart
// Display
displayLarge: 32px, weight: 700
displayMedium: 28px, weight: 600
displaySmall: 24px, weight: 600

// Headings
headlineLarge: 20px, weight: 600
headlineMedium: 18px, weight: 600
headlineSmall: 16px, weight: 600

// Body
bodyLarge: 15px, weight: 400
bodyMedium: 14px, weight: 400
bodySmall: 13px, weight: 400

// Labels
labelLarge: 14px, weight: 500
labelMedium: 12px, weight: 500
labelSmall: 11px, weight: 500
```

## 🧩 Componentes Shadcn UI

### ShadButton

```dart
// Primary Button
ShadButton(
  text: const Text('Iniciar sesión'),
  onPressed: () {},
)

// Secondary Button (outlined)
ShadButton.secondary(
  text: const Text('Cancelar'),
  onPressed: () {},
)

// Ghost Button (transparent)
ShadButton.ghost(
  text: const Text('Más opciones'),
  onPressed: () {},
)

// Destructive Button
ShadButton.destructive(
  text: const Text('Eliminar'),
  onPressed: () {},
)
```

### ShadInput

```dart
ShadInput(
  controller: _controller,
  placeholder: const Text('Escribe algo...'),
  prefix: const Icon(Icons.search),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    return null;
  },
)
```

### ShadCard

```dart
ShadCard(
  padding: const EdgeInsets.all(24),
  child: Column(
    children: [
      Text('Título', style: AppTheme.textTheme.headlineMedium),
      const SizedBox(height: 16),
      Text('Contenido', style: AppTheme.textTheme.bodyMedium),
    ],
  ),
)
```

### ShadCheckbox

```dart
ShadCheckbox(
  value: _isChecked,
  onChanged: (value) {
    setState(() => _isChecked = value);
  },
)
```

### ShadSwitch

```dart
ShadSwitch(
  value: _isEnabled,
  onChanged: (value) {
    setState(() => _isEnabled = value);
  },
)
```

### ShadToast (Notificaciones)

```dart
// Success Toast
ShadToaster.of(context).show(
  ShadToast(
    title: const Text('Éxito'),
    description: const Text('Operación completada'),
  ),
);

// Error Toast
ShadToaster.of(context).show(
  ShadToast.destructive(
    title: const Text('Error'),
    description: const Text('Algo salió mal'),
  ),
);

// Warning Toast
ShadToaster.of(context).show(
  ShadToast(
    title: const Text('Advertencia'),
    description: const Text('Revisa los datos'),
  ),
);
```

## 📱 Pantallas Implementadas

### Login Screen (Shadcn)

Ruta: `/` (pantalla inicial)

**Características:**
- ✅ ShadCard con bordes sutiles
- ✅ ShadInput con prefijos de iconos
- ✅ ShadButton primary y secondary
- ✅ ShadCheckbox para "Recordarme"
- ✅ Toggle de visibilidad de contraseña
- ✅ Web3 wallet connect button
- ✅ ShadToast para notificaciones
- ✅ Validación de formularios
- ✅ Estados de carga (loading)
- ✅ Footer con links

**Preview:**
```
┌─────────────────────────────────┐
│         [Logo Icon]             │
│      Sweet Models               │
│ Enterprise Management Platform  │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  Email                      │ │
│ │  [📧] nombre@empresa.com    │ │
│ │                             │ │
│ │  Contraseña                 │ │
│ │  [🔒] ••••••••        [👁]  │ │
│ │                             │ │
│ │  [✓] Recordarme             │ │
│ │          ¿Olvidaste...?     │ │
│ │                             │ │
│ │  [Iniciar sesión]           │ │
│ │                             │ │
│ │  ─── O CONTINUAR CON ───    │ │
│ │                             │ │
│ │  [💼 Conectar Wallet Web3]  │ │
│ │                             │ │
│ │  ¿No tienes cuenta?         │ │
│ │  [Regístrate]               │ │
│ └─────────────────────────────┘ │
│                                 │
│  © 2025 Sweet Models Enterprise │
│  Términos · Privacidad · Soporte│
└─────────────────────────────────┘
```

## 🚀 Ejecutar la App

```bash
# Windows (modo desarrollo)
flutter run -d windows

# Android
flutter run -d android

# Web
flutter run -d chrome
```

## 🎯 Roadmap

### Próximas Pantallas a Migrar:

1. **Dashboard** → Usar ShadCard, ShadButton, ShadBadge
2. **Register** → Usar ShadInput, ShadSelect, ShadDatePicker
3. **Profile** → Usar ShadAvatar, ShadTabs, ShadDialog
4. **Admin Stats** → Usar ShadCard con fl_chart
5. **Model Home** → Usar ShadCard, ShadButton, ShadDialog

### Componentes Adicionales:

- [ ] ShadDialog para modales
- [ ] ShadPopover para menús contextuales
- [ ] ShadSelect para dropdowns
- [ ] ShadDatePicker para fechas
- [ ] ShadAvatar para fotos de perfil
- [ ] ShadBadge para etiquetas/badges
- [ ] ShadTabs para navegación por tabs
- [ ] ShadAccordion para FAQ/info expandible
- [ ] ShadProgress para barras de progreso
- [ ] ShadSlider para controles deslizantes

## 📚 Recursos

- [shadcn_ui Documentation](https://mariuti.com/shadcn-ui/)
- [Shadcn UI Web (Inspiration)](https://ui.shadcn.com/)
- [Inter Font](https://fonts.google.com/specimen/Inter)
- [Zinc Color Palette](https://tailwindcss.com/docs/customizing-colors)

## 🔧 Personalización

### Cambiar colores del tema:

Editar `lib/theme/app_theme.dart`:

```dart
// Cambiar accent principal
static const Color accent = Color(0xFFEB1555); // Tu color aquí

// Cambiar paleta completa
static ShadThemeData get shadcnTheme => ShadThemeData(
  colorScheme: const ShadSlateColorScheme.dark(), // Slate en lugar de Zinc
  // ... resto de la configuración
);
```

### Cambiar fuente:

En `lib/theme/app_theme.dart`:

```dart
static TextTheme get textTheme => GoogleFonts.geistTextTheme( // Geist en lugar de Inter
  const TextTheme(
    // ... configuración de tipografía
  ),
);
```

## 💡 Tips de Diseño

1. **Spacing consistente**: Usar `AppTheme.spacingXSmall/Small/Medium/Large/XLarge`
2. **Bordes sutiles**: Radio de 8px para inputs, 12px para cards
3. **Sombras mínimas**: Solo en cards elevados
4. **Colores apagados**: Usar zinc-400/500 para texto secundario
5. **Estados hover**: Cambiar opacidad o color ligeramente
6. **Iconos outlined**: Preferir outlined sobre filled para look minimalista
7. **Validación inline**: Mostrar errores debajo de inputs
8. **Loading states**: Usar CircularProgressIndicator pequeño con strokeWidth: 2

## 🐛 Troubleshooting

### Error: "Cannot find package 'shadcn_ui'"

```bash
flutter pub get
flutter pub upgrade
```

### Error: "ShadApp not found"

Verificar import:
```dart
import 'package:shadcn_ui/shadcn_ui.dart';
```

### Tema no se aplica correctamente

Verificar que `ShadApp.material` esté usado en lugar de `MaterialApp`:
```dart
return ShadApp.material(
  darkTheme: AppTheme.shadcnTheme,
  // ...
);
```

---

**¡Sistema de diseño listo! 🎉**

Ahora puedes empezar a migrar las demás pantallas usando los componentes Shadcn UI para un look premium y minimalista.

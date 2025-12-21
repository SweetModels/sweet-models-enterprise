# 🚀 Sistema de Navegación Adaptativa - Guía Completa

## 📱 Descripción General

El sistema de navegación adaptativa de Sweet Models Enterprise proporciona una experiencia fluida y consistente en todas las plataformas (iOS, Android, macOS, Windows, Web) mediante componentes que se adaptan automáticamente al tamaño de pantalla.

## 🎨 Arquitectura

### Componentes Principales

```
lib/
├── screens/
│   ├── main_screen_enhanced.dart      # Hub de navegación principal con animaciones
│   ├── login_screen.dart              # Login con Shadcn UI
│   ├── register_model_screen_shadcn.dart # Registro con Shadcn UI
│   ├── chat_screen.dart               # Chat con IA
│   ├── social_screen.dart             # Feed social
│   └── financial_screen.dart          # Dashboard financiero Web3
└── widgets/
    ├── adaptive_layout.dart           # Widget de navegación adaptativa
    └── adaptive_layout_guide.dart     # Documentación de implementación
```

## 🔄 Flujo de Navegación

### 1. Login → Main Screen
```dart
// Después de login exitoso (login_screen.dart)
Navigator.of(context).pushReplacementNamed('/main');
```

### 2. Navegación entre Tabs
```dart
// MainScreen gestiona automáticamente con AdaptiveScaffold
// Los tabs persisten en SharedPreferences (clave: 'last_tab_index')
```

### 3. Registro → Main Screen
```dart
// Después de registro exitoso (register_model_screen_shadcn.dart)
Navigator.of(context).pushReplacementNamed('/main');
```

## 📐 Comportamiento Responsive

### Breakpoint: 600px

| Ancho de Pantalla | Navegación | Ubicación |
|-------------------|------------|-----------|
| < 600px (Mobile) | BottomNavigationBar | Inferior |
| ≥ 600px (Desktop/Tablet) | NavigationRail | Lateral izquierda (72px) |

### Dispositivos Típicos

- **iPhone SE, iPhone 13/14/15**: BottomNavigationBar (375px - 430px)
- **iPad Mini**: NavigationRail (744px)
- **iPad Pro**: NavigationRail (1024px)
- **MacBook**: NavigationRail (1440px+)
- **Desktop Windows**: NavigationRail (1920px+)

## ✨ Características Implementadas

### 1. Persistencia de Estado
```dart
// Guarda el último tab visitado en SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('last_tab_index', selectedIndex);
```

**Beneficio**: Al reiniciar la app, el usuario regresa al tab donde estaba.

### 2. Animaciones Fluidas
```dart
// FadeTransition entre screens (300ms)
FadeTransition(
  opacity: _fadeAnimation,
  child: _screens[_selectedIndex],
)
```

**Beneficio**: Transiciones suaves y profesionales entre pantallas.

### 3. Diseño Enterprise Minimalista
- **Palette**: Shadcn UI Zinc (#09090B, #18181B, #27272A, #FAFAFA)
- **Tipografía**: Google Fonts Inter
- **Componentes**: ShadButton, ShadInput, ShadCard

## 🧪 Testing Manual

### Paso 1: Verificar Login
```bash
# Correr la app
flutter run
```
1. Ingresa credenciales válidas
2. Verifica redirección a `/main`
3. Confirma que aparece DashboardScreen por defecto

### Paso 2: Verificar Navegación Adaptativa

#### En Desktop (>600px):
1. Redimensiona ventana a 1200px ancho
2. Verifica NavigationRail aparece a la izquierda (72px)
3. Haz clic en cada ítem (Dashboard, Chat, Social, Finanzas)
4. Confirma transiciones suaves con fade

#### En Mobile (<600px):
1. Redimensiona ventana a 375px ancho
2. Verifica BottomNavigationBar aparece en la parte inferior
3. Haz clic en cada ítem
4. Confirma scroll funciona correctamente

### Paso 3: Verificar Persistencia
1. Navega a "Chat" (tab 1)
2. Hot restart la app (Shift + R en Flutter)
3. Confirma que la app abre en "Chat", no en "Dashboard"

### Paso 4: Verificar Registro
1. Desde login, haz clic en "Registrar"
2. Llena el formulario:
   - Nombre: "María García"
   - Email: "maria@test.com"
   - Teléfono: "3001234567" → Clic en "Verificar"
   - Cédula: "123456789"
   - Dirección: "Calle 123"
   - Contraseña: "Test1234"
3. Verifica estilos Shadcn UI (inputs con focus glow)
4. Confirma navegación a `/main` después de registro

## 🎯 Tabs Disponibles

### 0. Dashboard (DashboardScreen)
- **Ícono**: `dashboard_outlined` / `dashboard`
- **Contenido**: Panel de control principal (legacy)
- **Estado**: Zinc palette aplicado

### 1. Chat (ChatScreen)
- **Ícono**: `chat_bubble_outline` / `chat_bubble`
- **Contenido**: Chat con IA, burbujas de mensajes
- **Estado**: ✅ Shadcn UI completo

### 2. Social (SocialScreen)
- **Ícono**: `people_outline` / `people`
- **Contenido**: Feed social con stories y posts
- **Estado**: ✅ Shadcn UI completo

### 3. Finanzas (FinancialScreen)
- **Ícono**: `account_balance_wallet_outlined` / `account_balance_wallet`
- **Contenido**: Dashboard Web3 con balance y transacciones
- **Estado**: ✅ Shadcn UI completo

## 🔧 Personalización

### Cambiar Breakpoint de Responsive
```dart
// En adaptive_layout.dart, línea ~50
final isDesktop = size.width > 800; // Cambiar de 600 a 800
```

### Agregar Nuevo Tab
```dart
// 1. Crear nueva pantalla (e.g., settings_screen.dart)
class SettingsScreen extends StatelessWidget { ... }

// 2. Agregar a main_screen_enhanced.dart
late final List<Widget> _screens = [
  const DashboardScreen(),
  const ChatScreen(),
  const SocialScreen(),
  const FinancialScreen(),
  const SettingsScreen(), // ← Nuevo
];

// 3. Agregar destination
final List<NavigationDestination> _destinations = const [
  // ... existentes
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    label: 'Ajustes',
  ),
];
```

### Cambiar Colores del Tema
```dart
// En theme/app_theme.dart
static const zincBackground = Color(0xFF09090B);  // Zinc-950
static const zincSurface = Color(0xFF18181B);     // Zinc-900
static const zincBorder = Color(0xFF27272A);      // Zinc-800
static const zincPrimary = Color(0xFFFAFAFA);     // Zinc-50
```

## 🐛 Troubleshooting

### Problema: NavigationRail no aparece en desktop
**Solución**: Verifica que el breakpoint se cumpla (>600px). Usa DevTools para inspeccionar `MediaQuery.of(context).size.width`.

### Problema: Persistencia no funciona
**Solución**: Verifica que `shared_preferences` esté instalado:
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

### Problema: Animaciones lagueadas
**Solución**: Reduce duración o desactiva temporalmente:
```dart
// En main_screen_enhanced.dart
duration: const Duration(milliseconds: 150), // Reducir de 300 a 150
```

### Problema: ShadInput no valida correctamente
**Solución**: Asegúrate de llamar `_formKey.currentState!.validate()` antes de procesar:
```dart
if (!_formKey.currentState!.validate()) {
  return; // No continuar si hay errores
}
```

## 📊 Performance

### Métricas Esperadas
- **Tiempo de transición entre tabs**: ~300ms
- **Tiempo de carga inicial (MainScreen)**: <500ms
- **Memoria RAM (4 screens cargadas)**: ~150-200 MB
- **Frame rate**: 60 FPS constante

### Optimizaciones Aplicadas
1. ✅ Uso de `const` constructors donde sea posible
2. ✅ `late final` para listas de screens (evita reconstrucción)
3. ✅ `SingleTickerProviderStateMixin` para animaciones eficientes
4. ✅ SharedPreferences async con `await` apropiado

## 🚀 Próximos Pasos

### Corto Plazo
- [ ] Migrar DashboardScreen completo a Shadcn UI
- [ ] Agregar Hero animations entre login → main
- [ ] Implementar pull-to-refresh en Social feed
- [ ] Añadir notificaciones push (badge en tab Chat)

### Mediano Plazo
- [ ] Conectar ChatScreen con API de IA real (OpenAI/Claude)
- [ ] Implementar Web3 wallet connection en FinancialScreen
- [ ] Agregar infinite scroll en SocialScreen
- [ ] Sistema de temas (dark/light mode toggle)

### Largo Plazo
- [ ] Soporte offline con Hive/SQLite
- [ ] Sincronización en tiempo real con WebSockets
- [ ] PWA support para Web platform
- [ ] Micro-animaciones y haptic feedback

## 📚 Referencias

- [Shadcn UI Flutter](https://pub.dev/packages/shadcn_ui)
- [Material Design Navigation](https://m3.material.io/components/navigation-drawer)
- [Flutter Adaptive Layouts](https://docs.flutter.dev/ui/layout/adaptive-responsive)
- [Google Fonts](https://pub.dev/packages/google_fonts)

---

**Última actualización**: 2025-12-09  
**Versión**: 1.0.0  
**Maintainer**: Sweet Models Enterprise Team

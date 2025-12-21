# 🤖 Beyorder AI - Interfaz Flutter

## 📋 Descripción General

Beyorder AI es un asistente inteligente integrado en la app móvil que proporciona coaching personalizado, análisis de rendimiento y sugerencias estratégicas para las modelos webcam.

## 🎨 Componentes Visuales

### 1. **BeyorderFAB** - Botón Flotante Animado
Botón flotante con efecto neón y partículas orbitales que aparece en todas las pantallas principales.

**Características:**
- ✨ Animación de pulso continuo (escala 1.0 → 1.15)
- 🌟 Aura dorada/rosa con gradiente radial
- 🎯 4 partículas orbitales sincronizadas
- 💫 Efecto de rotación sutil
- 🔮 BoxShadow con blur intenso para efecto neón

**Uso:**
```dart
Scaffold(
  body: YourContent(),
  floatingActionButton: const BeyorderFAB(),
)
```

### 2. **BeyorderCommandCenter** - Pantalla de Chat
Interfaz completa de chat con IA, diseño futurista con tema oscuro y bordes neón.

**Características:**
- 💬 Mensajes con bordes dorados para Beyorder
- 🏷️ Etiquetas de tipo (MOTIVACIÓN, FELICITACIONES, ALERTA)
- 💡 Sugerencias rápidas como chips interactivos
- ⌨️ Barra de entrada con botón de envío animado
- ⏳ Indicador de "escribiendo..." con puntos animados
- 📜 Historial de chat con scroll automático

**Tipos de Mensajes:**
```dart
BeyorderMessageType.motivation     // Borde dorado (#FFD700)
BeyorderMessageType.congratulation // Borde verde neón (#00E676)
BeyorderMessageType.alert          // Borde rosa (#FF6B9D)
BeyorderMessageType.normal         // Borde cyan (#00E5FF)
```

**Navegación:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BeyorderCommandCenter(),
  ),
);
```

### 3. **BeyorderToast** - Notificaciones Proactivas
Toast elegante que aparece en la parte superior cuando Beyorder envía mensajes automáticos.

**Características:**
- 🎭 Animación de entrada elastic desde arriba
- 🌈 Borde y glow según tipo de mensaje
- 👆 Tappable para abrir chat completo
- ⏱️ Auto-dismiss después de 5 segundos
- 🎨 Gradiente de fondo oscuro con efecto cristal

**Uso Manual:**
```dart
// Toast con mensaje personalizado
BeyorderToast.show(
  context,
  message: BeyorderMessage(
    id: 'manual_1',
    content: '¡Vamos Isa, estás a solo 200 tokens de tu meta!',
    isFromBeyorder: true,
    timestamp: DateTime.now(),
    type: BeyorderMessageType.motivation,
  ),
  onTap: () {
    // Navegar al chat
  },
);

// Shortcuts rápidos
BeyorderQuickToast.showMotivation(
  context,
  '¡Sigue así! Ya llevas 500 tokens hoy 🔥',
);

BeyorderQuickToast.showCongratulation(
  context,
  '🎉 ¡Felicidades! Superaste tu meta diaria',
);

BeyorderQuickToast.showAlert(
  context,
  '⚠️ Tu sesión ha bajado un 30% vs ayer',
);
```

### 4. **BeyorderNotificationListener** - Receptor WebSocket
Servicio que escucha mensajes proactivos del backend vía WebSocket.

**Características:**
- 🔌 Conexión persistente al backend
- 🔄 Auto-reconexión cada 5 segundos
- 📨 Muestra toasts automáticamente
- 🎯 Filtra solo mensajes de Beyorder (sender_id = 0)

**Integración en App:**
```dart
// En el Widget raíz después del login
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (authProvider.isAuthenticated) {
      return BeyorderNotificationProvider(
        userId: authProvider.userId!,
        token: authProvider.token!,
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }
    
    return LoginScreen();
  }
}
```

## 🎯 Flujo de Usuario

### Escenario 1: Chat Interactivo
1. Usuario toca el **FAB dorado** en cualquier pantalla
2. Se abre **BeyorderCommandCenter**
3. Usuario ve el estado vacío con avatar de Beyonder
4. Toca un chip de sugerencia rápida: "¿Cómo voy hoy?"
5. Backend responde con análisis de tokens, plataforma, horario
6. Usuario puede seguir preguntando o volver atrás

### Escenario 2: Notificación Proactiva
1. Backend (Observer) detecta que la modelo lleva 200 tokens de 500 meta
2. Backend envía mensaje vía WebSocket al canal `/ws/beyorder/{user_id}`
3. **BeyorderNotificationListener** recibe el mensaje
4. Se muestra **BeyorderToast** con el mensaje motivacional
5. Usuario toca el toast → Navega al chat completo
6. Puede responder o ignorar

## 🔧 Configuración del Backend

### Variables de Entorno (.env)
```env
OPENAI_API_KEY=sk-your-key-here
AI_MODEL=gpt-4o-mini
BEYORDER_ENABLED=true
BEYORDER_INTERVAL_MINS=30
BEYORDER_UNDERPERFORMANCE_THRESHOLD=-0.20
```

### Endpoints API
```
POST /api/ai/chat
Body: { "user_id": 123, "question": "¿Cómo voy hoy?" }
Response: { "response": "Llevas 350 tokens hoy...", "context": {...} }

GET /api/ai/chat/history/:user_id
Response: [{ "id": "1", "content": "...", "created_at": "..." }]

WebSocket: ws://backend/ws/beyorder/:user_id?token=xxx
Message: { "sender_id": 0, "message": "...", "type": "motivation" }
```

## 🎨 Paleta de Colores

```dart
// Backgrounds
Color(0xFF0A0E27)  // Fondo principal (azul oscuro)
Color(0xFF1E2337)  // Fondo secundario (cards)

// Beyorder Signature
Color(0xFFFFD700)  // Dorado (primario)
Color(0xFFFF6B9D)  // Rosa (acento)

// Mensajes
Color(0xFF00E5FF)  // Cyan (normal)
Color(0xFF00E676)  // Verde neón (congratulation)
Color(0xFFFF6B9D)  // Rosa (alert)

// Textos
Color(0xFFFAFAFA)  // Blanco (títulos)
Color(0xFF9E9E9E)  // Gris (subtítulos)
```

## 📦 Dependencias Requeridas

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  http: ^1.0.0
  web_socket_channel: ^2.4.0
  shadcn_ui: ^0.1.0
  google_fonts: ^5.0.0
```

## ✅ Checklist de Integración

- [x] Modelo `BeyorderMessage` creado
- [x] Servicio `BeyorderService` para API calls
- [x] Pantalla `BeyorderCommandCenter` completa
- [x] Widget `BeyorderFAB` con animaciones
- [x] Widget `BeyorderToast` para notificaciones
- [x] Listener WebSocket `BeyorderNotificationListener`
- [x] FAB integrado en `DashboardScreen`
- [x] FAB integrado en `FeedScreen`
- [ ] Integrar listener en `main.dart` o widget raíz
- [ ] Probar conexión WebSocket con backend
- [ ] Agregar analytics de interacciones

## 🚀 Próximos Pasos

1. **Agregar Avatar Personalizado**: Generar avatar procedural para Beyorder
2. **Historial Offline**: Cache local con Hive/SQLite
3. **Voice Input**: Integrar speech-to-text para preguntas por voz
4. **Animaciones Avanzadas**: Rive animations para estados de Beyorder
5. **Gamificación**: XP por interacciones con Beyonder
6. **Configuración**: Permitir deshabilitar notificaciones

## 📝 Notas Técnicas

- **Performance**: Las animaciones usan `SingleTickerProviderStateMixin` para eficiencia
- **Memory**: WebSocket se desconecta automáticamente en dispose()
- **UX**: Toasts no bloquean interacción, se pueden ignorar
- **Accesibilidad**: Todos los textos tienen contraste WCAG AA+
- **Responsive**: Diseño funciona en tablets y teléfonos

---

**Creado por:** Sweet Models Enterprise  
**Versión:** 1.0.0  
**Última actualización:** Diciembre 2025

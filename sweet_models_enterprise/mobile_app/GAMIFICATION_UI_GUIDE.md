# Componentes de Gamificación - Guía de Uso

## 📦 Componentes Disponibles

### 1. **RankBadge** - Emblema Principal

Muestra un icono distintivo según el rango del usuario.

```dart
RankBadge(
  rank: UserRank.elite,
  size: 80,
  isAnimated: true,
)
```

**Características:**
- Rango **Goddess**: Efecto shimmer animado (brillo diamante)
- Otros rangos: Borde neón con resplandor
- Colores distintivos:
  - 🪨 Novice (Gris)
  - ⭐ Rising Star (Azul Neón)
  - 👑 Elite (Violeta)
  - 👸 Queen (Oro)
  - 💎 Goddess (Diamante Cian)

### 2. **RankBadgeSmall** - Emblema Compacto

Para usar en headers, listas o avatares.

```dart
RankBadgeSmall(
  rank: UserRank.queen,
  size: 32,
)
```

### 3. **RankCard** - Tarjeta de Información

Muestra información completa del rango, XP y progreso.

```dart
RankCard(
  rank: UserRank.elite,
  currentXp: 7500,
  nextRankXp: 15000,
)
```

**Incluye:**
- Nombre y descripción del rango
- Emblema animado
- Barra de progreso hacia el siguiente rango
- XP actual / Requerido

### 4. **LevelProgressBar** - Barra de Progreso

Barra visual del progreso hacia el siguiente rango.

```dart
LevelProgressBar(
  currentXp: 7500,
  currentRank: UserRank.elite,
  nextThresholdXp: 15000,
  showLabel: true,
)
```

**Características:**
- Gradiente de color según el rango
- Etiqueta con XP actual/requerido
- Brillo simulado en la punta
- Muestra siguiente rango con emoji

### 5. **LevelProgressBarCompact** - Versión Compacta

Solo la barra, sin texto.

```dart
LevelProgressBarCompact(
  currentXp: 7500,
  currentRank: UserRank.elite,
  nextThresholdXp: 15000,
  height: 6,
)
```

### 6. **LevelUpOverlay** - Pantalla de Level Up

Overlay espectacular cuando el usuario sube de rango.

```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => LevelUpOverlay(
    oldRank: UserRank.elite,
    newRank: UserRank.queen,
    onDismiss: () => Navigator.pop(context),
    showConfetti: true,
  ),
);
```

**Características:**
- 🎊 Confeti animado cayendo
- Emblema con animación de escala + rotación
- Textos con fade + slide
- Auto-cierre después de 4 segundos
- Botón para cerrar manualmente

## 🎨 Paleta de Colores

| Rango | Color | Badge BG | Emoji |
|-------|-------|----------|-------|
| Novice | Grey[600] | Grey[800] | 🪨 |
| Rising Star | #00D9FF (Cyan) | #00D9FF[15%] | ⭐ |
| Elite | #9D4EDD (Violeta) | #9D4EDD[15%] | 👑 |
| Queen | #FFD60A (Oro) | #FFD60A[15%] | 👸 |
| Goddess | #64D9FF (Diamante) | #64D9FF[25%] | 💎 |

## 📱 Integración en ProfileScreen

### Paso 1: Importar componentes

```dart
import 'package:sweet_models_mobile/widgets/gamification/index.dart';
```

### Paso 2: Usar Provider para obtener datos

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gamificationProvider = FutureProvider.autoDispose<UserLevel>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) throw Exception('No user');
  return ref.watch(apiClientProvider).getGamificationLevel(userId);
});

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);
    
    return gamification.when(
      data: (level) {
        final rank = _rankFromString(level.currentRank);
        return SingleChildScrollView(
          child: Column(
            children: [
              // Emblema principal
              RankBadge(rank: rank, size: 120, isAnimated: true),
              
              // Tarjeta de información
              RankCard(
                rank: rank,
                currentXp: level.xp,
                nextRankXp: rank.nextRank?.minXp ?? level.xp,
              ),
              
              // Barra de progreso
              LevelProgressBar(
                currentXp: level.xp,
                currentRank: rank,
                nextThresholdXp: rank.nextRank?.minXp ?? level.xp,
              ),
              
              // Logros
              _buildAchievementsGrid(level.achievements),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => ErrorWidget(error: err),
    );
  }
}
```

### Paso 3: Escuchar notificaciones de level up

```dart
// En tu PushNotificationService:
void _handleNavigation(Map<String, dynamic> data) {
  final action = data['action'];
  
  if (action == 'level_up') {
    final oldRankStr = data['old_rank'];
    final newRankStr = data['new_rank'];
    
    final oldRank = UserRank.values.firstWhere(
      (r) => r.toString().split('.').last == oldRankStr.toLowerCase(),
    );
    final newRank = UserRank.values.firstWhere(
      (r) => r.toString().split('.').last == newRankStr.toLowerCase(),
    );
    
    _showLevelUpOverlay(oldRank, newRank);
  }
}

void _showLevelUpOverlay(UserRank oldRank, UserRank newRank) {
  // Reproducir sonido de triunfo
  // AudioService.instance.playSound('level_up.mp3');
  
  final context = navigatorKey.currentContext!;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LevelUpOverlay(
      oldRank: oldRank,
      newRank: newRank,
      onDismiss: () {
        Navigator.pop(context);
        // Refrescar datos de gamificación
        ref.refresh(gamificationProvider);
      },
      showConfetti: true,
    ),
  );
}
```

## 🔗 Modelo de Datos

```dart
enum UserRank {
  novice,
  risingStar,
  elite,
  queen,
  goddess,
}

class UserLevel {
  final UUID userId;
  final int xp;
  final UserRank currentRank;
  final List<String> achievements;
}
```

## 🎵 Sonidos Recomendados (Opcional)

Agregar a `assets/sounds/`:
- `level_up.mp3` (triunfo épico)
- `confetti.mp3` (sonido de confeti)

En `pubspec.yaml`:
```yaml
assets:
  - assets/sounds/level_up.mp3
  - assets/sounds/confetti.mp3
```

Reproducir:
```dart
import 'package:audioplayers/audioplayers.dart';

final audioPlayer = AudioPlayer();
await audioPlayer.play(AssetSource('sounds/level_up.mp3'));
```

## 🧪 Testing

```dart
void main() {
  group('Gamification Widgets', () {
    testWidgets('RankBadge renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RankBadge(rank: UserRank.elite, size: 80),
          ),
        ),
      );
      
      expect(find.byType(RankBadge), findsOneWidget);
      expect(find.text('👑'), findsOneWidget);
    });
    
    testWidgets('LevelUpOverlay animates', (tester) async {
      // Tu test aquí
    });
  });
}
```

## 📊 Umbrales de XP

| Rango | XP Mín | XP Máx | Reward |
|-------|--------|--------|--------|
| Novice | 0 | 999 | — |
| Rising Star | 1,000 | 4,999 | 50 USDT |
| Elite | 5,000 | 14,999 | 150 USDT |
| Queen | 15,000 | 49,999 | 500 USDT |
| Goddess | 50,000+ | ∞ | 2,000 USDT |

## ⚠️ Consideraciones de Performance

1. `RankBadge` con `isAnimated=true` usa `AnimationController`: mantén solo una instancia animada por pantalla.
2. `LevelUpOverlay` crea 50 confetti particles: considera reducir en dispositivos antiguos.
3. Usa `LevelProgressBarCompact` en listas para mejor performance.

## 🎯 Ejemplo Completo

Ver `profile_integration_example.dart` para un ejemplo funcional completo.

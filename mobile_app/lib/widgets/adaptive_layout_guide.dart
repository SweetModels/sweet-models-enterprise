/// 📱 GUÍA DE IMPLEMENTACIÓN - AdaptiveScaffold
/// 
/// Este archivo muestra cómo envolver tus pantallas con el nuevo sistema
/// de navegación adaptativa.

// ============================================================================
// PASO 1: Crear un MainScreen con estado para controlar la navegación
// ============================================================================

import 'package:flutter/material.dart';
import '../widgets/adaptive_layout.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';
// import 'social_screen.dart';
// import 'financial_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Define las pantallas correspondientes a cada índice
  late final List<Widget> _screens = [
    const DashboardScreen(),      // 0: Dashboard
    const ChatScreen(),            // 1: Chat
    const Placeholder(),           // 2: Social (reemplazar con SocialScreen)
    const Placeholder(),           // 3: Finanzas (reemplazar con FinancialScreen)
  ];

  // Define las rutas personalizadas (opcional)
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Social',
    ),
    NavigationDestination(
      icon: Icon(Icons.trending_up_outlined),
      selectedIcon: Icon(Icons.trending_up),
      label: 'Finanzas',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: _destinations, // Opcional: usa los destinos por defecto si no se especifica
      body: _screens[_selectedIndex],
    );
  }
}

// ============================================================================
// PASO 2: Actualizar main.dart para usar MainScreen como home
// ============================================================================

/*
En tu main.dart, cambia:

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      darkTheme: AppTheme.shadcnTheme,
      themeMode: ThemeMode.dark,
      home: const MainScreen(),  // ← Usa MainScreen en lugar de LoginScreen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),  // Ya no es necesario
        // ... otros routes
      },
    );
  }
}
*/

// ============================================================================
// PASO 3: (Opcional) Usar AdaptiveScaffold directamente en una pantalla
// ============================================================================

/*
Si prefieres no usar MainScreen y controlar la navegación dentro
de cada pantalla individual:

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        
        // Navegar a otras pantallas según el índice
        switch (index) {
          case 0:
            // Ya estás en Dashboard
            break;
          case 1:
            Navigator.pushNamed(context, '/chat');
            break;
          case 2:
            Navigator.pushNamed(context, '/social');
            break;
          case 3:
            Navigator.pushNamed(context, '/financial');
            break;
        }
      },
      body: Column(
        children: [
          // Tu contenido del Dashboard aquí
          Text('Dashboard Content'),
        ],
      ),
    );
  }
}
*/

// ============================================================================
// VENTAJAS DEL SISTEMA ADAPTATIVO
// ============================================================================

/*
✅ AUTOMÁTICO: Se adapta al tamaño de pantalla sin código adicional
✅ CONSISTENTE: Mismo código funciona en iPhone, iPad, Mac, Android, Web
✅ SHADCN UI: Diseño enterprise minimalista con Zinc palette
✅ RESPONSIVO: NavigationRail (>600px) o BottomNavigationBar (<600px)
✅ PERSONALIZABLE: Puedes cambiar iconos, colores, y comportamiento

COMPORTAMIENTO:
- iPhone/Android Phone: BottomNavigationBar (estándar móvil)
- iPad/Android Tablet: NavigationRail lateral (más espacio)
- Mac/Windows Desktop: NavigationRail lateral (modo escritorio)
- Web: NavigationRail lateral (modo desktop automático)

BREAKPOINT:
- 600px es el punto de cambio
- Puedes modificarlo en el código (línea: final isDesktop = size.width > 600;)
*/

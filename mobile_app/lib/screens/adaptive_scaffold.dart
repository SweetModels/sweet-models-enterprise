import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard_screen.dart';

/// 📱 Adaptive Layout Manager
/// Detecta el tamaño de la pantalla y adapta el layout:
/// - iPhone (<600px): BottomNavigationBar
/// - iPad/Mac (>600px): NavigationRail + Content
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({Key? key}) : super(key: key);

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
      label: 'Financial',
      route: '/financial_planning',
    ),
    NavigationItem(
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
      label: 'Grupos',
      route: '/groups',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil',
      route: '/profile',
    ),
    NavigationItem(
      icon: Icons.workspace_premium_outlined,
      activeIcon: Icons.workspace_premium,
      label: 'Modelo',
      route: '/model/home',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      // 📱 MOBILE: BottomNavigationBar (iPhone)
      return _buildMobileLayout();
    } else {
      // 🖥️ TABLET/DESKTOP: NavigationRail + Content (iPad/Mac)
      return _buildTabletLayout();
    }
  }

  /// 📱 Layout móvil con BottomNavigationBar
  Widget _buildMobileLayout() {
    return Scaffold(
      body: const DashboardScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            Navigator.pushNamed(context, _navigationItems[index].route);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1A1F3A),
          selectedItemColor: const Color(0xFF00F5FF),
          unselectedItemColor: Colors.white.withOpacity(0.5),
          elevation: 16,
          items: [
            for (final item in _navigationItems)
              BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
                backgroundColor: const Color(0xFF0A0E27),
              ),
          ],
        ),
      ),
    );
  }

  /// 🖥️ Layout de Tablet/Desktop con NavigationRail
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          // 🔷 NavigationRail (Barra Lateral Izquierda)
          _buildNavigationRail(),
          
          // 📄 Contenido Principal
          Expanded(
            child: Container(
              color: const Color(0xFF0A0E27),
              child: const DashboardScreen(),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔷 NavigationRail estilo Dashboard Profesional
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (int index) {
        setState(() => _currentIndex = index);
        Navigator.pushNamed(context, _navigationItems[index].route);
      },
      extended: true, // Mostrar labels
      backgroundColor: const Color(0xFF1A1F3A),
      selectedIconTheme: const IconThemeData(
        color: Color(0xFF00F5FF),
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: Colors.white.withOpacity(0.5),
        size: 24,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFF00F5FF),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
      ),
      destinations: [
        for (final item in _navigationItems)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

/// 📋 Modelo para los items de navegación
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// 🎯 Consumer Widget adaptativo para manejo de estado
class AdaptiveDashboardScreen extends ConsumerWidget {
  const AdaptiveDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdaptiveScaffold();
  }
}

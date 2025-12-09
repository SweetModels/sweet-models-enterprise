import 'package:flutter/material.dart';
import '../widgets/adaptive_layout.dart';
import '../dashboard_screen.dart';
import 'chat_screen.dart';
import 'social_screen.dart';
import 'financial_screen.dart';

/// Pantalla principal con navegación adaptativa
/// Envuelve todas las pantallas con AdaptiveScaffold para
/// navegación responsive (NavigationRail en desktop, BottomNavigationBar en mobile)
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Define las pantallas correspondientes a cada índice
  late final List<Widget> _screens = [
    const DashboardScreen(),    // 0: Dashboard
    const ChatScreen(),          // 1: Chat con IA
    const SocialScreen(),        // 2: Feed Social
    const FinancialScreen(),     // 3: Finanzas y Web3
  ];

  // Define las rutas personalizadas con iconos específicos
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
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
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
      destinations: _destinations,
      body: _screens[_selectedIndex],
    );
  }
}

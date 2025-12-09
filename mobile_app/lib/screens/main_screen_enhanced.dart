import 'package:flutter/material.dart';
import '../widgets/adaptive_layout.dart';
import '../dashboard_screen.dart';
import 'chat_screen.dart';
import 'social_screen.dart';
import 'financial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla principal con navegación adaptativa y persistencia
/// Guarda el último tab seleccionado y añade animaciones fluidas
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  void initState() {
    super.initState();
    _loadSavedIndex();
    
    // Configurar animación de fade
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('last_tab_index') ?? 0;
    if (mounted && savedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = savedIndex;
      });
    }
  }

  Future<void> _saveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab_index', index);
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    
    // Animación de fade out/in
    _animationController.reverse().then((_) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward();
    });
    
    // Guardar índice seleccionado
    _saveIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: _destinations,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_selectedIndex],
      ),
    );
  }
}

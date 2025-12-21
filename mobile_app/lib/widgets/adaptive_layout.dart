import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 📱 AdaptiveScaffold - Layout que se adapta automáticamente
/// 
/// - **Desktop/Tablet (>600px):** NavigationRail lateral + contenido
/// - **Mobile (<600px):** BottomNavigationBar + contenido
/// 
/// ## Uso:
/// ```dart
/// AdaptiveScaffold(
///   selectedIndex: 0,
///   onDestinationSelected: (index) => setState(() => _selectedIndex = index),
///   body: DashboardScreen(),
/// )
/// ```
class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<NavigationDestination> destinations;

  const AdaptiveScaffold({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    List<NavigationDestination>? destinations,
  })  : destinations = destinations ?? _defaultDestinations,
        super(key: key);

  static const List<NavigationDestination> _defaultDestinations = [
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  /// 🖥️ LAYOUT ESCRITORIO/TABLET: NavigationRail lateral
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Row(
        children: [
          // NavigationRail lateral (Shadcn styled)
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border(
                right: BorderSide(
                  color: const Color(0xFF27272A),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Logo/Brand
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Color(0xFFFAFAFA),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 32),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ShadButton.ghost(
                          onPressed: () => onDestinationSelected(index),
                          backgroundColor: isSelected
                              ? const Color(0xFF27272A)
                              : Colors.transparent,
                          hoverBackgroundColor: const Color(0xFF27272A).withOpacity(0.5),
                          size: ShadButtonSize.lg,
                          width: 48,
                          height: 48,
                          icon: isSelected
                              ? destinations[index].selectedIcon
                              : destinations[index].icon,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }

  /// 📱 LAYOUT MÓVIL: BottomNavigationBar
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF27272A),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                destinations.length,
                (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? (destinations[index].selectedIcon as Icon).icon
                                  : (destinations[index].icon as Icon).icon,
                              color: isSelected
                                  ? const Color(0xFFFAFAFA)
                                  : const Color(0xFF71717A),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destinations[index].label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFFAFAFA)
                                    : const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎯 NavigationDestination - Define un destino de navegación
class NavigationDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const NavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

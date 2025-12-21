import 'package:flutter/material.dart';

/// 📱 Responsive Layout Examples & Patterns
/// Ejemplos de cómo implementar layouts adaptativos en otros screens

// ═══════════════════════════════════════════════════════════════
// PATRÓN 1: Adaptive Grid (Photos, Models, Products)
// ═══════════════════════════════════════════════════════════════

class AdaptiveGridExample extends StatelessWidget {
  const AdaptiveGridExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determinamos el número de columnas según el ancho
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2;  // iPhone: 2 columnas
    } else if (screenWidth < 900) {
      crossAxisCount = 3;  // iPad: 3 columnas
    } else {
      crossAxisCount = 4;  // Mac: 4 columnas
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => Card(
        child: Center(
          child: Text('Item ${index + 1}'),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PATRÓN 2: Adaptive Table (Dashboard Data)
// ═══════════════════════════════════════════════════════════════

class AdaptiveTableExample extends StatelessWidget {
  const AdaptiveTableExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mostrar como lista en móvil
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text('Row ${index + 1}'),
            subtitle: Text('Datos comprimidos para móvil'),
          ),
        ),
      );
    } else {
      // Mostrar como tabla en tablet/desktop
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Valor')),
            DataColumn(label: Text('Estado')),
          ],
          rows: List.generate(
            10,
            (index) => DataRow(cells: [
              DataCell(Text('Item ${index + 1}')),
              DataCell(Text('\$${(index + 1) * 100}')),
              DataCell(Text('Activo')),
            ]),
          ),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PATRÓN 3: Adaptive Dialog / Bottom Sheet
// ═══════════════════════════════════════════════════════════════

void showAdaptiveDialog(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;

  if (isMobile) {
    // Mostrar como BottomSheet en móvil
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona una opción'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Opción 1'),
            ),
          ],
        ),
      ),
    );
  } else {
    // Mostrar como AlertDialog en tablet/desktop
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona una opción'),
        content: const Text('Esta es una descripción'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PATRÓN 4: Adaptive Form Layout
// ═══════════════════════════════════════════════════════════════

class AdaptiveFormExample extends StatelessWidget {
  const AdaptiveFormExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWideScreen
          ? _buildWideForm()  // Desktop: 2 columnas
          : _buildNarrowForm(), // Mobile/Tablet: 1 columna
    );
  }

  Widget _buildWideForm() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowForm() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Dirección',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Teléfono',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PATRÓN 5: Adaptive Sidebar + Content (Split View)
// ═══════════════════════════════════════════════════════════════

class AdaptiveSplitView extends StatefulWidget {
  const AdaptiveSplitView({Key? key}) : super(key: key);

  @override
  State<AdaptiveSplitView> createState() => _AdaptiveSplitViewState();
}

class _AdaptiveSplitViewState extends State<AdaptiveSplitView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth > 900;

    final contentWidget = _buildContent(_selectedIndex);

    if (showSidebar) {
      // Desktop: Sidebar + Content lado a lado
      return Row(
        children: [
          SizedBox(
            width: 250,
            child: ListView(
              children: List.generate(5, (index) {
                return ListTile(
                  title: Text('Item ${index + 1}'),
                  selected: _selectedIndex == index,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                );
              }),
            ),
          ),
          Expanded(child: contentWidget),
        ],
      );
    } else {
      // Mobile/Tablet: Stack o Navigation
      return Scaffold(
        body: contentWidget,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: List.generate(
            5,
            (index) => BottomNavigationBarItem(
              icon: Icon(Icons.abc),
              label: 'Item ${index + 1}',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(int index) {
    return Center(
      child: Text('Contenido del Item ${index + 1}'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PATRÓN 6: Responsive AppBar con Overflow Menu
// ═══════════════════════════════════════════════════════════════

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mobile: Mostrar opciones en Drawer o OverflowMenu
      return AppBar(
        title: const Text('Sweet Models'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Opción 1')),
              const PopupMenuItem(child: Text('Opción 2')),
              const PopupMenuItem(child: Text('Opción 3')),
            ],
          ),
        ],
      );
    } else {
      // Desktop: Mostrar botones directamente
      return AppBar(
        title: const Text('Sweet Models'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Opción 1')),
          TextButton(onPressed: () {}, child: const Text('Opción 2')),
          TextButton(onPressed: () {}, child: const Text('Opción 3')),
        ],
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ═══════════════════════════════════════════════════════════════
// HELPER CLASS: ResponsiveHelper
// ═══════════════════════════════════════════════════════════════

class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Screen size checks
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Orientation checks
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  // Responsive font size
  static double responsiveFontSize(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }
}

// ═══════════════════════════════════════════════════════════════
// EJEMPLO DE USO EN main.dart
// ═══════════════════════════════════════════════════════════════

/*
routes: {
  '/': (context) => const LoginScreenShadcn(),
  '/dashboard': (context) => const AdaptiveDashboardScreen(),
  
  // Ejemplos de otros screens adaptativos:
  '/models': (context) => const AdaptiveGridExample(),
  '/transactions': (context) => const AdaptiveTableExample(),
  '/settings': (context) => const AdaptiveFormExample(),
},
*/

// ═══════════════════════════════════════════════════════════════
// TIPS & BEST PRACTICES
// ═══════════════════════════════════════════════════════════════

/*
✅ BEST PRACTICES PARA RESPONSIVE DESIGN EN FLUTTER:

1. SIEMPRE usa MediaQuery.of(context).size.width
   - Recalcula automáticamente en cambios de orientación
   - Works en simuladores y dispositivos reales

2. Considera el SafeArea para notches y home indicators
   SafeArea(child: YourWidget())

3. Usa LayoutBuilder para más control granular
   LayoutBuilder(builder: (context, constraints) { ... })

4. Testa en múltiples tamaños:
   - iPhone SE (375×667)
   - iPhone 14 (390×844)
   - iPad Air (820×1180)
   - iPad Pro 12.9 (1024×1366)

5. Evita hardcoded widths/heights
   - Usa Expanded, Flexible, FractionallySizedBox en su lugar

6. Para imágenes, usa:
   - Image.asset() con fit: BoxFit.cover
   - FadeInImage para placeholders

7. Fonts también deben ser responsivos
   - Body: mobile 14sp → desktop 16sp
   - Heading: mobile 20sp → desktop 28sp

8. Testea con Device Preview:
   flutter pub add device_preview

✅ PERMISOS iOS/macOS A VERIFICAR:

iOS:
  ✓ NSCameraUsageDescription (KYC)
  ✓ NSPhotoLibraryUsageDescription (Photos upload)
  ✓ NSFaceIDUsageDescription (Biometric auth)
  ✓ NSMicrophoneUsageDescription (Video calls)

macOS:
  ✓ com.apple.security.network.client (API calls)
  ✓ com.apple.security.network.server (WebSockets)
  ✓ com.apple.security.device.camera (KYC)
  ✓ com.apple.security.device.microphone (Audio)
*/

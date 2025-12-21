import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Color Scheme - Sweet Models Enterprise
const Color _darkBg = Color(0xFF121212);
const Color _cardBg = Color(0xFF1E1E1E);
const Color _rosaNeon = Color(0xFFE91E63);
const Color _dorado = Color(0xFFD4AF37);
const Color _verde = Color(0xFF4CAF50);
const Color _rojo = Color(0xFFF44336);
const Color _greyText = Color(0xFFB0B0B0);

/// Reusable StatCard widget for displaying metrics
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: _greyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                color: _greyText,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live Activity Item widget
class LiveActivityItemWidget extends StatelessWidget {
  final LiveActivityItem item;

  const LiveActivityItemWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.left(
          color: _rosaNeon,
          width: 4,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.status == 'active' ? _verde : _rojo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.modelName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.roomName,
                  style: GoogleFonts.poppins(
                    color: _greyText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Viewers count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.viewersCount}',
                style: GoogleFonts.poppins(
                  color: _dorado,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'watching',
                style: GoogleFonts.poppins(
                  color: _greyText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Main Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late DashboardService _dashboardService;
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService();
    _statsFuture = _dashboardService.getAdminStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: _buildAppBar(),
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_dorado),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildEmptyState();
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _dashboardService.getAdminStats();
              });
            },
            color: _dorado,
            backgroundColor: _cardBg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Welcome, GOD',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sweet Models Enterprise Control Panel',
                    style: GoogleFonts.poppins(
                      color: _greyText,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 👥 Personal en Planta (Active Shifts)
                  _buildActiveShiftsSection(),
                  const SizedBox(height: 28),

                  // 📦 Órdenes Pendientes
                  _buildPendingOrdersSection(),
                  const SizedBox(height: 28),

                  // Stats Grid 2x2
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        label: 'Total Revenue',
                        value: '\$${stats.totalRevenueCop.toStringAsFixed(0)}',
                        icon: Icons.trending_up,
                        color: _verde,
                        subtitle: 'COP',
                      ),
                      StatCard(
                        label: 'Total Tokens',
                        value: '${stats.totalTokens}',
                        icon: Icons.token,
                        color: _dorado,
                        subtitle: 'In circulation',
                      ),
                      StatCard(
                        label: 'Active Models',
                        value: '${stats.activeModels}',
                        icon: Icons.person,
                        color: _rosaNeon,
                        subtitle: 'Online now',
                      ),
                      StatCard(
                        label: 'Alerts',
                        value: '${stats.alertsCount}',
                        icon: Icons.warning_amber,
                        color: stats.alertsCount > 0 ? _rojo : _verde,
                        subtitle: stats.alertsCount > 0
                            ? 'Require attention'
                            : 'All clear',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Live Activity Section
                  Text(
                    'Live Activity',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _rosaNeon.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: _buildLiveActivity(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Last Updated
                  Center(
                    child: Text(
                      'Last updated: ${_formatTime(stats.lastUpdated)}',
                      style: GoogleFonts.poppins(
                        color: _greyText,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _rosaNeon,
        onPressed: _showRegisterProductionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _darkBg,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Text(
            'Sweet Models',
            style: GoogleFonts.poppins(
              color: _dorado,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- GOD MODE',
            style: GoogleFonts.poppins(
              color: _rosaNeon,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.document_scanner, color: Colors.blue),
          tooltip: 'Documentos KYC',
          onPressed: _showPendingKycDialog,
        ),
        IconButton(
          icon: const Icon(Icons.gavel, color: _rojo),
          tooltip: 'Aplicar Sanción',
          onPressed: _showPenaltyDialog,
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _rosaNeon.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _rosaNeon, width: 1),
          ),
          child: Center(
            child: Text(
              'ADMIN',
              style: GoogleFonts.poppins(
                color: _rosaNeon,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: _rojo),
          onPressed: _showLogoutDialog,
          tooltip: 'Logout',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _dorado.withOpacity(0.3),
                _rosaNeon.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPenaltyDialog() {
    final emailController = TextEditingController(text: 'modelo@sweet.com');
    final penaltyTypes = <String, int>{
      'Llegada Tarde (-500 XP)': 500,
      'Ausencia (-1000 XP)': 1000,
      'Actitud (-2000 XP)': 2000,
    };
    String selectedType = 'Llegada Tarde (-500 XP)';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text(
            '⚠️ APLICAR SANCIÓN',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Modelo (email)'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setStateSB) {
                  return DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: _cardBg,
                    items: penaltyTypes.keys
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => setStateSB(() => selectedType = v ?? selectedType),
                    decoration: const InputDecoration(labelText: 'Tipo de Falta'),
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: _dorado)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _rojo, foregroundColor: Colors.white),
              onPressed: () async {
                final email = emailController.text.trim();
                final reason = selectedType.split(' (').first;
                final xpPenalty = penaltyTypes[selectedType] ?? 500;
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingrese el email de la modelo'), backgroundColor: Colors.red),
                  );
                  return;
                }
                try {
                  await _dashboardService.penalizeModel(
                    modelEmail: email,
                    reason: reason,
                    xpPenalty: xpPenalty,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Sanción aplicada: $reason (-$xpPenalty XP)'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  setState(() {
                    _statsFuture = _dashboardService.getAdminStats();
                  });
                } catch (e) {
                  final errorMsg = e.toString().replaceAll('Exception: ', '');
                  debugPrint('❌ Penalize error: $errorMsg');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $errorMsg'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: Text('APLICAR CASTIGO', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showRegisterProductionDialog() {
    final emailController = TextEditingController();
    final tokensController = TextEditingController();
    String platform = 'chaturbate';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text(
            'Registrar Producción',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email de la modelo',
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokensController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de Tokens',
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setStateSB) {
                  return DropdownButtonFormField<String>(
                    value: platform,
                    dropdownColor: _cardBg,
                    items: const [
                      DropdownMenuItem(value: 'chaturbate', child: Text('Chaturbate')),
                      DropdownMenuItem(value: 'stripchat', child: Text('Stripchat')),
                    ],
                    onChanged: (v) => setStateSB(() => platform = v ?? 'chaturbate'),
                    decoration: const InputDecoration(labelText: 'Plataforma'),
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: _dorado)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _dorado, foregroundColor: Colors.black),
              onPressed: () async {
                final email = emailController.text.trim();
                final tokens = int.tryParse(tokensController.text.trim() == '' ? '0' : tokensController.text.trim()) ?? 0;
                if (email.isEmpty || tokens <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa email y tokens válidos'), backgroundColor: Colors.red),
                  );
                  return;
                }
                try {
                  await _dashboardService.registerProduction(
                    modelEmail: email,
                    tokens: tokens,
                    platform: platform,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Producción guardada!'), backgroundColor: Colors.green),
                  );
                  setState(() {
                    _statsFuture = _dashboardService.getAdminStats();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('REGISTRAR', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildLiveActivity() {
    // Mock live activity data
    final items = [
      LiveActivityItem(
        modelName: 'Alejandra Vega',
        roomName: 'Private Show',
        viewersCount: 42,
        status: 'active',
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      LiveActivityItem(
        modelName: 'Isabella Santos',
        roomName: 'Group Chat',
        viewersCount: 28,
        status: 'active',
        startedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      LiveActivityItem(
        modelName: 'Sofia Marquez',
        roomName: 'Cam Show',
        viewersCount: 15,
        status: 'active',
        startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];

    return items.isEmpty
        ? [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No active streams',
                  style: GoogleFonts.poppins(
                    color: _greyText,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ]
        : items
            .map((item) => LiveActivityItemWidget(item: item))
            .toList();
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _rojo, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: _rojo, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: GoogleFonts.poppins(
                    color: _rojo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    color: _greyText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _statsFuture = _dashboardService.getAdminStats();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dorado,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No data available',
        style: GoogleFonts.poppins(
          color: _greyText,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(color: _greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: _dorado),
            ),
          ),
          TextButton(
            onPressed: _logout,
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: _rojo, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    
    // Clear dashboard cache
    await _dashboardService.clearCache();
    
    // Navigate to login
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  void _showPendingKycDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text(
            '📄 Ver Documento KYC',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email de la modelo',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _dorado.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _dorado),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: _dorado)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa el email de la modelo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _showKycImagePreview(email);
              },
              child: Text('Ver Documento', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showKycImagePreview(String modelEmail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text(
            '🖼️ Documento KYC - $modelEmail',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _dorado, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    'https://sweet-models-secure.s3.amazonaws.com/kyc/$modelEmail/sample.jpg',
                    fit: BoxFit.cover,
                    width: 300,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[800],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 64, color: _dorado),
                            const SizedBox(height: 16),
                            Text(
                              'No hay documento\no no está disponible',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            color: _dorado,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: GoogleFonts.poppins(color: _dorado)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Documento aprobado para $modelEmail',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Aprobar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '❌ Documento rechazado para $modelEmail',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('Rechazar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveShiftsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchActiveShifts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _dorado.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👥 Personal en Planta',
                  style: GoogleFonts.poppins(
                    color: _dorado,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final shifts = List<Map<String, dynamic>>.from(data['shifts'] ?? []);
        final count = data['count'] ?? 0;

        if (count == 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👥 Personal en Planta',
                  style: GoogleFonts.poppins(
                    color: _dorado,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🏜️ El estudio está vacío',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _dorado.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '👥 Personal en Planta',
                    style: GoogleFonts.poppins(
                      color: _dorado,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count activa${count > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final shift = shifts[index];
                    final name = (shift['full_name'] ?? 'Unknown') as String;
                    final email = (shift['email'] ?? '') as String;
                    final initials = name
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                        .join()
                        .substring(0, 2);

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Tooltip(
                        message: '$name\n$email',
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple,
                                    Colors.purple,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _dorado.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.poppins(
                                    color: _dorado,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name.split(' ').first,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchActiveShifts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'count': 0, 'shifts': []};
      }

      final dio = Dio(BaseOptions(
        baseUrl: 'http://10.0.2.2:3000',
        connectTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get(
        '/api/admin/active-shifts',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {'count': 0, 'shifts': []};
    } catch (e) {
      debugPrint('Error fetching active shifts: $e');
      return {'count': 0, 'shifts': []};
    }
  }

  Widget _buildPendingOrdersSection() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchPendingOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        
        return Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _rosaNeon.withOpacity(0.3), width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📦 Entregas Pendientes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _rosaNeon,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _rosaNeon.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${orders.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _rosaNeon,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '✅ ¡No hay órdenes pendientes!',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _verde,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _dorado.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['product_name'] ?? 'Producto',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order['user_email'] ?? 'Email',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: _greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _verde,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _markOrderDelivered(order['id']),
                              child: Text(
                                'ENTREGAR',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchPendingOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminToken = prefs.getString('admin_token') ?? '';

      final dio = Dio(
        BaseOptions(baseUrl: 'http://localhost:3000'),
      );

      final response = await dio.get(
        '/api/admin/pending-orders',
        options: Options(
          headers: {'Authorization': 'Bearer $adminToken'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pending orders: $e');
      return [];
    }
  }

  Future<void> _markOrderDelivered(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminToken = prefs.getString('admin_token') ?? '';

      final dio = Dio(
        BaseOptions(baseUrl: 'http://localhost:3000'),
      );

      final response = await dio.post(
        '/api/admin/mark-delivered',
        options: Options(
          headers: {'Authorization': 'Bearer $adminToken'},
        ),
        data: {'order_id': orderId},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orden entregada'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        setState(() {
          _statsFuture = _dashboardService.getAdminStats();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al entregar: $e'),
          backgroundColor: _rojo,
        ),
      );
    }
  }


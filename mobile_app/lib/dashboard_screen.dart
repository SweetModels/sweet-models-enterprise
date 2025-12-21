import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

// Provider para los datos del dashboard
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getDashboardData();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final numberFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text(
          'Panel de Control',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate, color: Color(0xFFFAFAFA)),
            onPressed: () => Navigator.pushNamed(context, '/financial_planning'),
            tooltip: 'Financial Planning',
          ),
          IconButton(
            icon: const Icon(Icons.group, color: Color(0xFFFAFAFA)),
            onPressed: () => Navigator.pushNamed(context, '/groups'),
            tooltip: 'Groups',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF00F5FF)),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Color(0xFFFFC857)),
            onPressed: () => Navigator.pushNamed(context, '/model/home'),
            tooltip: 'Espacio del Modelo',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F5FF)),
            onPressed: () => ref.refresh(dashboardProvider),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF6B9D)),
            onPressed: () async {
              // Cerrar sesión
              final apiService = ref.read(apiServiceProvider);
              await apiService.logout();
              
              // Navegar al login
              if (context.mounted) {
                // Usar pop hasta la raíz y luego navegar
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF00F5FF),
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Cargando datos...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: const Color(0xFFFF6B9D),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar datos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(dashboardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: const Color(0xFF0A0E27),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (dashboard) => RefreshIndicator(
          color: const Color(0xFF00F5FF),
          backgroundColor: const Color(0xFF1A1F3A),
          onRefresh: () async {
            ref.refresh(dashboardProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header con estadísticas generales
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00F5FF).withOpacity(0.2),
                        const Color(0xFFFF6B9D).withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 Resumen Financiero',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Tokens Totales',
                            '${dashboard.totalTokens.toStringAsFixed(0)}',
                            Icons.toll,
                            const Color(0xFF00F5FF),
                          ),
                          _buildStatCard(
                            'Miembros',
                            '${dashboard.totalMembers}',
                            Icons.people,
                            const Color(0xFFFF6B9D),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Pago Total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              numberFormat.format(dashboard.totalPayoutCop),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                            Text(
                              'TRM: \$${dashboard.trmUsed.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sección de Nuevas Funcionalidades
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEB1555).withOpacity(0.2),
                        const Color(0xFF00F5FF).withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEB1555).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.new_releases, color: Color(0xFFEB1555), size: 24),
                          SizedBox(width: 8),
                          Text(
                            '✨ Nuevas Funcionalidades',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _buildNewFeatureCard(
                            context,
                            'Estadísticas Financieras',
                            'Gráficos en tiempo real',
                            Icons.trending_up,
                            const Color(0xFF00FF41),
                            '/admin_stats',
                          ),
                          _buildNewFeatureCard(
                            context,
                            'Registro Avanzado',
                            'Proceso 4 pasos con OTP',
                            Icons.person_add,
                            const Color(0xFF00F5FF),
                            '/register_advanced',
                          ),
                          _buildNewFeatureCard(
                            context,
                            'Verificación OTP',
                            'Código SMS 6 dígitos',
                            Icons.sms,
                            const Color(0xFF4ADE80),
                            null,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/otp_verify',
                                arguments: {
                                  'phone': '+573001234567',
                                  'onComplete': () => Navigator.pop(context),
                                },
                              );
                            },
                          ),
                          _buildNewFeatureCard(
                            context,
                            'Captura KYC',
                            'Documentos con cámara',
                            Icons.camera_alt,
                            const Color(0xFFFFB800),
                            null,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/identity_camera',
                                arguments: {
                                  'documentType': 'national_id_front',
                                  'userId': 'demo-user',
                                  'onComplete': () => Navigator.pop(context),
                                },
                              );
                            },
                          ),
                          _buildNewFeatureCard(
                            context,
                            'CCTV Grid',
                            'Monitoreo en vivo',
                            Icons.videocam,
                            const Color(0xFFEB1555),
                            '/cctv_grid',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Título de grupos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '📊 Grupos Activos (${dashboard.groups.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Grid de tarjetas de grupos
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final group = dashboard.groups[index];
                      return _buildGroupCard(group, numberFormat);
                    },
                    childCount: dashboard.groups.length,
                  ),
                ),
              ),
              
              // Espaciado final
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(GroupData group, NumberFormat numberFormat) {
    // Seleccionar icono según plataforma
    IconData platformIcon;
    Color platformColor;
    switch (group.platform.toLowerCase()) {
      case 'fansly':
        platformIcon = Icons.favorite;
        platformColor = const Color(0xFFFF6B9D);
        break;
      case 'onlyfans':
        platformIcon = Icons.stars;
        platformColor = const Color(0xFF00F5FF);
        break;
      default:
        platformIcon = Icons.public;
        platformColor = const Color(0xFF9333EA);
    }

    return Card(
      elevation: 8,
      color: const Color(0xFF1A1F3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: platformColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              platformColor.withOpacity(0.05),
              platformColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header: Nombre y Plataforma
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: platformColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: platformColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(platformIcon, color: platformColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        group.platform,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: platformColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Pago por Miembro (Dato principal)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago por Miembro',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  numberFormat.format(group.payoutPerMemberCop),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Detalles: Tokens y Miembros
            Row(
              children: [
                Expanded(
                  child: _buildDetailChip(
                    Icons.toll,
                    'Tokens',
                    '${group.totalTokens.toStringAsFixed(0)}',
                    const Color(0xFF00F5FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailChip(
                    Icons.people,
                    'Miembros',
                    '${group.membersCount}',
                    const Color(0xFFFF6B9D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String? route, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? (route != null ? () => Navigator.pushNamed(context, route) : null),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

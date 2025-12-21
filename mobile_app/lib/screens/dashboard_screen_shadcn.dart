import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

// Provider para los datos del dashboard
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getDashboardData();
});

/// Dashboard Principal - Rediseñado con Shadcn UI
/// Enterprise minimalist design con Zinc palette
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final numberFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: dashboardAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error, ref),
        data: (dashboard) => _buildDashboardContent(context, dashboard, numberFormat, ref),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFAFAFA)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando dashboard...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF4444),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFAFAFA),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 24),
            ShadButton(
              onPressed: () => ref.refresh(dashboardProvider),
              icon: const Icon(Icons.refresh, size: 18),
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardData dashboard,
    NumberFormat numberFormat,
    WidgetRef ref,
  ) {
    return CustomScrollView(
      slivers: [
        // Header
        _buildHeader(context, ref),
        
        // Welcome Card
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: _buildWelcomeCard(dashboard),
          ),
        ),
        
        // Stats Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _buildStatsGrid(dashboard, numberFormat),
          ),
        ),
        
        // Quick Actions
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: _buildQuickActions(context),
          ),
        ),
        
        // Recent Activity
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _buildRecentActivity(dashboard),
          ),
        ),
        
        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF27272A),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Color(0xFFFAFAFA),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Dashboard',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
              ),
            ),
            const Spacer(),
            ShadButton.ghost(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => ref.refresh(dashboardProvider),
            ),
            const SizedBox(width: 8),
            ShadButton.ghost(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              onPressed: () {
                // Notificaciones
              },
            ),
            const SizedBox(width: 8),
            ShadButton.ghost(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () async {
                final apiService = ref.read(apiServiceProvider);
                await apiService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(DashboardData dashboard) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido de vuelta! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAFAFA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aquí está tu resumen de hoy',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 32,
              color: Color(0xFFFAFAFA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardData dashboard, NumberFormat numberFormat) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Generado',
          numberFormat.format(dashboard.totalEarnings),
          Icons.account_balance_wallet,
          const Color(0xFF22C55E),
          '+12.5%',
          true,
        ),
        _buildStatCard(
          'Pago Total',
          numberFormat.format(dashboard.totalPayoutCop),
          Icons.payments,
          const Color(0xFFFAFAFA),
          'TRM: \$${dashboard.trmUsed.toStringAsFixed(0)}',
          false,
        ),
        _buildStatCard(
          'Modelos Activos',
          dashboard.totalModels.toString(),
          Icons.people,
          const Color(0xFF3B82F6),
          '+3 este mes',
          true,
        ),
        _buildStatCard(
          'Sesiones',
          dashboard.totalSessions.toString(),
          Icons.calendar_today,
          const Color(0xFFA855F7),
          'En progreso',
          false,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    String subtitle,
    bool showTrend,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              if (showTrend)
                const Icon(
                  Icons.trending_up,
                  size: 20,
                  color: Color(0xFF22C55E),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF71717A),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: showTrend ? const Color(0xFF22C55E) : const Color(0xFF71717A),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAFAFA),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionButton(
              context,
              'Registrar Modelo',
              Icons.person_add_outlined,
              () => Navigator.pushNamed(context, '/register_model'),
            ),
            _buildActionButton(
              context,
              'Ver Grupos',
              Icons.group_outlined,
              () => Navigator.pushNamed(context, '/groups'),
            ),
            _buildActionButton(
              context,
              'Finanzas',
              Icons.trending_up,
              () => Navigator.pushNamed(context, '/financial_planning'),
            ),
            _buildActionButton(
              context,
              'Mi Perfil',
              Icons.person_outlined,
              () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ShadButton.outline(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFAFAFA)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFAFAFA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(DashboardData dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Actividad Reciente',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFAFAFA),
              ),
            ),
            const Spacer(),
            ShadButton.ghost(
              onPressed: () {},
              child: Text(
                'Ver todo',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          'Nuevo modelo registrado',
          'María García se unió al equipo',
          Icons.person_add,
          '2h',
        ),
        _buildActivityItem(
          'Pago procesado',
          'Transferencia exitosa de \$450,000',
          Icons.payment,
          '5h',
        ),
        _buildActivityItem(
          'Sesión completada',
          'Sesión fotográfica en Medellín',
          Icons.camera_alt,
          '1d',
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFFAFAFA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFAFAFA),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}

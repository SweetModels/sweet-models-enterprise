import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/web3_service.dart';

/// Pantalla de Finanzas - Dashboard financiero con Web3
/// Diseño enterprise minimalista usando Shadcn UI Zinc palette
/// Conectado con Web3Service para wallet real
class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen> {
  String _selectedPeriod = '30d';
  bool _isConnecting = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: CustomScrollView(
        slivers: [
          // Header
          _buildHeader(),
          
          // Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildBalanceCard(),
            ),
          ),
          
          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildQuickActions(),
            ),
          ),
          
          // Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildStatsSection(),
            ),
          ),
          
          // Recent Transactions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTransactionsSection(),
            ),
          ),
          
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            Text(
              'Finanzas',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
              ),
            ),
            const Spacer(),
            ShadButton.ghost(
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
              onPressed: _isConnecting ? null : _connectWallet,
            ),
            const SizedBox(width: 8),
            ShadButton.ghost(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              onPressed: () {
                // Notificaciones
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFFFAFAFA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Balance Total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF71717A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '\$24,589.42',
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFAFAFA),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildWalletInfo(),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildPeriodButton('7d'),
              const SizedBox(width: 8),
              _buildPeriodButton('30d'),
              const SizedBox(width: 8),
              _buildPeriodButton('90d'),
              const SizedBox(width: 8),
              _buildPeriodButton('1y'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo() {
    final web3Service = ref.watch(web3ServiceProvider);
    
    if (web3Service.isConnected) {
      final address = web3Service.currentAddress;
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF22C55E),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(width: 6),
                Text(
                  'Conectado',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: address));
                _showSnackBar('📋 Dirección copiada', isSuccess: true);
              },
              child: Text(
                '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF71717A)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              _showSnackBar('📋 Dirección copiada', isSuccess: true);
            },
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Text(
            'Wallet no conectada',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(width: 12),
          ShadButton(
            onPressed: _isConnecting ? null : _connectWallet,
            size: ShadButtonSize.sm,
            child: _isConnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF09090B),
                      ),
                    ),
                  )
                : Text(
                    'Conectar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      );
    }
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: ShadButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        backgroundColor: isSelected
            ? const Color(0xFFFAFAFA)
            : const Color(0xFF27272A),
        child: Text(
          period,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF09090B)
                : const Color(0xFFFAFAFA),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionButton(Icons.send, 'Enviar'),
        const SizedBox(width: 12),
        _buildActionButton(Icons.call_received, 'Recibir'),
        const SizedBox(width: 12),
        _buildActionButton(Icons.swap_horiz, 'Cambiar'),
        const SizedBox(width: 12),
        _buildActionButton(Icons.add, 'Comprar'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Expanded(
      child: ShadButton.outline(
        onPressed: () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: const Color(0xFFFAFAFA)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFFAFAFA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAFAFA),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Ingresos', '\$12,450', '+8.2%', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Gastos', '\$3,120', '-2.1%', false)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFAFAFA),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Transacciones Recientes',
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
                'Ver todas',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTransactionItem(
          'Pago recibido',
          'De Sophie Anderson',
          '+\$450.00',
          '2h',
          Icons.call_received,
          true,
        ),
        _buildTransactionItem(
          'Suscripción Premium',
          'Renovación mensual',
          '-\$29.99',
          '1d',
          Icons.credit_card,
          false,
        ),
        _buildTransactionItem(
          'Recompensa NFT',
          'Sweet Models Badge',
          '+\$120.50',
          '3d',
          Icons.emoji_events,
          true,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    String time,
    IconData icon,
    bool isPositive,
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
              color: const Color(0xFFFAFAFA),
              size: 20,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFFAFAFA),
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
        ],
      ),
    );
  }

  // Conectar Web3 Wallet
  Future<void> _connectWallet() async {
    setState(() => _isConnecting = true);

    try {
      final web3Service = ref.read(web3ServiceProvider);
      await web3Service.connectWallet();

      if (mounted && web3Service.isConnected) {
        final address = web3Service.currentAddress;
        _showSnackBar('✅ Wallet conectado: ${address.substring(0, 8)}...', isSuccess: true);
        
        // Actualizar balance
        setState(() {}); // Refresh UI
      } else {
        _showSnackBar('❌ No se pudo conectar la wallet', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('❌ Error: ${e.toString()}', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

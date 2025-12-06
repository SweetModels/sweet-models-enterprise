// ============================================================================
// Sweet Models Enterprise - Model Profile with Payout
// Pantalla de perfil de modelo con opción de liquidar saldo
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/payout_service.dart';

class ModelProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const ModelProfileScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  ConsumerState<ModelProfileScreen> createState() => _ModelProfileScreenState();
}

class _ModelProfileScreenState extends ConsumerState<ModelProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userBalance = ref.watch(userBalanceProvider(widget.userId));
    final payoutHistory = ref.watch(payoutHistoryProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil: ${widget.userName}'),
        backgroundColor: Colors.purple,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userBalanceProvider(widget.userId));
          ref.invalidate(payoutHistoryProvider(widget.userId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              userBalance.when(
                data: (balance) => _buildBalanceCard(balance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
              
              const SizedBox(height: 24),
              
              // Payout History
              Text(
                'Historial de Pagos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              payoutHistory.when(
                data: (history) => _buildPayoutHistoryList(history),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(UserBalanceResponse balance) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Pendiente',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(balance.pendingBalance),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (balance.pendingBalance > 0)
                  ElevatedButton.icon(
                    onPressed: () => _showPayoutModal(balance),
                    icon: const Icon(Icons.payments),
                    label: const Text('Liquidar Saldo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            const Divider(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Ganado',
                  currencyFormat.format(balance.totalEarned),
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Pagado',
                  currencyFormat.format(balance.totalPaid),
                  Icons.payment,
                  Colors.orange,
                ),
              ],
            ),
            
            if (balance.lastPayoutDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Último pago: ${_formatDate(balance.lastPayoutDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutHistoryList(PayoutHistoryResponse history) {
    if (history.payouts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay pagos registrados',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de pagos: ${history.totalCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Acumulado: \$${history.totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...history.payouts.map((payout) => _buildPayoutCard(payout)).toList(),
      ],
    );
  }

  Widget _buildPayoutCard(PayoutRecord payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMethodColor(payout.method),
          child: Icon(
            _getMethodIcon(payout.method),
            color: Colors.white,
          ),
        ),
        title: Text(
          '\$${payout.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método: ${_getMethodLabel(payout.method)}'),
            if (payout.transactionRef != null)
              Text(
                'Ref: ${payout.transactionRef}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (payout.notes != null)
              Text(
                payout.notes!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _formatDate(payout.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: payout.receiptUrl != null
            ? IconButton(
                icon: const Icon(Icons.receipt, color: Colors.purple),
                onPressed: () {
                  // TODO: Open receipt PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recibo: ${payout.receiptUrl}')),
                  );
                },
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutModal(UserBalanceResponse balance) {
    final TextEditingController amountController = TextEditingController(
      text: balance.pendingBalance.toStringAsFixed(2),
    );
    final TextEditingController notesController = TextEditingController();
    final TextEditingController txRefController = TextEditingController();
    String selectedMethod = 'binance';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.purple),
            const SizedBox(width: 12),
            const Text('Liquidar Saldo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo disponible: \$${balance.pendingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'Ingresa el monto a liquidar',
                ),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'binance', child: Text('💰 Binance')),
                  DropdownMenuItem(value: 'bank', child: Text('🏦 Transferencia Bancaria')),
                  DropdownMenuItem(value: 'cash', child: Text('💵 Efectivo')),
                  DropdownMenuItem(value: 'other', child: Text('📝 Otro')),
                ],
                onChanged: (value) {
                  if (value != null) selectedMethod = value;
                },
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: txRefController,
                decoration: const InputDecoration(
                  labelText: 'Referencia de transacción (opcional)',
                  hintText: 'TX12345678',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Ej: Pago quincenal, Binance TX...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _confirmPayout(
              balance,
              amountController.text,
              selectedMethod,
              txRefController.text,
              notesController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayout(
    UserBalanceResponse balance,
    String amountStr,
    String method,
    String txRef,
    String notes,
  ) async {
    final amount = double.tryParse(amountStr);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monto inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (amount > balance.pendingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto excede el saldo disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Procesando pago...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ref.read(payoutNotifierProvider.notifier).processPayout(
        userId: widget.userId,
        amount: amount,
        method: method,
        transactionRef: txRef.isEmpty ? null : txRef,
        notes: notes.isEmpty ? null : notes,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      final payoutState = ref.read(payoutNotifierProvider);
      
      payoutState.when(
        data: (result) {
          if (result != null) {
            _showSuccessAnimation(result);
            // Refresh data
            ref.invalidate(userBalanceProvider(widget.userId));
            ref.invalidate(payoutHistoryProvider(widget.userId));
          }
        },
        loading: () {},
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar pago: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showSuccessAnimation(PayoutResponse result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Pago Exitoso!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${result.amount.toStringAsFixed(2)} pagados',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Nuevo saldo: \$${result.newPendingBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (result.receiptUrl != null) ...[
              const SizedBox(height: 12),
              Text(
                'Recibo generado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    // Auto-close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'binance':
        return Icons.currency_bitcoin;
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'binance':
        return Colors.orange;
      case 'bank':
        return Colors.blue;
      case 'cash':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'binance':
        return 'Binance';
      case 'bank':
        return 'Transferencia Bancaria';
      case 'cash':
        return 'Efectivo';
      case 'other':
        return 'Otro';
      default:
        return method;
    }
  }
}

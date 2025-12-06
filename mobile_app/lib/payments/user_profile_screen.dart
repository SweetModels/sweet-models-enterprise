import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'payments_provider.dart';
import 'payout_dialog.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String token;
  final bool isAdmin;
  const UserProfileScreen({Key? key, required this.userId, required this.token, required this.isAdmin}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late PaymentsProvider provider;

  @override
  void initState() {
    super.initState();
    provider = PaymentsProvider(userId: widget.userId, token: widget.token);
    provider.fetchBalance();
    provider.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<PaymentsProvider>(
        builder: (context, provider, _) => Scaffold(
          appBar: AppBar(title: const Text('Perfil del Modelo')),
          body: Column(
            children: [
              if (widget.isAdmin)
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text('Saldo Pendiente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          '\$${provider.pendingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: provider.pendingBalance > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payments, size: 28),
                          label: const Text('💸 LIQUIDAR PAGO', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: provider.pendingBalance > 0
                              ? () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx) => PayoutDialog(provider: provider),
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Datos'),
                          Tab(text: 'Historial de Pagos'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Center(child: Text('Datos del modelo aquí')),
                            provider.isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount: provider.payoutHistory.length,
                                    itemBuilder: (ctx, i) {
                                      final p = provider.payoutHistory[i];
                                      return ListTile(
                                        leading: Icon(Icons.history),
                                        title: Text('\$${p['amount']} - ${p['method']}'),
                                        subtitle: Text('${p['created_at']}'),
                                        trailing: p['reference_id'] != null
                                            ? Text('Ref: ${p['reference_id']}')
                                            : null,
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayoutHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const PayoutHistoryScreen({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Pagos')),
      body: history.isEmpty
          ? const Center(child: Text('No hay pagos registrados'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final payout = history[index];
                final date = DateTime.parse(payout['created_at']);
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                final amount = payout['amount'] ?? 0.0;
                final method = payout['method'] ?? 'N/A';
                final reference = payout['reference_id'];
                final processedBy = payout['processed_by_email'] ?? 'Admin';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Método: $method'),
                        Text('Fecha: $formattedDate'),
                        if (reference != null) Text('Ref: $reference'),
                        Text('Procesado por: $processedBy', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'payments_provider.dart';

class PayoutDialog extends StatefulWidget {
  final PaymentsProvider provider;
  const PayoutDialog({Key? key, required this.provider}) : super(key: key);

  @override
  State<PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends State<PayoutDialog> {
  final _formKey = GlobalKey<FormState>();
  double? _amount;
  String? _method;
  String? _reference;
  bool _success = false;

  final List<String> _methods = ['Binance', 'Nequi', 'Efectivo'];

  @override
  Widget build(BuildContext context) {
    return _success
        ? Center(
            child: Lottie.asset(
              'assets/lottie/success_check.json',
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pop();
                });
              },
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saldo actual: \$${widget.provider.pendingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: widget.provider.pendingBalance.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Monto a Pagar',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = double.tryParse(v ?? '');
                      if (value == null || value <= 0 || value > widget.provider.pendingBalance) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                    onSaved: (v) => _amount = double.tryParse(v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Método',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: _methods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    validator: (v) => v == null ? 'Selecciona un método' : null,
                    onChanged: (v) => _method = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Referencia/TXID',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    onSaved: (v) => _reference = v,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirmar Transacción'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        final ok = await widget.provider.processPayout(
                          _amount ?? widget.provider.pendingBalance,
                          _method ?? '',
                          _reference ?? '',
                        );
                        if (ok) {
                          setState(() => _success = true);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
  }
}

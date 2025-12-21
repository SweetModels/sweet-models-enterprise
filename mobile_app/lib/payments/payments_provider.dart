import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentsProvider extends ChangeNotifier {
  double pendingBalance = 0.0;
  List<Map<String, dynamic>> payoutHistory = [];
  bool isLoading = false;

  final String userId;
  final String token;

  PaymentsProvider({required this.userId, required this.token});

  Future<void> fetchBalance() async {
    isLoading = true;
    notifyListeners();
    final url = Uri.parse('https://sweet-models-enterprise-production.up.railway.app/api/admin/user-balance/$userId');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      pendingBalance = (data['pending_balance'] ?? 0.0).toDouble();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    isLoading = true;
    notifyListeners();
    final url = Uri.parse('https://sweet-models-enterprise-production.up.railway.app/api/admin/payouts/$userId');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      payoutHistory = List<Map<String, dynamic>>.from(data['payouts'] ?? []);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> processPayout(double amount, String method, String reference) async {
    final url = Uri.parse('https://sweet-models-enterprise-production.up.railway.app/api/admin/payout');
    final res = await http.post(url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'amount': amount,
        'method': method,
        'reference_id': reference,
      }),
    );
    if (res.statusCode == 201) {
      await fetchBalance();
      await fetchHistory();
      return true;
    }
    return false;
  }
}

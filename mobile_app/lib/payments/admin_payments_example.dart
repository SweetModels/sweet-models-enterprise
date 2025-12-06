import 'package:flutter/material.dart';
import 'payments/user_profile_screen.dart';

class AdminPaymentsExample extends StatelessWidget {
  const AdminPaymentsExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ejemplo: token y userId del usuario admin
    const String adminToken = "your_admin_jwt_token_here";
    const String userId = "model_user_id_uuid_here";

    return UserProfileScreen(
      userId: userId,
      token: adminToken,
      isAdmin: true,
    );
  }
}

// Uso en main.dart:
// 
// import 'admin_payments_example.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Sweet Models Enterprise',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const AdminPaymentsExample(),
//     );
//   }
// }

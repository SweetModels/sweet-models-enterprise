class User {
  final String id;
  final String email;
  final String password;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

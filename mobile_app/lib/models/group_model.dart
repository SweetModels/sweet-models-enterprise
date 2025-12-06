class Group {
  final String id;
  final String name;
  final String? description;
  final String leaderUserId;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.leaderUserId,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      leaderUserId: json['leader_user_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'leader_user_id': leaderUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

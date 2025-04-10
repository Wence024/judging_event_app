enum UserRole { admin, organizer, judge }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<String> assignedEvents;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.assignedEvents = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'assignedEvents': assignedEvents,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is Map) return [];
      return [];
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role']?.toString(),
        orElse: () => UserRole.judge,
      ),
      assignedEvents: parseStringList(json['assignedEvents']),
    );
  }
}

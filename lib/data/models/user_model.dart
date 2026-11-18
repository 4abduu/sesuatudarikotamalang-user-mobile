enum Role { buyer, creator, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? creatorId;
  final String? applicationId;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.creatorId,
    this.applicationId,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    Role r = Role.buyer;
    if (j['role'] == 'creator') {
      r = Role.creator;
    } else if (j['role'] == 'admin') {
      r = Role.admin;
    }

    return UserModel(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      role: r,
      creatorId: j['creatorId'],
      applicationId: j['applicationId'],
      avatarUrl: j['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role == Role.creator ? 'creator' : (role == Role.admin ? 'admin' : 'buyer'),
    'creatorId': creatorId,
    'applicationId': applicationId,
    'avatarUrl': avatarUrl,
  };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    Role? role,
    String? creatorId,
    String? applicationId,
    String? email,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        creatorId: creatorId ?? this.creatorId,
        applicationId: applicationId ?? this.applicationId,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

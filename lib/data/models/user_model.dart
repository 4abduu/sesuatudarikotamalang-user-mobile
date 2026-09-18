enum Role { buyer, creator }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final Role role;
  final String? creatorId;
  final String? applicationId;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.creatorId,
    this.applicationId,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    password: j['password'] ?? '',
    role: j['role'] == 'creator' ? Role.creator : Role.buyer,
    creatorId: j['creatorId'],
    applicationId: j['applicationId'],
    avatarUrl: j['avatarUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'password': password,
    'role': role == Role.creator ? 'creator' : 'buyer',
    'creatorId': creatorId, 'applicationId': applicationId, 'avatarUrl': avatarUrl,
  };

  UserModel copyWith({String? name, String? avatarUrl, Role? role, String? creatorId, String? applicationId, String? email, String? password}) =>
    UserModel(
      id: id, name: name ?? this.name, email: email ?? this.email,
      password: password ?? this.password, role: role ?? this.role,
      creatorId: creatorId ?? this.creatorId, applicationId: applicationId ?? this.applicationId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
}

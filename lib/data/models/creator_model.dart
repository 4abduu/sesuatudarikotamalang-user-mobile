class CreatorModel {
  final String id;
  final String name; // brandName atau name
  final String handle;
  final String city;
  final String bio;
  final String specialty;
  final int joinedYear;
  final int productCount;
  final double rating;
  final String accent; // hex for avatar gradient
  final String? avatarUrl;
  final String status;
  final bool isOfficial;

  const CreatorModel({
    required this.id,
    required this.name,
    this.handle = '',
    this.city = 'Malang',
    this.bio = '',
    this.specialty = 'Artisan',
    this.joinedYear = 2024,
    this.productCount = 0,
    this.rating = 5.0,
    this.accent = '8B4513',
    this.avatarUrl,
    this.status = 'aktif',
    this.isOfficial = false,
  });

  factory CreatorModel.fromJson(Map<String, dynamic> j) {
    final brand = j['brandName'] ?? j['name'] ?? 'Kreator';
    final handle = brand.toString().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final year = j['createdAt'] != null
        ? (DateTime.tryParse(j['createdAt'].toString())?.year ?? 2024)
        : 2024;

    return CreatorModel(
      id: j['id'] ?? '',
      name: brand,
      handle: j['handle'] ?? handle,
      city: j['city'] ?? 'Malang',
      bio: j['bio'] ?? '',
      specialty: j['specialty'] ?? 'Artisan',
      joinedYear: (j['joinedYear'] as num?)?.toInt() ?? year,
      productCount: (j['productCount'] as num?)?.toInt() ??
          ((j['products'] as List<dynamic>?)?.length ?? 0),
      rating: (j['rating'] as num?)?.toDouble() ??
          ((j['avgRating'] as num?)?.toDouble() ?? 5.0),
      accent: j['accent'] ?? '8B4513',
      avatarUrl: j['avatarUrl'],
      status: j['status'] ?? 'aktif',
      isOfficial: j['isOfficial'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandName': name,
    'handle': handle,
    'city': city,
    'bio': bio,
    'specialty': specialty,
    'joinedYear': joinedYear,
    'productCount': productCount,
    'rating': rating,
    'accent': accent,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'status': status,
  };
}

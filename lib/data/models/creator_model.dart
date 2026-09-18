class CreatorModel {
  final String id;
  final String name;
  final String handle;
  final String city;
  final String bio;
  final String specialty;
  final int joinedYear;
  final int productCount;
  final double rating;
  final String accent; // hex for avatar gradient
  const CreatorModel({
    required this.id, required this.name, required this.handle, required this.city,
    required this.bio, required this.specialty, required this.joinedYear,
    required this.productCount, required this.rating, required this.accent,
  });
}

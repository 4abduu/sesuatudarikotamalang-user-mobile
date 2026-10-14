enum ApplicationStatus { pending, approved, rejected }

class CreatorApplicationModel {
  final String id;
  final String userId;
  final String applicantName;
  final String contact;
  final String email;
  final String brandName;
  final String description;
  final String category;
  final String submittedAt;
  final ApplicationStatus status;
  final String? rejectReason;

  const CreatorApplicationModel({
    required this.id, required this.userId, required this.applicantName,
    required this.contact, required this.email, required this.brandName,
    required this.description, required this.category, required this.submittedAt,
    required this.status, this.rejectReason,
  });

  factory CreatorApplicationModel.fromJson(Map<String, dynamic> j) {
    final statusStr = (j['status'] ?? '').toString().toLowerCase();
    final ApplicationStatus parsedStatus;
    if (statusStr == 'approved' || statusStr == 'diterima') {
      parsedStatus = ApplicationStatus.approved;
    } else if (statusStr == 'rejected' || statusStr == 'ditolak') {
      parsedStatus = ApplicationStatus.rejected;
    } else {
      parsedStatus = ApplicationStatus.pending;
    }

    return CreatorApplicationModel(
      id: (j['id'] ?? '').toString(),
      userId: (j['userId'] ?? '').toString(),
      applicantName: j['applicantName'] as String? ?? '',
      contact: j['contact'] as String? ?? '',
      email: j['email'] as String? ?? '',
      brandName: j['brandName'] as String? ?? '',
      description: j['description'] as String? ?? '',
      category: j['category'] as String? ?? (j['categoryId'] as String? ?? ''),
      submittedAt: (j['submittedAt'] ?? '').toString(),
      status: parsedStatus,
      rejectReason: j['rejectReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'applicantName': applicantName,
    'contact': contact,
    'email': email,
    'brandName': brandName,
    'description': description,
    'category': category,
    'submittedAt': submittedAt,
    'status': status == ApplicationStatus.approved
        ? 'diterima'
        : status == ApplicationStatus.rejected
            ? 'ditolak'
            : 'pending',
    'rejectReason': rejectReason,
  };
}

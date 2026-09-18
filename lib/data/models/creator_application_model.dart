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

  factory CreatorApplicationModel.fromJson(Map<String, dynamic> j) =>
    CreatorApplicationModel(
      id: j['id'], userId: j['userId'], applicantName: j['applicantName'],
      contact: j['contact'], email: j['email'], brandName: j['brandName'],
      description: j['description'], category: j['category'],
      submittedAt: j['submittedAt'],
      status: j['status'] == 'approved' ? ApplicationStatus.approved
            : j['status'] == 'rejected' ? ApplicationStatus.rejected
            : ApplicationStatus.pending,
      rejectReason: j['rejectReason'],
    );

  Map<String, dynamic> toJson() => {
    'id': id, 'userId': userId, 'applicantName': applicantName, 'contact': contact,
    'email': email, 'brandName': brandName, 'description': description,
    'category': category, 'submittedAt': submittedAt,
    'status': status == ApplicationStatus.approved ? 'approved'
            : status == ApplicationStatus.rejected ? 'rejected' : 'pending',
    'rejectReason': rejectReason,
  };
}

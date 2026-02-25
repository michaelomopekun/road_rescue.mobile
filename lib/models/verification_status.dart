enum VerificationStatusType { notStarted, pending, approved, rejected }

class VerificationStatus {
  final VerificationStatusType status;
  final String? serviceProviderId;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  VerificationStatus({
    required this.status,
    this.serviceProviderId,
    this.submittedAt,
    this.approvedAt,
    this.rejectionReason,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    final statusStr = json['verificationStatus'] as String?;
    VerificationStatusType statusType = VerificationStatusType.notStarted;

    if (statusStr != null) {
      switch (statusStr.toUpperCase()) {
        case 'PENDING':
          statusType = VerificationStatusType.pending;
          break;
        case 'APPROVED':
          statusType = VerificationStatusType.approved;
          break;
        case 'REJECTED':
          statusType = VerificationStatusType.rejected;
          break;
        default:
          statusType = VerificationStatusType.notStarted;
      }
    }

    return VerificationStatus(
      status: statusType,
      serviceProviderId: json['id'] as String?,
      submittedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      approvedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.toString().split('.').last,
      'serviceProviderId': serviceProviderId,
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == VerificationStatusType.pending;
  bool get isApproved => status == VerificationStatusType.approved;
  bool get isNotStarted => status == VerificationStatusType.notStarted;
  bool get isRejected => status == VerificationStatusType.rejected;
}

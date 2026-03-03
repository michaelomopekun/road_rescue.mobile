enum RequestStatus {
  PENDING,
  ACCEPTED,
  ARRIVED,
  QUOTED,
  IN_PROGRESS,
  COMPLETED,
  PAID,
  CANCELLED;

  String get driverLabel {
    switch (this) {
      case RequestStatus.PENDING:
        return 'Searching Mechanics';
      case RequestStatus.ACCEPTED:
        return 'Mechanic Accepted';
      case RequestStatus.ARRIVED:
        return 'Mechanic Arrived';
      case RequestStatus.QUOTED:
        return 'Quotation Received';
      case RequestStatus.IN_PROGRESS:
        return 'Service In Progress';
      case RequestStatus.COMPLETED:
        return 'Service Completed';
      case RequestStatus.PAID:
        return 'Paid';
      case RequestStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  String get mechanicLabel {
    switch (this) {
      case RequestStatus.PENDING:
        return 'New Request';
      case RequestStatus.ACCEPTED:
        return 'Accepted';
      case RequestStatus.ARRIVED:
        return 'Arrived';
      case RequestStatus.QUOTED:
        return 'Waiting Approval';
      case RequestStatus.IN_PROGRESS:
        return 'In Progress';
      case RequestStatus.COMPLETED:
        return 'Waiting Payment';
      case RequestStatus.PAID:
        return 'Paid';
      case RequestStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  bool isValidTransition(RequestStatus to) {
    if (this == RequestStatus.CANCELLED) return false;
    if (to == RequestStatus.CANCELLED) return true; // Can cancel from anywhere

    switch (this) {
      case RequestStatus.PENDING:
        return to == RequestStatus.ACCEPTED;
      case RequestStatus.ACCEPTED:
        return to == RequestStatus.ARRIVED;
      case RequestStatus.ARRIVED:
        return to == RequestStatus.QUOTED;
      case RequestStatus.QUOTED:
        // can transition to IN_PROGRESS (approved) or CANCELLED (rejected)
        return to == RequestStatus.IN_PROGRESS;
      case RequestStatus.IN_PROGRESS:
        return to == RequestStatus.COMPLETED;
      case RequestStatus.COMPLETED:
        return to == RequestStatus.PAID;
      case RequestStatus.PAID:
        return false;
      case RequestStatus.CANCELLED:
        return false;
    }
  }

  static RequestStatus fromString(String statusStr) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == statusStr.toUpperCase(),
      orElse: () => RequestStatus.PENDING,
    );
  }
}

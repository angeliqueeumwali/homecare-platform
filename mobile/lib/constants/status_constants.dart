class ServiceRequestStatus {
  static const String pending = 'PENDING';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}

class ServiceRequestItemStatus {
  static const String pending = 'PENDING';
  static const String searchingProvider = 'SEARCHING_PROVIDER';
  static const String providerAssigned = 'PROVIDER_ASSIGNED';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}

class AssignmentStatus {
  static const String pending = 'PENDING';
  static const String accepted = 'ACCEPTED';
  static const String declined = 'DECLINED';
  static const String onTheWay = 'ON_THE_WAY';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}

class QuoteStatus {
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
}

class PaymentStatus {
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String paid = 'PAID';
  static const String failed = 'FAILED';
  static const String refunded = 'REFUNDED';
}

class PaymentMethod {
  static const String mobileMoney = 'MOBILE_MONEY';
  static const String card = 'CARD';
  static const String cash = 'CASH';
}

class IssueStatus {
  static const String open = 'OPEN';
  static const String underReview = 'UNDER_REVIEW';
  static const String resolved = 'RESOLVED';
}

class NotificationType {
  static const String serviceRequest = 'SERVICE_REQUEST';
  static const String assignment = 'ASSIGNMENT';
  static const String quote = 'QUOTE';
  static const String payment = 'PAYMENT';
  static const String issue = 'ISSUE';
  static const String general = 'GENERAL';
}

class ProviderApprovalStatus {
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
}

String getStatusDisplayName(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'Pending';
    case 'IN_PROGRESS':
      return 'In Progress';
    case 'COMPLETED':
      return 'Completed';
    case 'CANCELLED':
      return 'Cancelled';
    case 'SEARCHING_PROVIDER':
      return 'Searching Provider';
    case 'PROVIDER_ASSIGNED':
      return 'Provider Assigned';
    case 'ACCEPTED':
      return 'Accepted';
    case 'DECLINED':
      return 'Declined';
    case 'ON_THE_WAY':
      return 'On the Way';
    case 'APPROVED':
      return 'Approved';
    case 'REJECTED':
      return 'Rejected';
    case 'PROCESSING':
      return 'Processing';
    case 'PAID':
      return 'Paid';
    case 'FAILED':
      return 'Failed';
    case 'REFUNDED':
      return 'Refunded';
    case 'UNDER_REVIEW':
      return 'Under Review';
    case 'RESOLVED':
      return 'Resolved';
    case 'OPEN':
      return 'Open';
    default:
      return status;
  }
}

String getStatusColorValue(String status) {
  final upper = status.toUpperCase();
  if (upper == 'COMPLETED' ||
      upper == 'APPROVED' ||
      upper == 'PAID' ||
      upper == 'RESOLVED' ||
      upper == 'ACCEPTED') {
    return 'success';
  }
  if (upper == 'FAILED' ||
      upper == 'DECLINED' ||
      upper == 'REJECTED' ||
      upper == 'CANCELLED') {
    return 'error';
  }
  if (upper == 'PENDING') {
    return 'warning';
  }
  if (upper == 'IN_PROGRESS' ||
      upper == 'PROCESSING' ||
      upper == 'ON_THE_WAY' ||
      upper == 'UNDER_REVIEW' ||
      upper == 'SEARCHING_PROVIDER') {
    return 'info';
  }
  return 'default';
}

/// Ordered happy-path steps for a service request, using only the values the
/// backend actually stores on `service_request_items.status`.
const List<String> serviceRequestTimelineSteps = <String>[
  ServiceRequestItemStatus.pending,
  ServiceRequestItemStatus.searchingProvider,
  ServiceRequestItemStatus.providerAssigned,
  ServiceRequestItemStatus.inProgress,
  ServiceRequestItemStatus.completed,
];

/// Ordered happy-path steps for a provider assignment, from
/// `AssignmentStatus` on the backend.
const List<String> assignmentTimelineSteps = <String>[
  AssignmentStatus.pending,
  AssignmentStatus.accepted,
  AssignmentStatus.onTheWay,
  AssignmentStatus.inProgress,
  AssignmentStatus.completed,
];

/// Index of [status] inside [steps], or -1 when the status is off the happy
/// path (for example CANCELLED, DECLINED or REJECTED).
int timelineStepIndex(String status, List<String> steps) {
  final index = steps.indexOf(status.toUpperCase());
  if (index != -1) return index;
  return steps.indexWhere((step) => step.toUpperCase() == status.toUpperCase());
}

/// True when the status means the record will not progress any further.
/// CANCELLED is shared by requests, items and assignments, so it is listed
/// once.
bool isTerminalFailureStatus(String status) {
  const failures = <String>{
    ServiceRequestStatus.cancelled,
    AssignmentStatus.declined,
    QuoteStatus.rejected,
  };
  return failures.contains(status.toUpperCase());
}

/// True when an assignment has finished and will not change again.
bool isFinishedAssignmentStatus(String status) {
  const finished = <String>{
    AssignmentStatus.completed,
    AssignmentStatus.declined,
    AssignmentStatus.cancelled,
  };
  return finished.contains(status.toUpperCase());
}

List<String> assignmentStatusActions(String status) {
  switch (status.toUpperCase()) {
    case AssignmentStatus.pending:
      return <String>[AssignmentStatus.accepted, AssignmentStatus.declined];
    case AssignmentStatus.accepted:
      return <String>[
        AssignmentStatus.onTheWay,
        AssignmentStatus.inProgress,
        AssignmentStatus.cancelled,
      ];
    case AssignmentStatus.onTheWay:
      return <String>[AssignmentStatus.inProgress, AssignmentStatus.cancelled];
    case AssignmentStatus.inProgress:
      return <String>[AssignmentStatus.completed, AssignmentStatus.cancelled];
    default:
      // COMPLETED, DECLINED and CANCELLED are all terminal.
      return const <String>[];
  }
}

String assignmentStatusActionLabel(String status) {
  switch (status.toUpperCase()) {
    case AssignmentStatus.accepted:
      return 'Accept job';
    case AssignmentStatus.declined:
      return 'Decline job';
    case AssignmentStatus.onTheWay:
      return 'On the way';
    case AssignmentStatus.inProgress:
      return 'Start work';
    case AssignmentStatus.completed:
      return 'Mark completed';
    case AssignmentStatus.cancelled:
      return 'Cancel job';
    default:
      return getStatusDisplayName(status);
  }
}

bool assignmentStatusNeedsConfirmation(String status) {
  const confirm = <String>{
    AssignmentStatus.declined,
    AssignmentStatus.onTheWay,
    AssignmentStatus.completed,
    AssignmentStatus.cancelled,
  };
  return confirm.contains(status.toUpperCase());
}

const List<String> assignmentStatusFilters = <String>[
  AssignmentStatus.pending,
  AssignmentStatus.accepted,
  AssignmentStatus.onTheWay,
  AssignmentStatus.inProgress,
  AssignmentStatus.completed,
  AssignmentStatus.declined,
  AssignmentStatus.cancelled,
];

bool isAssignmentOpen(String status) {
  const open = <String>{
    AssignmentStatus.pending,
    AssignmentStatus.accepted,
    AssignmentStatus.onTheWay,
    AssignmentStatus.inProgress,
  };
  return open.contains(status.toUpperCase());
}

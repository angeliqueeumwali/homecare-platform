class QuoteModel {
  final String id;
  final String serviceRequestId;
  final String serviceRequestItemId;
  final String providerId;
  final String amount;
  final String currency;
  final String status;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  QuoteModel({
    required this.id,
    required this.serviceRequestId,
    required this.serviceRequestItemId,
    required this.providerId,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      serviceRequestItemId: json['service_request_item_id'] as String,
      providerId: json['provider_id'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_request_id': serviceRequestId,
    'service_request_item_id': serviceRequestItemId,
    'provider_id': providerId,
    'amount': amount,
    'currency': currency,
    'status': status,
    'description': description,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class QuoteCreateRequest {
  final String serviceRequestId;
  final String serviceRequestItemId;
  final String amount;
  final String currency;
  final String? description;

  QuoteCreateRequest({
    required this.serviceRequestId,
    required this.serviceRequestItemId,
    required this.amount,
    this.currency = 'RWF',
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'service_request_id': serviceRequestId,
    'service_request_item_id': serviceRequestItemId,
    'amount': amount,
    'currency': currency,
    if (description != null) 'description': description,
  };
}

class PaymentModel {
  final String id;
  final String serviceRequestId;
  final String quoteId;
  final String customerId;
  final String amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? transactionReference;
  final String? paidAt;
  final String? createdAt;
  final String? updatedAt;

  PaymentModel({
    required this.id,
    required this.serviceRequestId,
    required this.quoteId,
    required this.customerId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.transactionReference,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      quoteId: json['quote_id'] as String,
      customerId: json['customer_id'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      transactionReference: json['transaction_reference'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class PaymentCreateRequest {
  final String serviceRequestId;
  final String quoteId;
  final String amount;
  final String currency;
  final String paymentMethod;

  PaymentCreateRequest({
    required this.serviceRequestId,
    required this.quoteId,
    required this.amount,
    this.currency = 'RWF',
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'service_request_id': serviceRequestId,
    'quote_id': quoteId,
    'amount': amount,
    'currency': currency,
    'payment_method': paymentMethod,
  };
}

class PaymentStatusUpdateRequest {
  final String status;
  final String? transactionReference;

  PaymentStatusUpdateRequest({required this.status, this.transactionReference});

  Map<String, dynamic> toJson() => {
    'status': status,
    if (transactionReference != null)
      'transaction_reference': transactionReference,
  };
}

class FeePayment {
  FeePayment({
    required this.id,
    required this.amount,
    required this.feeType,
    required this.paymentDate,
    required this.note,
    required this.loggedByName,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String feeType;
  final DateTime paymentDate;
  final String? note;
  final String loggedByName;
  final DateTime createdAt;

  factory FeePayment.fromJson(Map<String, dynamic> j) => FeePayment(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        feeType: j['fee_type'] as String,
        paymentDate: DateTime.parse(j['payment_date'] as String),
        note: j['note'] as String?,
        loggedByName: j['logged_by_name'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

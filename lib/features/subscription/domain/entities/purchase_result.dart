class PurchaseResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? transactionId;

  PurchaseResult({
    required this.isSuccess,
    this.errorMessage,
    this.transactionId,
  });
}

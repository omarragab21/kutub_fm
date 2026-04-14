import 'package:flutter/foundation.dart';
import 'package:kutub_fm/features/subscription/domain/entities/purchase_result.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';

class ApplePayDataSource {
  Future<PurchaseResult> processPurchase(SubscriptionPlan plan) async {
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      return PurchaseResult(
        isSuccess: true,
        transactionId:
            'mock_apple_pay_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    return PurchaseResult(
      isSuccess: false,
      errorMessage: 'Apple Pay integration is not implemented yet',
    );
  }
}

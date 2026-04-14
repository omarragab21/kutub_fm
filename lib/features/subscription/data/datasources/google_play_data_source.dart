import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kutub_fm/features/subscription/domain/entities/purchase_result.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';

class GooglePlayDataSource {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  Future<PurchaseResult> processPurchase(SubscriptionPlan plan) async {
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      return PurchaseResult(
        isSuccess: true,
        transactionId: 'mock_gp_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      return PurchaseResult(
        isSuccess: false,
        errorMessage: 'Store is not available',
      );
    }

    try {
      // For a real app, query products first, then purchase
      // final Set<String> kIds = <String>{plan.id};
      // final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
      // if (response.notFoundIDs.isNotEmpty) { ... }

      // Simulate success for this demo
      await Future.delayed(const Duration(seconds: 2));
      return PurchaseResult(
        isSuccess: true,
        transactionId: 'simulate_gp_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      return PurchaseResult(isSuccess: false, errorMessage: e.toString());
    }
  }
}

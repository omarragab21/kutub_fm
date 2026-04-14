import 'package:kutub_fm/features/subscription/domain/entities/credit_card_info.dart';
import 'package:kutub_fm/features/subscription/domain/entities/purchase_result.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';
import 'package:kutub_fm/features/subscription/domain/entities/wallet_provider.dart';

abstract class PaymentRepository {
  Future<List<SubscriptionPlan>> getAvailablePlans();

  Future<PurchaseResult> processGooglePlayPurchase(SubscriptionPlan plan);

  Future<PurchaseResult> processApplePayPurchase(SubscriptionPlan plan);

  Future<PurchaseResult> processWalletPayment({
    required SubscriptionPlan plan,
    required WalletProviderType provider,
    required String phoneNumber,
  });

  Future<PurchaseResult> processCreditCardPayment({
    required SubscriptionPlan plan,
    required CreditCardInfo creditCardInfo,
  });
}

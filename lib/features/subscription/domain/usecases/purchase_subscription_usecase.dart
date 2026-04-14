import 'package:kutub_fm/features/subscription/domain/entities/payment_method.dart';
import 'package:kutub_fm/features/subscription/domain/entities/purchase_result.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';
import 'package:kutub_fm/features/subscription/domain/entities/wallet_provider.dart';
import 'package:kutub_fm/features/subscription/domain/entities/credit_card_info.dart';
import 'package:kutub_fm/features/subscription/domain/repositories/payment_repository.dart';

class PurchaseSubscriptionUseCase {
  final PaymentRepository repository;

  PurchaseSubscriptionUseCase(this.repository);

  Future<PurchaseResult> call({
    required SubscriptionPlan plan,
    required PaymentMethodType method,
    WalletProviderType? walletProvider,
    String? phoneNumber,
    CreditCardInfo? creditCardInfo,
  }) async {
    switch (method) {
      case PaymentMethodType.googlePlay:
        return await repository.processGooglePlayPurchase(plan);
      case PaymentMethodType.applePay:
        return await repository.processApplePayPurchase(plan);
      case PaymentMethodType.wallet:
        if (walletProvider == null ||
            phoneNumber == null ||
            phoneNumber.isEmpty) {
          return PurchaseResult(
            isSuccess: false,
            errorMessage: 'Invalid wallet details',
          );
        }
        return await repository.processWalletPayment(
          plan: plan,
          provider: walletProvider,
          phoneNumber: phoneNumber,
        );
      case PaymentMethodType.creditCard:
        if (creditCardInfo == null) {
          return PurchaseResult(
            isSuccess: false,
            errorMessage: 'Invalid credit card info',
          );
        }
        return await repository.processCreditCardPayment(
          plan: plan,
          creditCardInfo: creditCardInfo,
        );
    }
  }
}

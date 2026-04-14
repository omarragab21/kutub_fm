import 'package:kutub_fm/features/subscription/data/datasources/apple_pay_data_source.dart';
import 'package:kutub_fm/features/subscription/data/datasources/credit_card_payment_data_source.dart';
import 'package:kutub_fm/features/subscription/data/datasources/google_play_data_source.dart';
import 'package:kutub_fm/features/subscription/data/datasources/wallet_payment_data_source.dart';
import 'package:kutub_fm/features/subscription/data/mocks/subscription_mock_data.dart';
import 'package:kutub_fm/features/subscription/domain/entities/credit_card_info.dart';
import 'package:kutub_fm/features/subscription/domain/entities/purchase_result.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';
import 'package:kutub_fm/features/subscription/domain/entities/wallet_provider.dart';
import 'package:kutub_fm/features/subscription/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final ApplePayDataSource applePayDataSource;
  final GooglePlayDataSource googlePlayDataSource;
  final WalletPaymentDataSource walletDataSource;
  final CreditCardPaymentDataSource creditCardDataSource;

  PaymentRepositoryImpl({
    required this.applePayDataSource,
    required this.googlePlayDataSource,
    required this.walletDataSource,
    required this.creditCardDataSource,
  });

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    return List<SubscriptionPlan>.unmodifiable(SubscriptionMockData.plans);
  }

  @override
  Future<PurchaseResult> processCreditCardPayment({
    required SubscriptionPlan plan,
    required CreditCardInfo creditCardInfo,
  }) {
    return creditCardDataSource.processPayment(
      plan: plan,
      cardInfo: creditCardInfo,
    );
  }

  @override
  Future<PurchaseResult> processGooglePlayPurchase(SubscriptionPlan plan) {
    return googlePlayDataSource.processPurchase(plan);
  }

  @override
  Future<PurchaseResult> processApplePayPurchase(SubscriptionPlan plan) {
    return applePayDataSource.processPurchase(plan);
  }

  @override
  Future<PurchaseResult> processWalletPayment({
    required SubscriptionPlan plan,
    required WalletProviderType provider,
    required String phoneNumber,
  }) {
    return walletDataSource.processPayment(
      plan: plan,
      provider: provider,
      phoneNumber: phoneNumber,
    );
  }
}

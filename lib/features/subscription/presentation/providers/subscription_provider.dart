import 'package:flutter/material.dart';
import 'package:kutub_fm/features/subscription/data/mocks/subscription_mock_data.dart';
import 'package:kutub_fm/features/subscription/domain/entities/credit_card_info.dart';
import 'package:kutub_fm/features/subscription/domain/entities/payment_method.dart';
import 'package:kutub_fm/features/subscription/domain/entities/purchase_result.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';
import 'package:kutub_fm/features/subscription/domain/entities/wallet_provider.dart';
import 'package:kutub_fm/features/subscription/domain/repositories/payment_repository.dart';
import 'package:kutub_fm/features/subscription/domain/usecases/purchase_subscription_usecase.dart';
import 'package:kutub_fm/core/utils/credit_card_utils.dart';

class SubscriptionProvider extends ChangeNotifier {
  final PaymentRepository repository;
  late final PurchaseSubscriptionUseCase _purchaseUseCase;

  SubscriptionProvider({required this.repository}) {
    _purchaseUseCase = PurchaseSubscriptionUseCase(repository);
    loadPlans();
  }

  // State Variables
  List<SubscriptionPlan> availablePlans = [];
  bool isLoadingPlans = false;

  SubscriptionPlan? selectedPlan;
  PaymentMethodType? selectedMethod;
  WalletProviderType? selectedWalletProvider;

  // Wallet State
  String walletPhoneNumber = '';

  // Credit Card State
  String ccHolderName = '';
  String ccNumber = '';
  String ccExpiry = '';
  String ccCvv = '';
  bool isCvvFocused = false;

  // Payment Status
  bool isProcessingPayment = false;
  PurchaseResult? lastPurchaseResult;

  Future<void> loadPlans() async {
    isLoadingPlans = true;
    notifyListeners();
    try {
      availablePlans = await repository.getAvailablePlans();
    } catch (e) {
      // Handle error
    } finally {
      isLoadingPlans = false;
      notifyListeners();
    }
  }

  void selectPlan(SubscriptionPlan plan) {
    selectedPlan = plan;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethodType method) {
    selectedMethod = method;
    notifyListeners();
  }

  void selectWalletProvider(WalletProviderType provider) {
    selectedWalletProvider = provider;
    notifyListeners();
  }

  void updateWalletPhoneNumber(String number) {
    walletPhoneNumber = number;
    notifyListeners();
  }

  void fillMockWalletData() {
    selectedWalletProvider = SubscriptionMockData.walletProvider;
    walletPhoneNumber = SubscriptionMockData.walletPhoneNumber;
    notifyListeners();
  }

  void updateCCInfo({
    String? name,
    String? number,
    String? expiry,
    String? cvv,
  }) {
    if (name != null) ccHolderName = name;
    if (number != null) {
      ccNumber = CreditCardUtils.formatCardNumber(number);
    }
    if (expiry != null) ccExpiry = expiry;
    if (cvv != null) ccCvv = cvv;
    notifyListeners();
  }

  void fillMockCreditCardData() {
    ccHolderName = SubscriptionMockData.cardHolderName;
    ccNumber = CreditCardUtils.formatCardNumber(
      SubscriptionMockData.cardNumber,
    );
    ccExpiry = SubscriptionMockData.cardExpiry;
    ccCvv = SubscriptionMockData.cardCvv;
    isCvvFocused = false;
    notifyListeners();
  }

  void setCvvFocused(bool focused) {
    if (isCvvFocused != focused) {
      isCvvFocused = focused;
      notifyListeners();
    }
  }

  bool get isCreditCardValid {
    return ccHolderName.isNotEmpty &&
        ccNumber.replaceAll(' ', '').length >= 16 &&
        ccExpiry.length == 5 &&
        ccCvv.length >= 3;
  }

  bool get isWalletValid {
    return selectedWalletProvider != null && walletPhoneNumber.length >= 10;
  }

  Future<bool> processPayment() async {
    if (selectedPlan == null) {
      lastPurchaseResult = PurchaseResult(
        isSuccess: false,
        errorMessage: 'اختر باقة الاشتراك أولاً',
      );
      notifyListeners();
      return false;
    }

    if (selectedMethod == null) {
      lastPurchaseResult = PurchaseResult(
        isSuccess: false,
        errorMessage: 'اختر طريقة الدفع أولاً',
      );
      notifyListeners();
      return false;
    }

    isProcessingPayment = true;
    lastPurchaseResult = null;
    notifyListeners();

    final result = await _purchaseUseCase.call(
      plan: selectedPlan!,
      method: selectedMethod!,
      walletProvider: selectedWalletProvider,
      phoneNumber: walletPhoneNumber,
      creditCardInfo: selectedMethod == PaymentMethodType.creditCard
          ? CreditCardInfo(
              holderName: ccHolderName,
              cardNumber: ccNumber,
              expiryDate: ccExpiry,
              cvv: ccCvv,
            )
          : null,
    );

    isProcessingPayment = false;
    lastPurchaseResult = result;
    notifyListeners();

    return result.isSuccess;
  }

  void resetState() {
    selectedPlan = null;
    selectedMethod = null;
    selectedWalletProvider = null;
    walletPhoneNumber = '';
    ccHolderName = '';
    ccNumber = '';
    ccExpiry = '';
    ccCvv = '';
    isCvvFocused = false;
    lastPurchaseResult = null;
    notifyListeners();
  }
}

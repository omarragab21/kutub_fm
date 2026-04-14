import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/subscription/domain/entities/payment_method.dart';
import 'package:kutub_fm/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:kutub_fm/features/subscription/presentation/widgets/payment_method_card.dart';
import 'package:kutub_fm/features/subscription/presentation/screens/credit_card_payment_screen.dart';
import 'package:kutub_fm/features/subscription/presentation/screens/wallet_payment_screen.dart';
import 'package:kutub_fm/features/subscription/presentation/screens/payment_success_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const _selectPlanMessage = 'اختر باقة الاشتراك أولاً';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<SubscriptionProvider>();
      if (provider.selectedPlan != null) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_selectPlanMessage, style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).maybePop();
    });
  }

  void _handlePaymentSelection(
    BuildContext context,
    SubscriptionProvider provider,
  ) async {
    if (provider.selectedMethod == PaymentMethodType.googlePlay) {
      final success = await provider.processPayment();
      if (success && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.lastPurchaseResult?.errorMessage ?? 'فشلت عملية الدفع',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (provider.selectedMethod == PaymentMethodType.applePay) {
      final success = await provider.processPayment();
      if (success && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.lastPurchaseResult?.errorMessage ?? 'فشلت عملية الدفع',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (provider.selectedMethod == PaymentMethodType.creditCard) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const CreditCardPaymentScreen(),
          ),
        ),
      );
    } else if (provider.selectedMethod == PaymentMethodType.wallet) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const WalletPaymentScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'طريقة الدفع',
          style: GoogleFonts.cairo(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          final canContinue =
              provider.selectedMethod != null && !provider.isProcessingPayment;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر طريقة الدفع المناسبة لك',
                  style: GoogleFonts.cairo(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 24),
                PaymentMethodCard(
                  method: PaymentMethodType.googlePlay,
                  isSelected:
                      provider.selectedMethod == PaymentMethodType.googlePlay,
                  onTap: () => provider.selectPaymentMethod(
                    PaymentMethodType.googlePlay,
                  ),
                ),
                PaymentMethodCard(
                  method: PaymentMethodType.applePay,
                  isSelected:
                      provider.selectedMethod == PaymentMethodType.applePay,
                  onTap: () =>
                      provider.selectPaymentMethod(PaymentMethodType.applePay),
                ),
                PaymentMethodCard(
                  method: PaymentMethodType.wallet,
                  isSelected:
                      provider.selectedMethod == PaymentMethodType.wallet,
                  onTap: () =>
                      provider.selectPaymentMethod(PaymentMethodType.wallet),
                ),
                PaymentMethodCard(
                  method: PaymentMethodType.creditCard,
                  isSelected:
                      provider.selectedMethod == PaymentMethodType.creditCard,
                  onTap: () => provider.selectPaymentMethod(
                    PaymentMethodType.creditCard,
                  ),
                ),
                const Spacer(),
                if (provider.selectedMethod != null)
                  ElevatedButton(
                    onPressed: canContinue
                        ? () => _handlePaymentSelection(context, provider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: canContinue ? 8 : 0,
                    ),
                    child: provider.isProcessingPayment
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'المتابعة',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:kutub_fm/features/subscription/presentation/widgets/wallet_provider_selector.dart';
import 'package:kutub_fm/features/subscription/presentation/screens/payment_success_screen.dart';

class WalletPaymentScreen extends StatefulWidget {
  const WalletPaymentScreen({super.key});

  @override
  State<WalletPaymentScreen> createState() => _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends State<WalletPaymentScreen> {
  static const _selectPlanMessage = 'اختر باقة الاشتراك أولاً';
  final TextEditingController _phoneController = TextEditingController();
  bool _didHydrateController = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateController) {
      return;
    }

    _phoneController.text = context
        .read<SubscriptionProvider>()
        .walletPhoneNumber;
    _didHydrateController = true;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePayment(SubscriptionProvider provider) async {
    final success = await provider.processPayment();
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
    } else if (!success && mounted) {
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
  }

  void _fillMockData(SubscriptionProvider provider) {
    provider.fillMockWalletData();
    _phoneController.value = TextEditingValue(
      text: provider.walletPhoneNumber,
      selection: TextSelection.collapsed(
        offset: provider.walletPhoneNumber.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'الدفع عبر المحفظة الإلكترونية',
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
          final selectedPlan = provider.selectedPlan;
          final canSubmit =
              provider.isWalletValid && !provider.isProcessingPayment;
          final paymentLabel = selectedPlan == null
              ? 'تأكيد الدفع'
              : 'تأكيد الدفع ${selectedPlan.price.toStringAsFixed(0)} ج.م';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalletProviderSelector(
                  selectedProvider: provider.selectedWalletProvider,
                  onSelect: (p) => provider.selectWalletProvider(p),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _fillMockData(provider),
                      icon: const Icon(
                        Icons.science_outlined,
                        color: Color(0xFFD4AF37),
                      ),
                      label: Text(
                        'استخدام بيانات تجريبية',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'رقم الهاتف للمحفظة',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) => provider.updateWalletPhoneNumber(val),
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: '01X XXXX XXXX',
                      hintStyle: GoogleFonts.cairo(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.phone_iphone,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: canSubmit ? () => _handlePayment(provider) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.grey[500],
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canSubmit ? 8 : 0,
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
                          paymentLabel,
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

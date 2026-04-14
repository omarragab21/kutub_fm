import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:kutub_fm/features/subscription/presentation/widgets/credit_card_preview.dart';
import 'package:kutub_fm/features/subscription/presentation/screens/payment_success_screen.dart';

class CreditCardPaymentScreen extends StatefulWidget {
  const CreditCardPaymentScreen({super.key});

  @override
  State<CreditCardPaymentScreen> createState() =>
      _CreditCardPaymentScreenState();
}

class _CreditCardPaymentScreenState extends State<CreditCardPaymentScreen> {
  static const _selectPlanMessage = 'اختر باقة الاشتراك أولاً';
  final FocusNode _cvvFocusNode = FocusNode();
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _didHydrateControllers = false;

  @override
  void initState() {
    super.initState();
    _cvvFocusNode.addListener(() {
      context.read<SubscriptionProvider>().setCvvFocused(
        _cvvFocusNode.hasFocus,
      );
    });
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
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateControllers) {
      return;
    }

    final provider = context.read<SubscriptionProvider>();
    _holderController.text = provider.ccHolderName;
    _numberController.text = provider.ccNumber;
    _expiryController.text = provider.ccExpiry;
    _cvvController.text = provider.ccCvv;
    _didHydrateControllers = true;
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

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _fillMockData(SubscriptionProvider provider) {
    provider.fillMockCreditCardData();
    _setControllerValue(_holderController, provider.ccHolderName);
    _setControllerValue(_numberController, provider.ccNumber);
    _setControllerValue(_expiryController, provider.ccExpiry);
    _setControllerValue(_cvvController, provider.ccCvv);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'الدفع بالبطاقة البنكية',
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
              provider.isCreditCardValid && !provider.isProcessingPayment;
          final paymentLabel = selectedPlan == null
              ? 'دفع'
              : 'دفع ${selectedPlan.price.toStringAsFixed(0)} ج.م';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreditCardPreview(
                  cardNumber: provider.ccNumber,
                  cardHolder: provider.ccHolderName,
                  expiryDate: provider.ccExpiry,
                  cvv: provider.ccCvv,
                  showBack: provider.isCvvFocused,
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
                _buildTextField(
                  controller: _holderController,
                  label: 'اسم صاحب البطاقة',
                  icon: Icons.person,
                  onChanged: (val) => provider.updateCCInfo(name: val),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _numberController,
                  label: 'رقم البطاقة',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  onChanged: (val) => provider.updateCCInfo(number: val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _expiryController,
                        label: 'تاريخ الانتهاء (MM/YY)',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(5)],
                        onChanged: (val) => provider.updateCCInfo(expiry: val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _cvvController,
                        label: 'الرقم السري (CVV)',
                        icon: Icons.lock,
                        focusNode: _cvvFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: (val) => provider.updateCCInfo(cvv: val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: isPassword,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.cairo(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
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
    );
  }
}

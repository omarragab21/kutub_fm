import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kutub_fm/features/subscription/domain/entities/payment_method.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodType method;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    Key? key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  String get title {
    switch (method) {
      case PaymentMethodType.googlePlay:
        return 'جوجل بلاي';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.wallet:
        return 'المحافظ الإلكترونية';
      case PaymentMethodType.creditCard:
        return 'بطاقة بنكية';
    }
  }

  Widget _buildGooglePlayIcon(bool active) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            child: Icon(
              Icons.play_arrow_rounded,
              color: active ? const Color(0xFF34A853) : const Color(0xFF81C995),
              size: 22,
            ),
          ),
          const Positioned(
            top: 6,
            left: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF4285F4),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: SizedBox(width: 4, height: 4),
            ),
          ),
          const Positioned(
            bottom: 5,
            left: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFEA4335),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: SizedBox(width: 4, height: 4),
            ),
          ),
          const Positioned(
            right: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFBBC05),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: SizedBox(width: 5, height: 5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodIcon() {
    switch (method) {
      case PaymentMethodType.googlePlay:
        return _buildGooglePlayIcon(isSelected);
      case PaymentMethodType.applePay:
        return Icon(
          Icons.apple,
          color: isSelected ? Colors.black : Colors.white,
          size: 24,
        );
      case PaymentMethodType.wallet:
        return Icon(
          Icons.account_balance_wallet,
          color: isSelected ? Colors.black : Colors.white,
          size: 24,
        );
      case PaymentMethodType.creditCard:
        return Icon(
          Icons.credit_card,
          color: isSelected ? Colors.black : Colors.white,
          size: 24,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF37).withOpacity(0.1)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: _buildMethodIcon(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }
}

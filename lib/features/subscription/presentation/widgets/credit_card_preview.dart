import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditCardPreview extends StatelessWidget {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final bool showBack;

  const CreditCardPreview({
    Key? key,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    this.showBack = false,
  }) : super(key: key);

  String get _formattedNumber {
    if (cardNumber.isEmpty) return '**** **** **** ****';
    return cardNumber.padRight(19, '*');
  }

  String get _formattedExpiry {
    if (expiryDate.isEmpty) return 'MM/YY';
    return expiryDate.padRight(5, '*');
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: showBack ? pi : 0),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        bool isBack = value > (pi / 2);
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(value),
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildBack(),
                )
              : _buildFront(),
        );
      },
    );
  }

  Widget _buildFront() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF121212)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.credit_card, color: Color(0xFFD4AF37), size: 32),
              Text(
                'KUTUB PAY',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formattedNumber,
            style: GoogleFonts.sourceCodePro(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: GoogleFonts.cairo(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    cardHolder.isEmpty ? 'JOHN DOE' : cardHolder.toUpperCase(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES',
                    style: GoogleFonts.cairo(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _formattedExpiry,
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF121212)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            height: 45,
            color: Colors.black87,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    color: Colors.white,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      cvv.isEmpty ? '***' : cvv,
                      style: GoogleFonts.sourceCodePro(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 80), // To make the signature strip look realistic
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

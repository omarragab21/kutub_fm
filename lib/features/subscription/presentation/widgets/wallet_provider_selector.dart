import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kutub_fm/features/subscription/domain/entities/wallet_provider.dart';

class WalletProviderSelector extends StatelessWidget {
  final WalletProviderType? selectedProvider;
  final Function(WalletProviderType) onSelect;

  const WalletProviderSelector({
    Key? key,
    required this.selectedProvider,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر مزود الخدمة',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildProviderOption(WalletProviderType.vodafone, 'فودافون كاش', Colors.red),
            _buildProviderOption(WalletProviderType.orange, 'أورانج كاش', Colors.orange),
            _buildProviderOption(WalletProviderType.etisalat, 'اتصالات كاش', Colors.green),
            _buildProviderOption(WalletProviderType.wePay, 'وي باي', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderOption(WalletProviderType type, String title, Color color) {
    final isSelected = selectedProvider == type;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isSelected ? color : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

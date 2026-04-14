import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:kutub_fm/features/subscription/presentation/widgets/subscription_card.dart';
import 'package:kutub_fm/features/subscription/presentation/screens/payment_method_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'باقات الاشتراك',
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
          if (provider.isLoadingPlans) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (provider.availablePlans.isEmpty) {
            return Center(
              child: Text(
                'لا توجد باقات متاحة حالياً',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.availablePlans.length,
                  itemBuilder: (context, index) {
                    final plan = provider.availablePlans[index];
                    return SubscriptionCard(
                      title: plan.title,
                      description: plan.description,
                      price: plan.price,
                      isSelected: provider.selectedPlan?.id == plan.id,
                      onTap: () => provider.selectPlan(plan),
                    );
                  },
                ),
              ),
              if (provider.selectedPlan != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () {
                      final subscriptionProvider = context
                          .read<SubscriptionProvider>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: subscriptionProvider,
                            child: const PaymentMethodScreen(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                    child: Text(
                      'المتابعة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum SubscriptionPlanType { studentsEgyptian, studentsForeign, governmentEmployees, telecomCompanies }

class SubscriptionPlan {
  final String id;
  final String title;
  final String description;
  final double price; // Will be displayed in EGP
  final SubscriptionPlanType type;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
  });
}

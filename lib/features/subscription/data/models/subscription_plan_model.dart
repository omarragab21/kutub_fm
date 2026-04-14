import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';

class SubscriptionPlanModel extends SubscriptionPlan {
  SubscriptionPlanModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.type,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      type: SubscriptionPlanType.values.firstWhere(
            (e) => e.toString() == 'SubscriptionPlanType.${json['type']}',
        orElse: () => SubscriptionPlanType.studentsEgyptian,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'type': type.toString().split('.').last,
    };
  }
}

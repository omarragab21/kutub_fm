import 'package:kutub_fm/features/subscription/data/models/subscription_plan_model.dart';
import 'package:kutub_fm/features/subscription/domain/entities/subscription_plan.dart';
import 'package:kutub_fm/features/subscription/domain/entities/wallet_provider.dart';

class SubscriptionMockData {
  static final List<SubscriptionPlanModel> plans = [
    SubscriptionPlanModel(
      id: 'plan_students_eg',
      title: 'اشتراك الطلاب المصريين',
      description: 'خصم خاص للطلاب داخل جمهورية مصر العربية 🇪🇬',
      price: 50.0,
      type: SubscriptionPlanType.studentsEgyptian,
    ),
    SubscriptionPlanModel(
      id: 'plan_students_foreign',
      title: 'اشتراك الطلاب الأجانب',
      description: 'باقة مخصصة للطلاب الوافدين والأجانب 🌍',
      price: 150.0,
      type: SubscriptionPlanType.studentsForeign,
    ),
    SubscriptionPlanModel(
      id: 'plan_gov_employees',
      title: 'اشتراك الموظفين الحكوميين',
      description: 'باقة مدعمة لموظفي القطاع العام 🏢',
      price: 75.0,
      type: SubscriptionPlanType.governmentEmployees,
    ),
    SubscriptionPlanModel(
      id: 'plan_telecom',
      title: 'اشتراك شركات المحمول',
      description: 'ادفع عبر رصيدك أو محفظتك بخصم إضافي 📱',
      price: 60.0,
      type: SubscriptionPlanType.telecomCompanies,
    ),
    SubscriptionPlanModel(
      id: 'plan_family_plus',
      title: 'اشتراك العائلة بلس',
      description:
          'خطة تجريبية لاختبار الواجهات بحد أعلى من الصلاحيات 👨‍👩‍👧‍👦',
      price: 120.0,
      type: SubscriptionPlanType.telecomCompanies,
    ),
  ];

  static const WalletProviderType walletProvider = WalletProviderType.vodafone;
  static const String walletPhoneNumber = '01012345678';

  static const String cardHolderName = 'Ahmed Ali';
  static const String cardNumber = '4242424242424242';
  static const String cardExpiry = '12/28';
  static const String cardCvv = '123';

  const SubscriptionMockData._();
}

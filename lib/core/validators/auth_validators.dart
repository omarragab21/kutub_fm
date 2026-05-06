enum PasswordStrength {
  empty,
  weak,
  medium,
  strong,
  veryStrong,
}

class AuthValidators {
  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  static String? validateLoginEmail(String? value) {
    return validateEmail(value);
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.startsWith(' ') || value.endsWith(' ')) {
      return 'كلمة المرور لا يجب أن تبدأ أو تنتهي بمسافة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف';
    }
    if (value.length > 64) {
      return 'كلمة المرور طويلة جداً (الحد الأقصى 64 حرف)';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 3) {
      return 'الاسم قصير جداً (3 أحرف على الأقل)';
    }
    
    if (trimmedValue.length > 50) {
      return 'الاسم طويل جداً (الحد الأقصى 50 حرف)';
    }

    // Prevent numbers, emojis, special characters except spaces, Arabic, English
    final validChars = RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$');
    if (!validChars.hasMatch(trimmedValue)) {
      return 'الاسم يجب أن يحتوي على حروف عربية أو إنجليزية فقط';
    }

    final words = trimmedValue.split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'الرجاء إدخال الاسم الثنائي على الأقل';
    }
    
    for (final word in words) {
      if (word.length < 2) {
        return 'كل جزء من الاسم يجب أن يكون حرفين على الأقل';
      }
    }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length > 254) {
      return 'البريد الإلكتروني طويل جداً';
    }
    
    if (trimmedValue.contains(' ')) {
      return 'البريد الإلكتروني لا يجب أن يحتوي على مسافات';
    }

    // Reject obvious temporary invalid formats
    if (trimmedValue.startsWith('@') || trimmedValue.endsWith('@')) {
      return 'البريد الإلكتروني غير صحيح';
    }
    if (trimmedValue.endsWith('@gmail.com') && trimmedValue.split('@').first.isEmpty) {
      return 'البريد الإلكتروني غير صحيح';
    }
    if (trimmedValue.contains('@@')) {
      return 'البريد الإلكتروني غير صحيح';
    }
    
    final strictEmailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$");
    if (!strictEmailRegex.hasMatch(trimmedValue)) {
       return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (value.startsWith(' ') || value.endsWith(' ')) {
      return 'كلمة المرور لا يجب أن تبدأ أو تنتهي بمسافة';
    }
    
    if (value.length < 8) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف';
    }
    
    if (value.length > 64) {
      return 'كلمة المرور طويلة جداً (الحد الأقصى 64 حرف)';
    }
    
    if (containsArabic(value)) {
      return 'كلمة المرور لا يجب أن تحتوي على أحرف عربية';
    }

    if (!hasUppercase(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!hasLowercase(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    if (!hasNumber(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!hasSpecialCharacter(value)) {
      return 'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل';
    }
    
    if (isWeakPassword(value)) {
      return 'كلمة المرور ضعيفة جداً، الرجاء اختيار كلمة مرور أقوى';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  static bool hasUppercase(String password) => password.contains(RegExp(r'[A-Z]'));
  
  static bool hasLowercase(String password) => password.contains(RegExp(r'[a-z]'));
  
  static bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
  
  static bool hasSpecialCharacter(String password) => password.contains(RegExp(r'[!@#\$%\^&\*(),\.?":{}|<>\-_\+=\/\\~`\[\]]'));
  
  static bool hasMinLength(String password) => password.length >= 8;
  
  static bool containsArabic(String password) => password.contains(RegExp(r'[\u0600-\u06FF]'));

  static bool isWeakPassword(String password) {
    final weakPasswords = [
      'password',
      'Password123',
      '12345678',
      'qwerty123',
      'admin123',
      '11111111',
    ];
    return weakPasswords.contains(password);
  }

  static PasswordStrength calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    
    if (password.length < 8) return PasswordStrength.weak;
    if (containsArabic(password)) return PasswordStrength.weak;
    if (isWeakPassword(password)) return PasswordStrength.weak;
    
    int score = 0;
    if (hasMinLength(password)) score++;
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasNumber(password)) score++;
    if (hasSpecialCharacter(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score == 3) return PasswordStrength.medium;
    if (score == 4) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

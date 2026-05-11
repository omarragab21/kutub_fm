enum UserType {
  student,
  employee,
  normalUser,
}

String extractEmailDomain(String email) {
  final parts = email.split('@');
  if (parts.length > 1) {
    return parts.last.trim().toLowerCase();
  }
  return '';
}

bool isPublicPersonalEmail(String email) {
  final domain = extractEmailDomain(email);
  const publicDomains = [
    'gmail.com',
    'googlemail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'icloud.com',
    'me.com',
    'proton.me',
    'protonmail.com',
    'aol.com',
  ];
  return publicDomains.contains(domain);
}

bool isStudentEmail(String email) {
  final domain = extractEmailDomain(email);
  const studentKeywords = [
    'edu',
    'university',
    'student',
    'school',
    'academy',
    'institute',
    'college',
  ];
  for (final keyword in studentKeywords) {
    if (domain.contains(keyword)) {
      return true;
    }
  }
  return false;
}

String detectUserTypeFromEmail(String email) {
  if (isPublicPersonalEmail(email)) {
    return 'normal_user';
  } else if (isStudentEmail(email)) {
    return 'student';
  } else {
    return 'employee';
  }
}

bool requiresEmailVerification(String email) {
  return detectUserTypeFromEmail(email) == 'normal_user';
}

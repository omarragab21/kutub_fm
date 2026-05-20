import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_user_model.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/firebase_storage_service.dart';
import '../../data/services/user_firestore_service.dart';
import '../../utils/auth_helpers.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
  guest,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuthService? authService}) : _authService = authService;

  FirebaseAuthService? _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  AppUserModel? _appUser;
  String? _errorMessage;
  _PendingRegistration? _pendingRegistration;

  AuthStatus get status => _status;
  User? get user => _user;
  AppUserModel? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn =>
      _status == AuthStatus.authenticated || _status == AuthStatus.guest;
  bool get isGuest => _user?.isAnonymous ?? false;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isCategorySelectionCompleted => _appUser?.categorySelectionCompleted ?? false;

  FirebaseAuthService get _service => _authService ??= FirebaseAuthService();

  void listenToAuthChanges() {
    _authSubscription ??= _service.authStateChanges.listen(
      (firebaseUser) {
        _user = firebaseUser;
        _appUser = firebaseUser == null
            ? null
            : AppUserModel.fromFirebaseUser(firebaseUser);
        _errorMessage = null;
        _status = _resolveStatus(firebaseUser);
        notifyListeners();
      },
      onError: (error) {
        _setError(_mapUnknownAuthError(error));
      },
    );
  }

  FirebaseStorageService? _storageService;
  UserFirestoreService? _firestoreService;

  FirebaseStorageService get _storage =>
      _storageService ??= FirebaseStorageService();
  UserFirestoreService get _firestore =>
      _firestoreService ??= UserFirestoreService();

  Future<void> register({
    required String name,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _service.registerWithEmail(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user ?? _service.currentUser;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'User was not created.',
        );
      }

      final emailDomain = extractEmailDomain(email);
      final userType = detectUserTypeFromEmail(email);
      final shouldVerifyEmail = requiresEmailVerification(email);

      _pendingRegistration = _PendingRegistration(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        profileImage: profileImage,
      );

      _user = firebaseUser;
      
      if (shouldVerifyEmail) {
        _appUser = AppUserModel.fromFirebaseUser(firebaseUser).copyWith(
          userType: userType,
          emailDomain: emailDomain,
          appEmailVerified: false,
          firebaseEmailVerified: false,
          verificationMode: 'firebase_email_verification',
        );
        await _service.sendEmailVerification();
        _status = AuthStatus.emailNotVerified;
      } else {
        String? photoUrl = firebaseUser.photoURL;

        if (profileImage != null) {
          photoUrl = await _storage.uploadProfileImage(
            imageFile: profileImage,
            uid: firebaseUser.uid,
          );
        }

        await _service.updateUserProfile(name: name, photoUrl: photoUrl);
        await _firestore.createUserDocument(
          uid: firebaseUser.uid,
          name: name,
          email: email,
          photoUrl: photoUrl,
          provider: 'email',
          emailVerified: true,
          userType: userType,
          emailDomain: emailDomain,
          appEmailVerified: true,
          firebaseEmailVerified: firebaseUser.emailVerified,
          verificationMode: 'domain_skip_temporary',
        );

        await _service.reloadUser();
        _user = _service.currentUser;
        _appUser = AppUserModel(
          uid: firebaseUser.uid,
          name: name,
          email: email,
          photoUrl: photoUrl,
          provider: 'email',
          role: 'user',
          isGuest: false,
          emailVerified: true,
          userType: userType,
          emailDomain: emailDomain,
          appEmailVerified: true,
          firebaseEmailVerified: firebaseUser.emailVerified,
          verificationMode: 'domain_skip_temporary',
        );
        _pendingRegistration = null;
        _status = AuthStatus.authenticated;
      }
    } on FirebaseAuthException catch (error) {
      _setError(_mapAuthError(error));
    } on FirebaseException catch (error) {
      _setError(_mapFirebaseError(error));
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''));
    }

    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _runAuthAction(() async {
      final credential = await _service.loginWithEmail(
        email: email,
        password: password,
      );
      _user = credential.user ?? _service.currentUser;
      await _refreshCurrentUser();
    });
  }

  Future<void> continueAsGuest() async {
    await _runAuthAction(() async {
      final credential = await _service.continueAsGuest();
      _user = credential.user ?? _service.currentUser;
      _status = AuthStatus.guest;
    });
  }

  Future<void> signInWithGoogle() async {
    await _runAuthAction(() async {
      final credential = await _service.signInWithGoogle();
      if (credential == null) {
        _setError('تم إلغاء تسجيل الدخول بجوجل');
        _status = AuthStatus.unauthenticated;
        return;
      }
      _user = credential.user ?? _service.currentUser;
      _status = _resolveStatus(_user);
    });
  }

  Future<void> resendVerificationEmail() async {
    await _runNonAuthAction(() async {
      await _service.sendEmailVerification();
    });
  }

  Future<void> checkEmailVerification() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.reloadUser();
      final firebaseUser = _service.currentUser;
      _user = firebaseUser;

      if (firebaseUser == null) {
        _appUser = null;
        _status = AuthStatus.unauthenticated;
        return;
      }

      if (!firebaseUser.emailVerified) {
        _status = AuthStatus.emailNotVerified;
        _errorMessage =
            'لم يتم تفعيل البريد بعد. افتح رسالة التفعيل ثم حاول مرة أخرى.';
        return;
      }

      final pendingRegistration = _pendingRegistration?.uid == firebaseUser.uid
          ? _pendingRegistration
          : null;
      final name =
          pendingRegistration?.name ??
          firebaseUser.displayName?.trim() ??
          firebaseUser.email?.split('@').first ??
          '';
      final email = pendingRegistration?.email ?? firebaseUser.email ?? '';
      String? photoUrl = firebaseUser.photoURL;

      if (pendingRegistration?.profileImage != null) {
        photoUrl = await _storage.uploadProfileImage(
          imageFile: pendingRegistration!.profileImage,
          uid: firebaseUser.uid,
        );
      }

      await _service.updateUserProfile(name: name, photoUrl: photoUrl);
      await _firestore.createUserDocument(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        provider: 'email',
        emailVerified: true,
        userType: 'normal_user',
        emailDomain: extractEmailDomain(email),
        appEmailVerified: true,
        firebaseEmailVerified: true,
        verificationMode: 'firebase_email_verification',
      );

      await _service.reloadUser();
      _user = _service.currentUser;
      
      // Initialize with default and then update from Firestore if exists
      _appUser = AppUserModel.fromFirebaseUser(_user!);

      // Fetch additional data from Firestore
      final userData = await _firestore.getUserDocument(firebaseUser.uid);
      if (userData != null) {
        _appUser = AppUserModel.fromMap(userData, firebaseUser.uid);
      }

      _pendingRegistration = null;
      _status = AuthStatus.authenticated;
    } on FirebaseAuthException catch (error) {
      _setError(_mapAuthError(error));
      return;
    } on FirebaseException catch (error) {
      _setError(_mapFirebaseError(error));
      return;
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''));
      return;
    } finally {
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _runNonAuthAction(() async {
      await _service.resetPassword(email);
    });
  }

  Future<void> updateProfileName(String name) async {
    await _runNonAuthAction(() async {
      await _service.updateDisplayName(name);
      await _refreshCurrentUser();
    });
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.logout();
      _user = null;
      _appUser = null;
      _pendingRegistration = null;
      _status = AuthStatus.unauthenticated;
    } on FirebaseAuthException catch (error) {
      _setError(_mapAuthError(error));
    } on FirebaseException catch (error) {
      _setError(_mapFirebaseError(error));
    } catch (_) {
      _setError('حدث خطأ أثناء المصادقة');
    }

    notifyListeners();
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _user = _service.currentUser;
      _appUser = _user == null ? null : AppUserModel.fromFirebaseUser(_user!);
      _status = _resolveStatus(_user);
    } on FirebaseAuthException catch (error) {
      _setError(_mapAuthError(error));
      return;
    } on FirebaseException catch (error) {
      _setError(_mapFirebaseError(error));
      return;
    } catch (_) {
      _setError('حدث خطأ أثناء المصادقة');
      return;
    }

    notifyListeners();
  }

  Future<void> _runNonAuthAction(Future<void> Function() action) async {
    final previousStatus = _status;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _user = _service.currentUser;
      _appUser = _user == null ? null : AppUserModel.fromFirebaseUser(_user!);
      _status = _resolveStatus(_user);
    } on FirebaseAuthException catch (error) {
      _status = previousStatus;
      _errorMessage = _mapAuthError(error);
    } on FirebaseException catch (error) {
      _status = previousStatus;
      _errorMessage = _mapFirebaseError(error);
    } catch (_) {
      _status = previousStatus;
      _errorMessage = 'حدث خطأ أثناء المصادقة';
    }

    notifyListeners();
  }

  Future<void> refreshUser() async {
    await _refreshCurrentUser();
    notifyListeners();
  }

  Future<void> _refreshCurrentUser() async {
    await _service.reloadUser();
    _user = _service.currentUser;
    if (_user == null) {
      _appUser = null;
    } else {
      final userData = await _firestore.getUserDocument(_user!.uid);
      if (userData != null) {
        _appUser = AppUserModel.fromMap(userData, _user!.uid);
      } else {
        _appUser = AppUserModel.fromFirebaseUser(_user!);
      }
    }
    _status = _resolveStatus(_user);
  }

  AuthStatus _resolveStatus(User? firebaseUser) {
    if (firebaseUser == null) return AuthStatus.unauthenticated;
    if (firebaseUser.isAnonymous) return AuthStatus.guest;
    
    if (firebaseUser.email != null) {
      final userType = detectUserTypeFromEmail(firebaseUser.email!);
      if (userType == 'normal_user' && !firebaseUser.emailVerified) {
        return AuthStatus.emailNotVerified;
      }
    } else if (!firebaseUser.emailVerified) {
      return AuthStatus.emailNotVerified;
    }
    
    return AuthStatus.authenticated;
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقًا';
      case 'operation-not-allowed':
        return 'تسجيل البريد وكلمة المرور غير مفعل في Firebase';
      case 'admin-restricted-operation':
        return 'طريقة تسجيل الدخول هذه غير مفعلة في Firebase';
      case 'configuration-not-found':
        return 'إعدادات Firebase Authentication غير مكتملة';
      case 'app-not-authorized':
        return 'هذا التطبيق غير مصرح له باستخدام Firebase';
      case 'invalid-api-key':
        return 'مفتاح Firebase غير صحيح';
      case 'channel-error':
      case 'internal-error':
      case 'unknown':
        return 'تعذر الاتصال بخدمة المصادقة، حاول مرة أخرى';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'requires-recent-login':
        return 'يرجى تسجيل الدخول مرة أخرى لإكمال العملية';
      default:
        return 'حدث خطأ أثناء المصادقة';
    }
  }

  String _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'no-app':
        return 'لم يتم تهيئة Firebase داخل التطبيق';
      case 'invalid-api-key':
        return 'مفتاح Firebase غير صحيح';
      case 'app-not-authorized':
        return 'هذا التطبيق غير مصرح له باستخدام Firebase';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'حدث خطأ أثناء المصادقة';
    }
  }

  String _mapUnknownAuthError(Object error) {
    if (error is FirebaseAuthException) return _mapAuthError(error);
    if (error is FirebaseException) return _mapFirebaseError(error);
    return 'حدث خطأ أثناء المصادقة';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class _PendingRegistration {
  const _PendingRegistration({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImage,
  });

  final String uid;
  final String name;
  final String email;
  final File? profileImage;
}

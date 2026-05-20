import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthCancelledException implements Exception {
  const FacebookAuthCancelledException([
    this.message = 'Facebook login was cancelled.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class FacebookAuthServiceException implements Exception {
  const FacebookAuthServiceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class FirebaseFacebookAuthService {
  FirebaseFacebookAuthService({
    FirebaseAuth? firebaseAuth,
    FacebookAuth? facebookAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  final FirebaseAuth _firebaseAuth;
  final FacebookAuth _facebookAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? getCurrentUser() => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithFacebook() async {
    _log('Starting Facebook login flow.');

    try {
      final loginResult = await _facebookAuth.login(
        permissions: const ['public_profile', 'email'],
        loginBehavior: LoginBehavior.nativeWithFallback,
        loginTracking: LoginTracking.enabled,
      );

      _log('Facebook login status: ${loginResult.status.name}.');

      switch (loginResult.status) {
        case LoginStatus.success:
          final accessToken = loginResult.accessToken;
          final tokenString = accessToken?.tokenString;

          if (tokenString == null || tokenString.isEmpty) {
            throw const FacebookAuthServiceException(
              'Facebook login succeeded, but no access token was returned.',
            );
          }

          final credential = FacebookAuthProvider.credential(tokenString);
          _log('Signing in to Firebase with Facebook credential.');

          final userCredential = await _firebaseAuth.signInWithCredential(
            credential,
          );
          _log(
            'Firebase Facebook sign-in completed for uid: '
            '${userCredential.user?.uid ?? 'unknown'}.',
          );

          return userCredential;
        case LoginStatus.cancelled:
          _log('Facebook login cancelled by the user.');
          throw const FacebookAuthCancelledException();
        case LoginStatus.failed:
          throw FacebookAuthServiceException(
            loginResult.message?.trim().isNotEmpty == true
                ? loginResult.message!.trim()
                : 'Facebook login failed. Please try again.',
          );
        case LoginStatus.operationInProgress:
          throw const FacebookAuthServiceException(
            'A Facebook login operation is already in progress.',
          );
      }
    } on FacebookAuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      _log(
        'FirebaseAuthException during Facebook sign-in: ${error.code}.',
        error,
        stackTrace,
      );
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      _log(
        'FirebaseException during Facebook sign-in: ${error.code}.',
        error,
        stackTrace,
      );
      throw FacebookAuthServiceException(
        _mapFirebaseException(error),
        cause: error,
      );
    } on PlatformException catch (error, stackTrace) {
      _log('Facebook platform error during sign-in.', error, stackTrace);
      throw FacebookAuthServiceException(
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Facebook login failed because of a platform error.',
        cause: error,
      );
    } on FacebookAuthServiceException catch (error, stackTrace) {
      _log('Facebook auth service error.', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _log('Unexpected error during Facebook sign-in.', error, stackTrace);
      throw FacebookAuthServiceException(
        'Unable to sign in with Facebook. Please try again.',
        cause: error,
      );
    }
  }

  Future<void> signOut() async {
    _log('Signing out from Facebook SDK and Firebase.');

    try {
      await _facebookAuth.logOut();
    } catch (error, stackTrace) {
      _log(
        'Facebook SDK logout failed; continuing with Firebase logout.',
        error,
        stackTrace,
      );
    }

    try {
      await _firebaseAuth.signOut();
      _log('Firebase sign-out completed.');
    } on FirebaseAuthException catch (error, stackTrace) {
      _log(
        'FirebaseAuthException during sign-out: ${error.code}.',
        error,
        stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      _log('Unexpected error during sign-out.', error, stackTrace);
      throw FacebookAuthServiceException(
        'Unable to sign out. Please try again.',
        cause: error,
      );
    }
  }

  String _mapFirebaseException(FirebaseException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'no-app':
        return 'Firebase has not been initialized.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Authentication.';
      case 'invalid-api-key':
        return 'The Firebase API key is invalid.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'A Firebase error occurred during Facebook sign-in.';
    }
  }

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    developer.log(
      message,
      name: 'FirebaseFacebookAuthService',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

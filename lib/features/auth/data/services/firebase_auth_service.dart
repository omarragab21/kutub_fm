import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> continueAsGuest() {
    return _firebaseAuth.signInAnonymously();
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null || user.emailVerified || user.isAnonymous) return;
    await user.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  Future<void> resetPassword(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    return _firebaseAuth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    final user = currentUser;
    if (user == null) return;
    
    if (name != null) {
      await user.updateDisplayName(name.trim());
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
    
    await user.reload();
  }
}

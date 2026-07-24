import 'package:cloud_firestore/cloud_firestore.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    required String provider,
    required bool emailVerified,
    String userType = 'normal_user',
    String? emailDomain,
    bool appEmailVerified = false,
    bool firebaseEmailVerified = false,
    String verificationMode = 'firebase_email_verification',
    String? phoneNumber,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);

      final Map<String, dynamic> data = {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': ?photoUrl,
        'provider': provider,
        'role': 'user',
        'isGuest': false,
        'emailVerified': emailVerified,
        'userType': userType,
        'emailDomain': ?emailDomain,
        'appEmailVerified': appEmailVerified,
        'firebaseEmailVerified': firebaseEmailVerified,
        'verificationMode': verificationMode,
        'updatedAt': FieldValue.serverTimestamp(),
        'phoneNumber': ?phoneNumber,
      };

      // We use SetOptions(merge: true) to avoid overwriting existing fields
      // like createdAt if the document already exists.
      // But we also need to ensure createdAt is set if it's a new document.

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('فشل حفظ بيانات المستخدم: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع أثناء حفظ بيانات المستخدم.');
    }
  }
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}

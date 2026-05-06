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
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      
      final Map<String, dynamic> data = {
        'uid': uid,
        'name': name,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'provider': provider,
        'role': 'user',
        'isGuest': false,
        'emailVerified': emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
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
}

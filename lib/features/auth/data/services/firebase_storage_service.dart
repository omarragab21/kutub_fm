import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage({
    required File? imageFile,
    required String uid,
  }) async {
    if (imageFile == null) return null;

    try {
      final String path = 'users/$uid/profile/profile_image.jpg';
      final Reference ref = _storage.ref().child(path);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('فشل رفع صورة الحساب: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع أثناء رفع الصورة.');
    }
  }
}

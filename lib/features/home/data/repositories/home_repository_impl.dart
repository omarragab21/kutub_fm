import '../../domain/entities/book_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<List<HomeCategory>> getCategories() async {
    // Mocking data for now as per plan
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      HomeCategory(id: 'history', title: 'التاريخ', icon: 'history_edu'),
      HomeCategory(id: 'novels', title: 'الروايات', icon: 'auto_stories'),
      HomeCategory(id: 'self_improvement', title: 'تطوير الذات', icon: 'self_improvement'),
      HomeCategory(id: 'business', title: 'الأعمال', icon: 'trending_up'),
      HomeCategory(id: 'religion', title: 'الدين', icon: 'mosque'),
      HomeCategory(id: 'science', title: 'العلوم', icon: 'science'),
    ];
  }

  @override
  Future<List<BookEntity>> getRecommendedBooks() async {
    // Mocking data for now as per plan
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      BookEntity(
        id: '1',
        title: 'طوق الحمامة',
        author: 'ابن حزم الأندلسي',
        coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAWFZCLuzVeFM8VOxTMQDaoCX32AsfAoFptyv7ybXLA9nWloCJIFpZRxzNos9lRiewswhOlsRD2rhZhAec2A4g2W5BrwUTXQtuhzSCSreirZ4H1V8DOduYMa41MsMTUC-1yJ9-nLj8Tz4eIesKNLqC3A4w7LvW14LEXOmsTp9Yanh-S9fHtKOgNstHl56ln1egcgonGot07PUeL5o23As7E4ZloPrK1jIXMGrPpiI0Tbetqq9Mil9Ax5HtFfLrQxNgX71ZsUe-zFWc',
        rating: 4.9,
        duration: '٨ ساعات',
      ),
      BookEntity(
        id: '2',
        title: 'مدن الملح',
        author: 'عبدالرحمن منيف',
        coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3Y2apirvC_AC_GljgNERIW6vN2VU2XLDuM6miQcYxg14eKriUyVUF8UOdBiYUihVSjme9wverOPLC7aLqTqaZWcHrtjlOPswnjkI2zh-3k4ahmBUCwyJ2hD18e4Z7IDiQ5xYxEU_iMZHXd9-t4ACOMWzjGWkXBNTDOhdg80fGVaX7Z0in6tELGV5cnBUWqgAVNOEO5fUqKZkshwhJkNEKmHAK1UT7t_1xPnwG2T7VJY70fZlqTFgXgIrauwX1JMsQmcx7RrVowTE',
        rating: 4.7,
        duration: '١٥ ساعة',
      ),
      BookEntity(
        id: '3',
        title: 'رسالة الغفران',
        author: 'أبو العلاء المعري',
        coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAffVaFTvImZAjqiBfOil4oF4TMZpaOdEy6CfOkIC5PEFWSKDbdS51fF5hI3uRUAK29XLGc_ZuoQrwIY950n-OayP0DK4KleW-aTLflfiiIfMv0wUSsV553YGCOtOp3myIiA0daC6qpMgWl8RO2wBPTDaE5SPBkjl8ANmMSC-fDzocmR_a6KryJJ54af0slKYLFskA0912aIfhzKR-_9FBmpsqCLPYNCSKlXdB1cv_nTEAu27JFKGJDIgW3P0U68hjbMdMs26O0fv4',
        rating: 4.8,
        duration: '١١ ساعة',
      ),
    ];
  }
}

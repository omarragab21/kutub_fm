import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/reader_post.dart';
import '../providers/reader_sessions_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _bookController = TextEditingController();
  ReaderPostType _selectedType = ReaderPostType.quote;

  @override
  void dispose() {
    _contentController.dispose();
    _bookController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    await context.read<ReaderSessionsProvider>().createPost(
      content: content,
      type: _selectedType,
      bookTitle: _bookController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090806),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('منشور جديد'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF14110D),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ماذا يدور في بالك اليوم؟',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    minLines: 6,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(
                      hint: 'اكتب اقتباساً، سؤالاً، أو رأياً عن كتاب تقرؤه...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bookController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(
                      hint: 'اسم الكتاب اختياري',
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'نوع المنشور',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ReaderPostType.values.map((type) {
                      final selected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        selectedColor: const Color(0xFFD9AF68),
                        backgroundColor: const Color(0xFF1A1510),
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD9AF68),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'نشر الآن',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.36)),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Color(0xFFD9AF68)),
      ),
    );
  }
}

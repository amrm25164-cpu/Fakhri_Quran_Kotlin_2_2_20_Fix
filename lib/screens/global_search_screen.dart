import 'package:flutter/material.dart';
import '../services/app_store.dart';
import '../services/quran_service.dart';
import 'reader_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key, required this.store, required this.quran});
  final AppStore store;
  final QuranService quran;
  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final controller = TextEditingController();
  bool loading = false;
  String error = '';
  List<Map<String, dynamic>> results = [];

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  Future<void> _search() async {
    if (controller.text.trim().isEmpty) return;
    setState(() { loading = true; error = ''; results = []; });
    try {
      final found = await widget.quran.searchAll(controller.text);
      if (mounted) setState(() => results = found);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر البحث. تحقق من الإنترنت ثم حاول مرة أخرى.');
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن كاملًا')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.search, onSubmitted: (_) => _search(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'اكتب كلمة أو عبارة قرآنية', border: OutlineInputBorder())),),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: loading ? null : _search, icon: const Icon(Icons.search)),
        ])),
        if (loading) const LinearProgressIndicator(),
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(error)),
        if (!loading && results.isEmpty && error.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('اكتب كلمة أو عبارة للبحث في آيات القرآن كاملًا.')),
        Expanded(child: ListView.builder(itemCount: results.length, itemBuilder: (context, index) {
          final item = results[index];
          final surah = Map<String, dynamic>.from(item['surah'] as Map? ?? const {});
          final number = (surah['number'] as num?)?.toInt() ?? 1;
          final verseNumber = (item['numberInSurah'] as num?)?.toInt() ?? 1;
          final name = surah['name']?.toString() ?? 'سورة';
          return ListTile(
            title: Text(item['text']?.toString() ?? '', textAlign: TextAlign.justify, style: const TextStyle(fontSize: 20, height: 1.8)),
            subtitle: Text('$name — آية $verseNumber'),
            onTap: () async {
              await widget.store.saveProgress(number, verseNumber);
              if (!context.mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(surahNumber: number, store: widget.store, quran: widget.quran)));
            },
          );
        })),
      ]),
    ),
  );
}

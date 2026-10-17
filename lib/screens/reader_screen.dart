import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../models/quran.dart';
import '../services/app_store.dart';
import '../services/quran_service.dart';
import '../services/audio_library.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.surahNumber, required this.store, required this.quran});
  final int surahNumber;
  final AppStore store;
  final QuranService quran;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int surah;
  String query = '';
  late final AudioPlayer player;
  int? playingVerse;
  bool showTranslation = false;
  String translationEdition = 'ar.muyassar';
  bool playingWholeSurah = false;
  String surahName = '';

  @override
  void initState() {
    super.initState();
    surah = widget.surahNumber;
    player = AudioPlayer();
    _loadSurahName();
  }

  Future<void> _loadSurahName() async {
    try {
      final list = await widget.quran.surahs();
      if (mounted) setState(() => surahName = list.firstWhere((s) => s.number == surah).name);
    } catch (_) {}
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(surahName.isEmpty ? 'سورة رقم $surah' : surahName), actions: [
        IconButton(tooltip: 'السورة السابقة', onPressed: () => _change(surah - 1), icon: const Icon(Icons.chevron_right)),
        IconButton(tooltip: 'السورة التالية', onPressed: () => _change(surah + 1), icon: const Icon(Icons.chevron_left)),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Row(children: [
          const Text('حجم الخط'),
          Expanded(child: Slider(min: 20, max: 44, value: widget.store.fontSize, onChanged: widget.store.setFontSize)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث في آيات السورة', isDense: true),
          onChanged: (v) => setState(() => query = v),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Wrap(spacing: 8, children: [
          OutlinedButton.icon(onPressed: () => setState(() => showTranslation = !showTranslation), icon: const Icon(Icons.translate), label: Text(showTranslation ? 'إخفاء التفسير/الترجمة' : 'عرض التفسير/الترجمة')),
          if (showTranslation) SizedBox(width: 190, child: DropdownButtonFormField<String>(
            value: translationEdition,
            decoration: const InputDecoration(isDense: true, labelText: 'اللغة / الإصدار'),
            items: const [
              DropdownMenuItem(value: 'ar.muyassar', child: Text('التفسير الميسر — عربي')),
              DropdownMenuItem(value: 'en.sahih', child: Text('English — Sahih International')),
              DropdownMenuItem(value: 'en.pickthall', child: Text('English — Pickthall')),
              DropdownMenuItem(value: 'fr.hamidullah', child: Text('Français — Hamidullah')),
              DropdownMenuItem(value: 'ur.jalandhry', child: Text('اردو — جالندھری')),
            ],
            onChanged: (v) => setState(() => translationEdition = v ?? 'ar.muyassar'),
          )),
          FilledButton.tonalIcon(onPressed: _playWholeSurah, icon: Icon(playingWholeSurah ? Icons.graphic_eq : Icons.play_arrow), label: const Text('تشغيل السورة كاملة')),
          IconButton(tooltip: 'إيقاف الصوت', onPressed: () async { await player.stop(); if (mounted) setState(() { playingVerse = null; playingWholeSurah = false; }); }, icon: const Icon(Icons.stop_circle_outlined)),
        ])),
        Expanded(child: FutureBuilder<List<Verse>>(
          key: ValueKey(surah), future: widget.quran.verses(surah),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('تعذر تحميل الآيات'), TextButton(onPressed: () => setState(() {}), child: const Text('إعادة المحاولة'))]));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final verses = snap.data!.where((v) => v.text.contains(query)).toList();
            if (verses.isEmpty) return const Center(child: Text('لا توجد آيات مطابقة'));
            return FutureBuilder<List<String>?>(
              future: showTranslation ? widget.quran.editionTexts(surah, translationEdition) : Future.value(null),
              builder: (context, translationSnap) => ListView.builder(
                padding: const EdgeInsets.all(16), itemCount: verses.length,
                itemBuilder: (context, i) {
                  final v = verses[i];
                  final marked = widget.store.bookmarks.contains('$surah:${v.number}');
                  final translations = translationSnap.data;
                  return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(v.text, style: TextStyle(fontFamily: widget.store.fontFamily, fontSize: widget.store.fontSize, height: 1.9), textAlign: TextAlign.justify),
                    if (showTranslation) Padding(padding: const EdgeInsets.only(top: 8), child: Text(
                      translationSnap.hasError ? 'تعذر تحميل النص الإضافي. تحقق من الإنترنت أو نزّله للاستخدام دون إنترنت.' : (translations != null && v.number <= translations.length ? translations[v.number - 1] : 'جارٍ تحميل التفسير الميسر…'),
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.secondary, height: 1.6),
                    )),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('﴿ ${v.number} ﴾', style: const TextStyle(color: Color(0xffc9a44c))), const Spacer(),
                      IconButton(tooltip: 'حفظ موضع القراءة', onPressed: () => widget.store.saveProgress(surah, v.number), icon: const Icon(Icons.bookmark_add_outlined)),
                      IconButton(tooltip: 'حفظ علامة', onPressed: () => widget.store.toggleBookmark(surah, v.number), icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border)),
                      IconButton(tooltip: 'نسخ', onPressed: () { Clipboard.setData(ClipboardData(text: '${v.text} (سورة $surah، آية ${v.number})')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الآية'))); }, icon: const Icon(Icons.copy)),
                      IconButton(tooltip: 'تشغيل الآية', onPressed: () => _playVerse(v.number), icon: Icon(playingVerse == v.number ? Icons.volume_up : Icons.play_circle_outline)),
                      IconButton(tooltip: 'مشاركة', onPressed: () => Share.share('${v.text}\nسورة $surah، آية ${v.number}'), icon: const Icon(Icons.share)),
                    ]),
                  ])));
                },
              ),
            );
          },
        )),
      ]),
    ),
  );

  Future<void> _playVerse(int verse) async {
    try {
      final source = await AudioLibrary.instance.sourceFor(widget.store.reciterId, surah, verse);
      if (source.scheme == 'file') {
        await player.setAudioSource(AudioSource.file(source.toFilePath()));
      } else {
        await player.setUrl(source.toString());
      }
      setState(() { playingVerse = verse; playingWholeSurah = false; });
      await widget.store.saveProgress(surah, verse);
      await player.play();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل الآية بهذا القارئ. تحقق من الإنترنت أو اختر قارئًا آخر.')));
    }
  }

  Future<void> _playWholeSurah() async {
    try {
      final verses = await widget.quran.verses(surah);
      final playlist = <AudioSource>[];
      for (final v in verses) {
        final source = await AudioLibrary.instance.sourceFor(widget.store.reciterId, surah, v.number);
        playlist.add(source.scheme == 'file' ? AudioSource.file(source.toFilePath()) : AudioSource.uri(source));
      }
      await player.setAudioSource(ConcatenatingAudioSource(children: playlist), initialIndex: 0, initialPosition: Duration.zero);
      setState(() { playingWholeSurah = true; playingVerse = 1; });
      await widget.store.saveProgress(surah, 1);
      await player.play();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل السورة كاملة. جرّب قارئًا آخر أو تحقق من الإنترنت.')));
    }
  }

  Future<void> _change(int n) async {
    if (n < 1 || n > 114) return;
    await player.stop();
    setState(() { surah = n; playingVerse = null; playingWholeSurah = false; surahName = ''; });
    await widget.store.saveProgress(n, 1);
    await _loadSurahName();
  }
}

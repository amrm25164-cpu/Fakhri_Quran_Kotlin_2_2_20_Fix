import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'quran_service.dart';
import 'reciters.dart';

/// Private on-device cache for recitation audio. EveryAyah is the remote source;
/// only files explicitly downloaded by the user are kept for offline playback.
class AudioLibrary {
  static final AudioLibrary instance = AudioLibrary._();
  AudioLibrary._();
  final http.Client _client = http.Client();
  bool _cancelRequested = false;

  Future<Directory> _directory(String reciterId) async {
    final root = await getApplicationSupportDirectory();
    final safeId = reciterId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final dir = Directory('${root.path}/recitations/$safeId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _fileName(int surah, int ayah) =>
      '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  String remoteUrl(String reciterId, int surah, int ayah) {
    final reciter = arabicReciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => arabicReciters.first,
    );
    return reciter.verseUrl(surah, ayah);
  }

  Future<File> fileFor(String reciterId, int surah, int ayah) async =>
      File('${(await _directory(reciterId)).path}/${_fileName(surah, ayah)}');

  Future<bool> hasVerse(String reciterId, int surah, int ayah) async =>
      await (await fileFor(reciterId, surah, ayah)).exists();

  Future<Uri> sourceFor(String reciterId, int surah, int ayah) async {
    final file = await fileFor(reciterId, surah, ayah);
    if (await file.exists() && await file.length() > 0) return Uri.file(file.path);
    return Uri.parse(remoteUrl(reciterId, surah, ayah));
  }

  Future<void> downloadSurah({
    required String reciterId,
    required int surahNumber,
    required QuranService quran,
    void Function(int done, int total)? onProgress,
  }) async {
    _cancelRequested = false;
    final verses = await quran.verses(surahNumber);
    for (var i = 0; i < verses.length; i++) {
      if (_cancelRequested) throw const AudioDownloadCancelled();
      await _downloadVerse(reciterId, surahNumber, verses[i].number);
      onProgress?.call(i + 1, verses.length);
    }
  }

  Future<void> downloadWholeQuran({
    required String reciterId,
    required QuranService quran,
    void Function(int surahDone, int surahTotal, int ayahDone, int ayahTotal)? onProgress,
  }) async {
    _cancelRequested = false;
    final surahs = await quran.surahs();
    var done = 0;
    var totalAyahs = 0;
    for (final s in surahs) { totalAyahs += s.ayahCount; }
    for (var i = 0; i < surahs.length; i++) {
      if (_cancelRequested) throw const AudioDownloadCancelled();
      final verses = await quran.verses(surahs[i].number);
      for (final verse in verses) {
        if (_cancelRequested) throw const AudioDownloadCancelled();
        final cached = await hasVerse(reciterId, surahs[i].number, verse.number);
        await _downloadVerse(reciterId, surahs[i].number, verse.number);
        done++;
        onProgress?.call(i + 1, surahs.length, done, totalAyahs);
        // Pace new network requests without slowing down a resumed download.
        if (!cached) await Future<void>.delayed(const Duration(milliseconds: 70));
      }
    }
  }

  void cancelDownload() { _cancelRequested = true; }

  Future<File> _downloadVerse(String reciterId, int surah, int ayah) async {
    final target = await fileFor(reciterId, surah, ayah);
    if (await target.exists() && await target.length() > 0) return target;
    final temp = File('${target.path}.part');
    try {
      final response = await _client.get(Uri.parse(remoteUrl(reciterId, surah, ayah)))
          .timeout(const Duration(seconds: 35));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw HttpException('Audio source returned ${response.statusCode}');
      }
      await temp.writeAsBytes(response.bodyBytes, flush: true);
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      return target;
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }

  Future<int> cachedVerseCount(String reciterId) async {
    final dir = await _directory(reciterId);
    if (!await dir.exists()) return 0;
    return dir.list().where((e) => e is File && e.path.endsWith('.mp3')).length;
  }

  Future<void> clearReciter(String reciterId) async {
    final dir = await _directory(reciterId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

class AudioDownloadCancelled implements Exception {
  const AudioDownloadCancelled();
  @override
  String toString() => 'Audio download cancelled';
}

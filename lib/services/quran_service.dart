import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/quran.dart';

/// Quran data client with persistent JSON cache so previously downloaded text
/// remains readable without a network connection.
class QuranService {
  static const _base = 'https://api.alquran.cloud/v1';
  final Map<int, List<Verse>> _cache = {};
  final Map<String, List<String>> _editionCache = {};
  List<Surah>? _surahs;
  Directory? _cacheDirectory;

  Future<Directory> get _diskCache async {
    if (_cacheDirectory != null) return _cacheDirectory!;
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/quran_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDirectory = dir;
    return dir;
  }

  Future<File> _cacheFile(String name) async => File('${(await _diskCache).path}/$name.json');

  Future<dynamic> _readJson(String name) async {
    try {
      final file = await _cacheFile(name);
      if (await file.exists()) return jsonDecode(await file.readAsString());
    } catch (_) {}
    return null;
  }

  Future<void> _writeJson(String name, Object data) async {
    final file = await _cacheFile(name);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(data), flush: true);
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }

  Future<List<Surah>> surahs({bool refresh = false}) async {
    if (!refresh && _surahs != null) return _surahs!;
    if (!refresh) {
      final cached = await _readJson('surah_list');
      if (cached is List) {
        _surahs = cached.map((e) => Surah.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        return _surahs!;
      }
    }
    final response = await http.get(Uri.parse('$_base/surah')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('تعذر تحميل قائمة السور (${response.statusCode})');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['data'] as List;
    _surahs = raw.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
    await _writeJson('surah_list', raw);
    return _surahs!;
  }

  Future<List<String>> editionTexts(int number, String edition, {bool refresh = false}) async {
    final key = '$number:$edition';
    if (!refresh && _editionCache.containsKey(key)) return _editionCache[key]!;
    final fileKey = 'edition_${edition.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}_$number';
    if (!refresh) {
      final cached = await _readJson(fileKey);
      if (cached is List) {
        final texts = cached.map((e) => e.toString()).toList();
        _editionCache[key] = texts;
        return texts;
      }
    }
    final response = await http.get(Uri.parse('$_base/surah/$number/$edition')).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('تعذر تحميل النص الإضافي (${response.statusCode})');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    final dynamic ayahs = data is Map<String, dynamic> ? data['ayahs'] : null;
    if (ayahs is! List) throw Exception('صيغة بيانات النص الإضافي غير متوقعة');
    final texts = ayahs.map<String>((e) => (e as Map<String, dynamic>)['text'] as String).toList();
    _editionCache[key] = texts;
    await _writeJson(fileKey, texts);
    return texts;
  }

  Future<List<Verse>> verses(int number, {bool refresh = false}) async {
    if (!refresh && _cache.containsKey(number)) return _cache[number]!;
    if (!refresh) {
      final cached = await _readJson('verses_$number');
      if (cached is List) {
        final verses = cached.map((e) => Verse.fromJson(Map<String, dynamic>.from(e as Map), number)).toList();
        _cache[number] = verses;
        return verses;
      }
    }
    final response = await http.get(Uri.parse('$_base/surah/$number/quran-uthmani')).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('تعذر تحميل الآيات (${response.statusCode})');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final raw = data['ayahs'] as List;
    final list = raw.map((e) => Verse.fromJson(e as Map<String, dynamic>, number)).toList();
    _cache[number] = list;
    await _writeJson('verses_$number', raw);
    return list;
  }

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final term = query.trim();
    if (term.isEmpty) return <Map<String, dynamic>>[];
    final uri = Uri.parse('$_base/search/${Uri.encodeComponent(term)}/all/quran-uthmani');
    final response = await http.get(uri).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw Exception('تعذر البحث في القرآن (${response.statusCode})');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>;
    final matches = data['matches'] as List? ?? const [];
    return matches.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Downloads one translation/tafsir edition for all surahs for offline reading.
  Future<void> downloadWholeEdition(String edition, {void Function(int done, int total)? onProgress}) async {
    final allSurahs = await surahs();
    for (var i = 0; i < allSurahs.length; i++) {
      await editionTexts(allSurahs[i].number, edition);
      onProgress?.call(i + 1, allSurahs.length);
    }
  }

  /// Downloads all 114 surahs and their Uthmani text to the app's private cache.
  /// Progress is a fraction in the inclusive range 0.0–1.0.
  Future<void> downloadWholeQuran({void Function(int done, int total)? onProgress}) async {
    final allSurahs = await surahs();
    const total = 114;
    for (var i = 0; i < allSurahs.length; i++) {
      await verses(allSurahs[i].number);
      onProgress?.call(i + 1, total);
    }
  }

  Future<bool> isSurahCached(int number) async => await (await _cacheFile('verses_$number')).exists();

  Future<void> clearTextCache() async {
    final dir = await _diskCache;
    if (await dir.exists()) await dir.delete(recursive: true);
    _cacheDirectory = null;
    _surahs = null;
    _cache.clear();
    _editionCache.clear();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStore extends ChangeNotifier {
  AppStore(this._prefs);
  final SharedPreferences _prefs;
  bool get darkMode => _prefs.getBool('darkMode') ?? false;
  double get fontSize => _prefs.getDouble('fontSize') ?? 28;
  int get lastSurah => _prefs.getInt('lastSurah') ?? 1;
  int get lastVerse => _prefs.getInt('lastVerse') ?? 1;
  int get tasbeeh => _prefs.getInt('tasbeeh') ?? 0;
  String get reciterId => _prefs.getString('reciterId') ?? 'Alafasy_128kbps';
  String? get customFontPath => _prefs.getString('customFontPath');
  String get fontFamily => customFontPath == null ? 'UthmanicHafs' : 'ImportedQuranFont';
  List<String> get bookmarks => _prefs.getStringList('bookmarks') ?? [];
  List<String> get favorites => _prefs.getStringList('favorites') ?? [];
  Future<void> setReciter(String id) async { await _prefs.setString('reciterId', id); notifyListeners(); }
  Future<void> setCustomFontPath(String path) async { await _prefs.setString('customFontPath', path); notifyListeners(); }
  Future<void> clearCustomFontPath() async { await _prefs.remove('customFontPath'); notifyListeners(); }
  Future<void> toggleTheme() async { await _prefs.setBool('darkMode', !darkMode); notifyListeners(); }
  Future<void> setFontSize(double v) async { await _prefs.setDouble('fontSize', v); notifyListeners(); }
  Future<void> saveProgress(int s, int v) async { await _prefs.setInt('lastSurah', s); await _prefs.setInt('lastVerse', v); notifyListeners(); }
  Future<void> toggleBookmark(int s, int v) async { final a=bookmarks; final k='$s:$v'; a.contains(k) ? a.remove(k) : a.add(k); await _prefs.setStringList('bookmarks', a); notifyListeners(); }
  Future<void> toggleFavorite(int s) async { final a=favorites; final k='$s'; a.contains(k) ? a.remove(k) : a.add(k); await _prefs.setStringList('favorites', a); notifyListeners(); }
  Future<void> incrementTasbeeh() async { await _prefs.setInt('tasbeeh', tasbeeh+1); notifyListeners(); }
  Future<void> resetTasbeeh() async { await _prefs.setInt('tasbeeh', 0); notifyListeners(); }
  int dhikrCount(String id) => _prefs.getInt('dhikr_$id') ?? 0;
  Future<void> incrementDhikr(String id) async { await _prefs.setInt('dhikr_$id', dhikrCount(id) + 1); notifyListeners(); }
  Future<void> resetDhikr(String id) async { await _prefs.setInt('dhikr_$id', 0); notifyListeners(); }
}

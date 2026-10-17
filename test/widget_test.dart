import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fakhri_quran/models/quran.dart';
import 'package:fakhri_quran/services/app_store.dart';
import 'package:fakhri_quran/services/reciters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Surah model parses API fields', () {
    final surah = Surah.fromJson({
      'number': 1,
      'name': 'سُورَةُ الْفَاتِحَةِ',
      'englishName': 'Al-Faatiha',
      'numberOfAyahs': 7,
    });
    expect(surah.number, 1);
    expect(surah.ayahCount, 7);
    expect(surah.englishName, 'Al-Faatiha');
  });

  test('reading progress and dhikr counters persist', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    await store.saveProgress(2, 255);
    await store.incrementDhikr('subhanallah');
    expect(store.lastSurah, 2);
    expect(store.lastVerse, 255);
    expect(store.dhikrCount('subhanallah'), 1);
  });

  test('reciter URLs follow EveryAyah file naming', () {
    final reciter = arabicReciters.first;
    expect(reciter.verseUrl(1, 1), contains('/001001.mp3'));
    expect(reciter.sourceUrl, startsWith('https://everyayah.com/data/'));
  });
}

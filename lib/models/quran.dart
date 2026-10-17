class Surah {
  const Surah({required this.number, required this.name, required this.englishName, required this.ayahCount});
  final int number;
  final String name, englishName;
  final int ayahCount;
  factory Surah.fromJson(Map<String, dynamic> j) => Surah(number: j['number'] as int, name: j['name'] as String, englishName: j['englishName'] as String, ayahCount: j['numberOfAyahs'] as int);
}
class Verse {
  const Verse({required this.number, required this.text, required this.surahNumber});
  final int number, surahNumber;
  final String text;
  factory Verse.fromJson(Map<String, dynamic> j, int surah) => Verse(number: j['numberInSurah'] as int, text: j['text'] as String, surahNumber: surah);
}

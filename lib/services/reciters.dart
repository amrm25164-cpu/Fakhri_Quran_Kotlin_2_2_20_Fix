class QuranReciter {
  const QuranReciter(this.id, this.name, this.description);
  final String id;
  final String name;
  final String description;
  String get sourceUrl => 'https://everyayah.com/data/$id/';
  String verseUrl(int surah, int ayah) => '$sourceUrl${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
}

/// Audio directory names provided by EveryAyah. Requires internet access.
const arabicReciters = <QuranReciter>[
  QuranReciter('Alafasy_128kbps', 'مشاري العفاسي', 'مرتل'),
  QuranReciter('Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد', 'مرتل'),
  QuranReciter('Abdul_Basit_Mujawwad_128kbps', 'عبد الباسط عبد الصمد', 'مجود'),
  QuranReciter('Husary_128kbps', 'محمود خليل الحصري', 'مرتل'),
  QuranReciter('Husary_Muallim_128kbps', 'محمود خليل الحصري', 'معلم'),
  QuranReciter('Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي', 'مرتل'),
  QuranReciter('Minshawy_Mujawwad_192kbps', 'محمد صديق المنشاوي', 'مجود'),
  QuranReciter('Maher_AlMuaiqly_128kbps', 'ماهر المعيقلي', 'مرتل'),
  QuranReciter('Saood_ash-Shuraym_128kbps', 'سعود الشريم', 'مرتل'),
  QuranReciter('Abdurrahmaan_As-Sudais_192kbps', 'عبد الرحمن السديس', 'مرتل'),
  QuranReciter('Hani_Rifai_192kbps', 'هاني الرفاعي', 'مرتل'),
  QuranReciter('Yasser_Ad-Dussary_128kbps', 'ياسر الدوسري', 'مرتل'),
  QuranReciter('Nasser_Alqatami_128kbps', 'ناصر القطامي', 'مرتل'),
  QuranReciter('Ibrahim_Akhdar_32kbps', 'إبراهيم الأخضر', 'مرتل'),
  QuranReciter('Muhammad_Ayyoub_128kbps', 'محمد أيوب', 'مرتل'),
  QuranReciter('Abu_Bakr_Ash-Shaatree_128kbps', 'أبو بكر الشاطري', 'مرتل'),
  QuranReciter('Ahmed_ibn_Ali_al-Ajamy_128kbps', 'أحمد العجمي', 'مرتل'),
  QuranReciter('Khaalid_Abdullaah_al-Qahtaanee_192kbps', 'خالد القحطاني', 'مرتل'),
  QuranReciter('Salah_Al_Budair_128kbps', 'صلاح البدير', 'مرتل'),
  QuranReciter('Mohammad_al_Tablaway_128kbps', 'محمد الطبلاوي', 'مرتل'),
];

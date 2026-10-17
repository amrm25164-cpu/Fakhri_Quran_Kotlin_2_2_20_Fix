import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/quran_service.dart';
import 'services/app_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(await SharedPreferences.getInstance());
  final customFont = store.customFontPath;
  if (customFont != null) {
    try {
      final bytes = await File(customFont).readAsBytes();
      final loader = ui.FontLoader('ImportedQuranFont')..addFont(Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    } catch (_) { await store.clearCustomFontPath(); }
  }
  runApp(FakhriQuranApp(store: store, quran: QuranService()));
}

class FakhriQuranApp extends StatelessWidget {
  const FakhriQuranApp({super.key, required this.store, required this.quran});
  final AppStore store;
  final QuranService quran;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (_, __) => MaterialApp(
      title: 'Fakhri Quran',
      debugShowCheckedModeBanner: false,
      themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff145943), secondary: const Color(0xffc9a44c), brightness: Brightness.light), useMaterial3: true),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff145943), secondary: const Color(0xffd6b45f), brightness: Brightness.dark), useMaterial3: true),
      home: HomeScreen(store: store, quran: quran),
    ),
  );
}
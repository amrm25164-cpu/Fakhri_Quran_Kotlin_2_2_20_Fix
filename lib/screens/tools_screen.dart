import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/reader_screen.dart';
import '../services/quran_service.dart';
import '../services/app_store.dart';
import '../services/reciters.dart';
import '../services/audio_library.dart';
import '../models/quran.dart';
import '../services/prayer_notifications.dart';

class ToolsScreen extends StatefulWidget {const ToolsScreen({super.key,required this.store,required this.quran});final AppStore store;final QuranService quran;@override State<ToolsScreen> createState()=>_ToolsScreenState();}
class _ToolsScreenState extends State<ToolsScreen>{
 late final AudioPlayer player; String status='لم يبدأ التشغيل';
 final cityController = TextEditingController(text: 'Cairo');
 final latitudeController = TextEditingController(text: '30.0444');
 final longitudeController = TextEditingController(text: '31.2357');
 Map<String, String>? prayerTimes; String prayerStatus = 'أدخل اسم المدينة ثم اضغط تحديث'; String notificationStatus='تنبيهات الصلاة غير مفعّلة';
 double? qiblaBearing;
 bool downloadingQuran = false; int downloadDone = 0; String downloadStatus = 'نزّل نص القرآن كاملًا للاستخدام دون إنترنت';
 int selectedAudioSurah = 1; bool downloadingAudio = false; int audioDone = 0; int audioTotal = 0; String audioStatus = 'نزّل سورة للاستماع إليها دون إنترنت';
 bool downloadingTranslation=false; int translationDone=0; String translationStatus='نزّل التفسير الميسر أو ترجمة للقراءة دون إنترنت';
 @override void initState(){super.initState();player=AudioPlayer();}
 @override void dispose(){player.dispose();cityController.dispose();latitudeController.dispose();longitudeController.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(18),children:[
 const Text('الأدوات',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:14),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('مشغل التلاوة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const Text('اختر قارئًا عربيًا. يستخدم الملفات المحمّلة محليًا إن وُجدت، وإلا يحتاج اتصالًا بالإنترنت.'),
 const Text('المصدر الصوتي: EveryAyah — ملفات MP3 بحسب مجلد القارئ.'),
 DropdownButtonFormField<String>(value: arabicReciters.any((r)=>r.id==widget.store.reciterId)?widget.store.reciterId:arabicReciters.first.id,decoration:const InputDecoration(labelText:'القارئ'),items:arabicReciters.map((r)=>DropdownMenuItem(value:r.id,child:Text('${r.name} — ${r.description}',overflow:TextOverflow.ellipsis))).toList(),onChanged:(id){if(id!=null)widget.store.setReciter(id);}),
 const SizedBox(height:8),Text(status,style:const TextStyle(color:Colors.grey)),Wrap(spacing:8,children:[
 FilledButton.icon(onPressed:_play,icon:const Icon(Icons.play_arrow),label:const Text('تشغيل الفاتحة')),
 IconButton(onPressed:()=>player.pause(),icon:const Icon(Icons.pause)),IconButton(onPressed:()=>player.stop(),icon:const Icon(Icons.stop))
 ])
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('تنزيل التلاوات للاستماع دون إنترنت',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('يمكن تنزيل سورة واحدة للقارئ المختار. تنزيل القرآن الصوتي كاملًا قد يحتاج مساحة كبيرة جدًا ووقتًا طويلًا.'),
 FutureBuilder<List<Surah>>(future:widget.quran.surahs(),builder:(context,snapshot){
   final surahs=snapshot.data;
   if(snapshot.hasError)return const Padding(padding:EdgeInsets.all(8),child:Text('تعذر تحميل قائمة السور. تحقق من الإنترنت.'));
   if(surahs==null)return const Padding(padding:EdgeInsets.all(8),child:LinearProgressIndicator());
   return DropdownButtonFormField<int>(value:selectedAudioSurah,decoration:const InputDecoration(labelText:'السورة'),items:surahs.map((s)=>DropdownMenuItem<int>(value:s.number,child:Text('${s.number}. ${s.name}'))).toList(),onChanged:downloadingAudio?null:(v){if(v!=null)setState(()=>selectedAudioSurah=v);});
 }),
 const SizedBox(height:8),Text(audioStatus,style:const TextStyle(color:Colors.grey)),
 if(downloadingAudio && audioTotal>0) LinearProgressIndicator(value:audioDone/audioTotal),
 Wrap(spacing:8,runSpacing:8,children:[
  FilledButton.icon(onPressed:downloadingAudio?null:_downloadSelectedSurahAudio,icon:const Icon(Icons.download),label:const Text('تنزيل السورة المحددة')),
  OutlinedButton.icon(onPressed:downloadingAudio?AudioLibrary.instance.cancelDownload:null,icon:const Icon(Icons.cancel_outlined),label:const Text('إلغاء التنزيل')),
  TextButton(onPressed:downloadingAudio?null:_clearCurrentReciterAudio,child:const Text('مسح تنزيلات القارئ')),
  TextButton(onPressed:downloadingAudio?null:_showWholeAudioWarning,child:const Text('تنزيل القرآن الصوتي كاملًا')),
 ]),
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('مواقيت الصلاة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('أوقات تقريبية حسب المدينة وطريقة الحساب؛ راجع جهة محلية موثوقة للتأكد.'),
 TextField(controller:cityController,decoration:const InputDecoration(labelText:'المدينة',hintText:'Cairo'),textInputAction:TextInputAction.done),
 const SizedBox(height:8),
 FilledButton.icon(onPressed:_loadPrayerTimes,icon:const Icon(Icons.refresh),label:const Text('تحديث المواقيت')),
 Text(prayerStatus,style:const TextStyle(color:Colors.grey)),
 if(prayerTimes!=null) ...prayerTimes!.entries.map((e)=>ListTile(dense:true,title:Text(e.key),trailing:Text(e.value))),
 if(prayerTimes!=null) ...[Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:_enablePrayerNotifications,icon:const Icon(Icons.notifications_active),label:const Text('تفعيل تنبيهات الصلاة اليومية')),OutlinedButton.icon(onPressed:_disablePrayerNotifications,icon:const Icon(Icons.notifications_off),label:const Text('إلغاء التنبيهات'))]),Text(notificationStatus,style:const TextStyle(color:Colors.grey))],
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('القرآن دون إنترنت',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('يحفظ نص السور الـ114 داخل مساحة التطبيق. هذا التنزيل للنص فقط، ولا يشمل ملفات الصوت أو التفسير.'),
 const SizedBox(height:8),
 if(downloadingQuran) LinearProgressIndicator(value:downloadDone/114),
 Text(downloadStatus,style:const TextStyle(color:Colors.grey)),
 const SizedBox(height:8),
 FilledButton.icon(onPressed:downloadingQuran?null:_downloadQuran,icon:const Icon(Icons.download),label:Text(downloadingQuran?'جارٍ التنزيل $downloadDone/114':'تنزيل القرآن كاملًا')),
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('التفسير والترجمات دون إنترنت',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('اختر إصدارًا لتنزيله لكل السور. التنزيل يحتاج إنترنت ومساحة تخزين.'),
 if(downloadingTranslation) LinearProgressIndicator(value:translationDone/114),
 Text(translationStatus,style:const TextStyle(color:Colors.grey)),
 Wrap(spacing:8,runSpacing:8,children:[
  FilledButton.tonal(onPressed:downloadingTranslation?null:()=>_downloadEdition('ar.muyassar','التفسير الميسر'),child:const Text('تنزيل التفسير الميسر')),
  OutlinedButton(onPressed:downloadingTranslation?null:()=>_downloadEdition('en.sahih','English Sahih'),child:const Text('تنزيل الإنجليزية')),
  OutlinedButton(onPressed:downloadingTranslation?null:()=>_downloadEdition('fr.hamidullah','Français'),child:const Text('تنزيل الفرنسية')),
 ]),
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('اتجاه القبلة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('أدخل إحداثيات موقعك يدويًا لحساب الزاوية، ثم استخدم سهم البوصلة إذا كان مستشعر الهاتف متاحًا.'),
 Row(children:[Expanded(child:TextField(controller:latitudeController,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'خط العرض'))),const SizedBox(width:8),Expanded(child:TextField(controller:longitudeController,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'خط الطول')))]),
 const SizedBox(height:8),
 FilledButton.icon(onPressed:_calculateQibla,icon:const Icon(Icons.explore),label:const Text('حساب اتجاه القبلة')),
 if(qiblaBearing!=null) ...[
  Text('اتجه نحو ${qiblaBearing!.round()}° من الشمال باتجاه عقارب الساعة',style:const TextStyle(fontWeight:FontWeight.bold)),
  const SizedBox(height:8),
  StreamBuilder<CompassEvent>(stream:FlutterCompass.events,builder:(context,snapshot){
   final heading=snapshot.data?.heading;
   if(heading==null)return const Text('مستشعر البوصلة غير متاح على هذا الجهاز؛ استخدم زاوية القبلة المحسوبة.');
   final rotation=(qiblaBearing!-heading)*math.pi/180;
   return Column(children:[Transform.rotate(angle:rotation,child:const Icon(Icons.navigation,size:72,color:Color(0xffc9a44c))),Text('اتجاه البوصلة: ${heading.round()}°')]);
  }),
 ],
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('مصادر النص والصوت',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const SizedBox(height:6),
 const Text('النص والروايات الصوتية تعتمد على خدمات خارجية؛ يلزم الإنترنت وقد تختلف إتاحة بعض الملفات.'),
 Wrap(spacing:8,runSpacing:8,children:[
 OutlinedButton.icon(onPressed:()=>_open('https://everyayah.com/'),icon:const Icon(Icons.open_in_new),label:const Text('EveryAyah — الصوت')),
 OutlinedButton.icon(onPressed:()=>_open('https://alquran.cloud/api'),icon:const Icon(Icons.open_in_new),label:const Text('AlQuran Cloud — النص')),
 OutlinedButton.icon(onPressed:()=>_open('https://alquran.cloud/cdn'),icon:const Icon(Icons.open_in_new),label:const Text('توثيق CDN الصوتي')),
 ]),
 const SizedBox(height:8),
 Text('مصدر القارئ المحدد: ${arabicReciters.firstWhere((r)=>r.id==widget.store.reciterId,orElse:()=>arabicReciters.first).sourceUrl}',style:const TextStyle(fontSize:11,color:Colors.grey)),
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('علامات القراءة المحفوظة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 if(widget.store.bookmarks.isEmpty) const Padding(padding:EdgeInsets.all(8),child:Text('لم تحفظ أي آية بعد. استخدم رمز العلامة داخل شاشة القراءة.')),
 ...widget.store.bookmarks.map((key){final parts=key.split(':');final s=int.tryParse(parts.first)??1;final v=parts.length>1?(int.tryParse(parts[1])??1):1;return ListTile(dense:true,leading:const Icon(Icons.bookmark),title:Text('سورة $s — آية $v'),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReaderScreen(surahNumber:s,store:widget.store,quran:widget.quran))));}),
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Text('الخط القرآني',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(widget.store.customFontPath==null?'الخط الحالي: عثماني حفص المرفق':'الخط الحالي: ${widget.store.customFontPath!.split('/').last}'),const SizedBox(height:8),Wrap(spacing:8,children:[FilledButton.icon(onPressed:_pickFont,icon:const Icon(Icons.font_download),label:const Text('إضافة خط من الجهاز')),if(widget.store.customFontPath!=null)TextButton(onPressed:()async{await widget.store.clearCustomFontPath();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('سيتم استخدام خط عثماني حفص المرفق بعد إعادة فتح التطبيق.')));},child:const Text('استخدام الخط الافتراضي'))]),const Text('الخطوط المدعومة: TTF وOTF. قد تحتاج لإعادة فتح شاشة القراءة أو التطبيق بعد التغيير.'),
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
 const Text('التسبيح',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text('${widget.store.tasbeeh}',style:const TextStyle(fontSize:44,color:Color(0xffc9a44c))),FilledButton(onPressed:widget.store.incrementTasbeeh,child:const Text('سبحان الله')),TextButton(onPressed:widget.store.resetTasbeeh,child:const Text('تصفير العداد'))
 ]))),
 Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('الأذكار والعدادات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('عداد مستقل لكل ذكر، محفوظ على الجهاز. الأعداد أهداف مقترحة وليست إلزامية.'),
 _dhikrTile('subhanallah','سبحان الله وبحمده',100),
 _dhikrTile('istighfar','أستغفر الله وأتوب إليه',100),
 _dhikrTile('subhan','سبحان الله',33),
 _dhikrTile('hamd','الحمد لله',33),
 _dhikrTile('takbir','الله أكبر',34),
 _dhikrTile('tahlil','لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',1),
 const SizedBox(height:8),const Text('للتوثيق والتفصيل، راجع كتاب الأذكار للإمام النووي أو مصدرًا حديثيًا موثوقًا.',style:TextStyle(fontSize:12,color:Colors.grey))
 ]))),
 ListTile(leading:const Icon(Icons.info_outline),title:const Text('حول فخري قرآن'),subtitle:const Text('النص القرآني عبر AlQuran Cloud؛ الصوت من EveryAyah.'),onTap:()=>showAboutDialog(context:context,applicationName:'فخري قرآن',applicationVersion:'1.0.0',children:[const Text('قارئ قرآني عربي مع حفظ محلي ومعاينة تصميم الآيات.')]))
 ]));
 Widget _dhikrTile(String id, String text, int target) {
  final count=widget.store.dhikrCount(id);
  return ListTile(
   contentPadding:EdgeInsets.zero,
   title:Text(text),
   subtitle:Text('العدد: $count / $target'),
   trailing:Wrap(spacing:0,children:[
    IconButton(tooltip:'تصفير',onPressed:()=>widget.store.resetDhikr(id),icon:const Icon(Icons.refresh)),
    FilledButton.tonal(onPressed:()=>widget.store.incrementDhikr(id),child:Text('$count +')),
   ]),
  );
 }

 Future<void> _clearCurrentReciterAudio() async {
  final confirmed=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('مسح التلاوات المحمّلة؟'),content:const Text('سيتم حذف ملفات الصوت المحفوظة لهذا القارئ فقط.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('مسح'))]));
  if(confirmed!=true || !mounted)return;
  try {
   await AudioLibrary.instance.clearReciter(widget.store.reciterId);
   if(mounted)setState(()=>audioStatus='تم حذف ملفات الصوت لهذا القارئ.');
  } catch (_) {if(mounted)setState(()=>audioStatus='تعذر مسح الملفات المحمّلة.');}
 }

 Future<void> _downloadSelectedSurahAudio() async {
  setState(() { downloadingAudio=true; audioDone=0; audioTotal=0; audioStatus='جارٍ تجهيز التنزيل…'; });
  try {
   final verses=await widget.quran.verses(selectedAudioSurah);
   setState(()=>audioTotal=verses.length);
   await AudioLibrary.instance.downloadSurah(reciterId:widget.store.reciterId,surahNumber:selectedAudioSurah,quran:widget.quran,onProgress:(done,total){if(mounted)setState(()=>{audioDone=done,audioTotal=total,audioStatus='تم تنزيل $done من $total آية'});});
   if(mounted)setState(()=>audioStatus='اكتمل تنزيل السورة. يمكنك تشغيلها دون إنترنت لهذا القارئ.');
  } catch (e) {
   if(mounted)setState(()=>audioStatus=e is AudioDownloadCancelled?'تم إلغاء التنزيل.':'فشل التنزيل؛ تحقق من الإنترنت أو جرّب قارئًا آخر.');
  } finally {if(mounted)setState(()=>downloadingAudio=false);}
 }
 Future<void> _showWholeAudioWarning() async {
  final confirmed=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('تنزيل القرآن الصوتي كاملًا؟'),content:const Text('قد يتطلب هذا آلاف الملفات ومساحة تخزين كبيرة جدًا، وقد يستغرق وقتًا طويلًا. الأفضل تنزيل السور التي تحتاجها. هل تريد المتابعة؟'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('ليس الآن')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('متابعة'))]));
  if(confirmed!=true || !mounted)return;
  setState(()=>{downloadingAudio=true,audioDone=0,audioTotal=6236,audioStatus='جارٍ تنزيل القرآن الصوتي؛ لا تغلق التطبيق'});
  try {
   await AudioLibrary.instance.downloadWholeQuran(reciterId:widget.store.reciterId,quran:widget.quran,onProgress:(sDone,sTotal,aDone,aTotal){if(mounted)setState(()=>{audioDone=aDone,audioTotal=aTotal,audioStatus='السورة $sDone من $sTotal — الآية الصوتية $aDone من $aTotal'});});
   if(mounted)setState(()=>audioStatus='اكتمل تنزيل القرآن الصوتي للقارئ المحدد.');
  } catch(e) {if(mounted)setState(()=>audioStatus=e is AudioDownloadCancelled?'تم إلغاء التنزيل.':'توقف التنزيل بسبب مشكلة في الاتصال؛ أعد المحاولة لاستكمال الملفات غير الموجودة.');}
  finally {if(mounted)setState(()=>downloadingAudio=false);}
 }

 Future<void> _downloadQuran() async {
  setState(() { downloadingQuran = true; downloadDone = 0; downloadStatus = 'جارٍ حفظ النص القرآني…'; });
  try {
   await widget.quran.downloadWholeQuran(onProgress: (done, total) {
    if (mounted) setState(() { downloadDone = done; downloadStatus = 'تم حفظ $done من $total سورة'; });
   });
   if (mounted) setState(() => downloadStatus = 'اكتمل تنزيل نص القرآن. يمكنك فتح السور دون إنترنت.');
  } catch (_) {
   if (mounted) setState(() => downloadStatus = 'توقف التنزيل عند السورة $downloadDone؛ تحقق من الإنترنت ثم أعد المحاولة.');
  } finally { if (mounted) setState(() => downloadingQuran = false); }
 }

 Future<void> _downloadEdition(String edition, String label) async {
  setState(()=>{downloadingTranslation=true,translationDone=0,translationStatus='جارٍ تنزيل $label…'});
  try {
   await widget.quran.downloadWholeEdition(edition,onProgress:(done,total){if(mounted)setState(()=>{translationDone=done,translationStatus='تم حفظ $done من $total سورة'});});
   if(mounted)setState(()=>translationStatus='اكتمل تنزيل $label لجميع السور.');
  } catch (_) {if(mounted)setState(()=>translationStatus='توقف التنزيل. تحقق من الإنترنت ثم أعد المحاولة.');}
  finally {if(mounted)setState(()=>downloadingTranslation=false);}
 }

 Future<void> _disablePrayerNotifications() async {
  try {
   await PrayerNotificationService.instance.cancelPrayerTimes();
   if(mounted)setState(()=>notificationStatus='تم إلغاء تنبيهات الصلاة اليومية.');
  } catch (_) {if(mounted)setState(()=>notificationStatus='تعذر إلغاء التنبيهات.');}
 }

 Future<void> _enablePrayerNotifications() async {
  final timings=prayerTimes;
  if(timings==null){setState(()=>notificationStatus='حمّل مواقيت الصلاة أولًا');return;}
  setState(()=>notificationStatus='جارٍ إعداد التنبيهات…');
  try {
   await PrayerNotificationService.instance.scheduleDailyPrayerTimes(timings);
   if(mounted)setState(()=>notificationStatus='تم إعداد التنبيهات اليومية للأوقات الظاهرة. راجع إعدادات البطارية والإشعارات إذا لم تظهر.');
  } catch (_) {if(mounted)setState(()=>notificationStatus='تعذر إعداد التنبيهات. اسمح بإشعارات التطبيق من إعدادات الهاتف.');}
 }

 Future<void> _loadPrayerTimes() async {
  final city = cityController.text.trim();
  if(city.isEmpty){setState(()=>prayerStatus='اكتب اسم المدينة أولًا');return;}
  setState(()=>prayerStatus='جارٍ تحميل المواقيت…');
  try {
   final uri=Uri.https('api.aladhan.com','/v1/timingsByCity',{'city':city,'country':'Egypt','method':'5'});
   final response=await http.get(uri).timeout(const Duration(seconds:15));
   if(response.statusCode!=200) throw Exception('HTTP ${response.statusCode}');
   final root=jsonDecode(response.body) as Map<String,dynamic>;
   final data=root['data'] as Map<String,dynamic>;
   final raw=data['timings'] as Map<String,dynamic>;
   const keys=['Fajr','Sunrise','Dhuhr','Asr','Maghrib','Isha'];
   const labels={'Fajr':'الفجر','Sunrise':'الشروق','Dhuhr':'الظهر','Asr':'العصر','Maghrib':'المغرب','Isha':'العشاء'};
   final values=<String,String>{};
   for(final key in keys){final value=(raw[key]??'—').toString().split(' ').first;values[labels[key]??key]=value;}
   if(mounted)setState(() { prayerTimes=values; prayerStatus='تم تحميل المواقيت لمدينة $city'; });
  } catch (_) {if(mounted)setState(()=>prayerStatus='تعذر تحميل المواقيت. تحقق من المدينة والإنترنت.');}
 }
 void _calculateQibla(){
  final lat=double.tryParse(latitudeController.text.trim());
  final lon=double.tryParse(longitudeController.text.trim());
  if(lat==null||lon==null||lat < -90||lat > 90||lon < -180||lon > 180){setState(()=>qiblaBearing=null);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل إحداثيات صحيحة')));return;}
  const kaabaLat=21.422487, kaabaLon=39.826206;
  final phi1=lat*math.pi/180, phi2=kaabaLat*math.pi/180, delta=(kaabaLon-lon)*math.pi/180;
  final y=math.sin(delta), x=math.cos(phi1)*math.tan(phi2)-math.sin(phi1)*math.cos(delta);
  final bearing=(math.atan2(y,x)*180/math.pi+360)%360;
  setState(()=>qiblaBearing=bearing);
 }
 Future<void> _open(String value) async { final uri=Uri.parse(value); if(!await launchUrl(uri,mode:LaunchMode.externalApplication) && mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر فتح الرابط')));} }
 Future<void> _play()async{try{setState(()=>status='جارٍ تحميل تلاوة الفاتحة…');final source=await AudioLibrary.instance.sourceFor(widget.store.reciterId,1,1);if(source.scheme=='file'){await player.setAudioSource(AudioSource.file(source.toFilePath()));}else{await player.setUrl(source.toString());}if(mounted)setState(()=>status='تلاوة سورة الفاتحة — ${arabicReciters.firstWhere((r)=>r.id==widget.store.reciterId,orElse:()=>arabicReciters.first).name}');await player.play();}catch(e){if(mounted)setState(()=>status='تعذر تشغيل الصوت. تحقق من الإنترنت أو اختر قارئًا آخر.');}}
 Future<void> _pickFont() async {
  try {
   final result = await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['ttf','otf'],withData:true);
   if(result==null || result.files.single.bytes==null || !mounted) return;
   final file=result.files.single; final dir=await getApplicationDocumentsDirectory();
   final safeName=file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
   final target=File('${dir.path}/$safeName'); await target.writeAsBytes(file.bytes!,flush:true);
   final bytes=await target.readAsBytes();
   final loader=ui.FontLoader('ImportedQuranFont')..addFont(Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))));
   await loader.load(); await widget.store.setCustomFontPath(target.path);
   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة الخط. افتح شاشة القراءة من جديد لتطبيقه.')));
  } catch (_) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('لم نتمكن من تحميل الخط. تأكد أن الملف TTF أو OTF صالح.'))); }
 }
}

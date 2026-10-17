import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../services/reciters.dart';
import '../services/app_store.dart';
import '../services/quran_service.dart';

class StudioScreen extends StatefulWidget {
 const StudioScreen({super.key,required this.store,required this.quran});
 final AppStore store; final QuranService quran;
 @override State<StudioScreen> createState()=>_StudioScreenState();
}
class _StudioScreenState extends State<StudioScreen>{
 final GlobalKey previewKey = GlobalKey();
 bool exporting = false; bool exportingVideo = false; String videoStatus = '';
 int surah=1,verse=1; double size=27; Color bg=const Color(0xff0d4938); String text='بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'; String reciter='مشاري العفاسي';
 final controller=TextEditingController(text:'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
 @override void initState(){super.initState();reciter=arabicReciters.firstWhere((r)=>r.id==widget.store.reciterId,orElse:()=>arabicReciters.first).name;}
 @override void dispose(){controller.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('استوديو تصميم الآيات')),body:ListView(padding:const EdgeInsets.all(16),children:[
  const Text('معاينة التصميم قبل التصدير',style:TextStyle(color:Colors.grey,fontWeight:FontWeight.bold)),
  const SizedBox(height:12),
  AspectRatio(aspectRatio:9/16,child:RepaintBoundary(key:previewKey,child:Container(constraints:const BoxConstraints(maxHeight:560),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[bg,bg.withOpacity(.72),const Color(0xff111b17)])),padding:const EdgeInsets.all(22),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
   const Icon(Icons.auto_awesome,color:Color(0xffd8b45a),size:32),const SizedBox(height:24),
   Text('سورة $surah • آية $verse',style:const TextStyle(color:Color(0xffe5c777),fontWeight:FontWeight.w600)),
   const SizedBox(height:18),Flexible(child:Text(text,textAlign:TextAlign.center,style:TextStyle(fontFamily:widget.store.fontFamily,fontSize:size,color:Colors.white,height:1.8))),
   const SizedBox(height:28),Text(reciter,style:const TextStyle(color:Colors.white70))
  ])))),
  const SizedBox(height:14),
  FilledButton.icon(onPressed:exporting?null:_exportPng,icon:const Icon(Icons.image),label:Text(exporting?'جارٍ تجهيز الصورة…':'تصدير التصميم كصورة PNG')),
  const SizedBox(height:8),
  FilledButton.icon(onPressed:exportingVideo?null:_exportMp4,icon:const Icon(Icons.movie_creation),label:Text(exportingVideo?'جارٍ إنشاء الفيديو…':'إنشاء فيديو MP4 مع التلاوة')),
  if(videoStatus.isNotEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(videoStatus,style:const TextStyle(color:Colors.grey))),
  const SizedBox(height:8),FilledButton.tonalIcon(onPressed:_loadSelectedVerse,icon:const Icon(Icons.auto_stories),label:const Text('جلب نص الآية المختارة من القرآن')),
  const SizedBox(height:8),
  TextField(controller:controller,maxLines:3,decoration:const InputDecoration(labelText:'نص الآية للمعاينة',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>text=v)),
  const SizedBox(height:8),Row(children:[const Text('السورة'),Expanded(child:Slider(min:1,max:114,divisions:113,value:surah.toDouble(),label:'$surah',onChanged:(v)=>setState(()=>surah=v.round())))]),
  Row(children:[const Text('رقم الآية'),Expanded(child:Slider(min:1,max:286,divisions:285,value:verse.toDouble(),label:'$verse',onChanged:(v)=>setState(()=>verse=v.round())))]),
  Row(children:[const Text('حجم الخط'),Expanded(child:Slider(min:18,max:40,value:size,onChanged:(v)=>setState(()=>size=v)))]),
  Wrap(spacing:10,children:[_color('أخضر',const Color(0xff0d4938)),_color('كحلي',const Color(0xff182747)),_color('داكن',const Color(0xff242424)),_color('خمري',const Color(0xff582d32))]),
  const SizedBox(height:8),DropdownButtonFormField<String>(value:widget.store.reciterId,decoration:const InputDecoration(labelText:'قارئ التلاوة للفيديو'),items:arabicReciters.map((r)=>DropdownMenuItem<String>(value:r.id,child:Text('${r.name} — ${r.description}',overflow:TextOverflow.ellipsis))).toList(),onChanged:(id)async{if(id==null)return;await widget.store.setReciter(id);if(mounted)setState(()=>reciter=arabicReciters.firstWhere((r)=>r.id==id,orElse:()=>arabicReciters.first).name);}),
  const SizedBox(height:12),const Text('الفيديو الناتج يعرض التصميم الثابت مع تلاوة الآية المحددة. تأكد من حقوق الصوت والخط قبل النشر.',style:TextStyle(color:Colors.grey))
 ])));
 Future<void> _loadSelectedVerse() async {
  try {
   final verses=await widget.quran.verses(surah);
   final selected=verses.firstWhere((v)=>v.number==verse,orElse:()=>verses.first);
   final surahs=await widget.quran.surahs();
   final surahName=surahs.firstWhere((s)=>s.number==surah).name;
   if(!mounted)return;
   setState(()=>{verse=selected.number,text=selected.text,controller.text=selected.text,reciter=surahName});
  } catch (_) {
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر جلب الآية. تحقق من الإنترنت أو افتح السورة مرة أولى.')));
  }
 }

 Future<File> _capturePreviewPng() async {
   await WidgetsBinding.instance.endOfFrame;
   final boundary = previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
   if (boundary == null) throw Exception('preview not ready');
   final image = await boundary.toImage(pixelRatio: 3);
   try {
     final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
     if (byteData == null) throw Exception('PNG encoding failed');
     final dir = await getApplicationDocumentsDirectory();
     final file = File('${dir.path}/fakhri_quran_design_${DateTime.now().millisecondsSinceEpoch}.png');
     await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
     return file;
   } finally { image.dispose(); }
 }
 Future<void> _exportPng() async {
  setState(() => exporting = true);
  try {
   final file = await _capturePreviewPng();
   await Share.shareXFiles([XFile(file.path)], text: 'تصميم آية من فخري قرآن');
  } catch (_) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تصدير التصميم. جرّب مرة أخرى.')));
  } finally { if (mounted) setState(() => exporting = false); }
 }
 Future<void> _exportMp4() async {
  setState(() { exportingVideo = true; videoStatus = 'جارٍ تجهيز التصميم والصوت…'; });
  File? audioFile;
  try {
   final quranVerses = await widget.quran.verses(surah);
   final safeVerse = verse.clamp(1, quranVerses.length).toInt();
   final png = await _capturePreviewPng();
   final reciterId = widget.store.reciterId;
   final reciter = arabicReciters.firstWhere((r) => r.id == reciterId, orElse: () => arabicReciters.first);
   final response = await http.get(Uri.parse(reciter.verseUrl(surah, safeVerse))).timeout(const Duration(seconds: 40));
   if (response.statusCode != 200 || response.bodyBytes.isEmpty) throw Exception('Audio unavailable');
   final dir = await getApplicationDocumentsDirectory();
   audioFile = File('${dir.path}/fakhri_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
   await audioFile.writeAsBytes(response.bodyBytes, flush: true);
   final output = '${dir.path}/fakhri_quran_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
   String quote(String path) => '"${path.replaceAll('"', '\\"')}"';
   final command = '-y -loop 1 -framerate 30 -i ${quote(png.path)} -i ${quote(audioFile.path)} '
       '-vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,format=yuv420p" '
       '-c:v libx264 -preset ultrafast -tune stillimage -c:a aac -b:a 128k -shortest -movflags +faststart ${quote(output)}';
   if (mounted) setState(() => videoStatus = 'جارٍ ترميز الفيديو؛ قد يستغرق ذلك بعض الوقت…');
   final session = await FFmpegKit.execute(command);
   final returnCode = await session.getReturnCode();
   if (!ReturnCode.isSuccess(returnCode)) {
     final logs = await session.getOutput();
     throw Exception(logs ?? 'FFmpeg failed');
   }
   final video = File(output);
   if (!await video.exists() || await video.length() < 10000) throw Exception('Output video is empty');
   await Share.shareXFiles([XFile(video.path)], text: 'فيديو آية من فخري قرآن');
   if (mounted) setState(() => videoStatus = 'تم إنشاء الفيديو ومشاركته.');
  } catch (e) {
   if (mounted) setState(() => videoStatus = 'فشل إنشاء الفيديو: تحقق من الإنترنت ومصدر الصوت ثم أعد المحاولة.');
  } finally {
   try { if (audioFile != null && await audioFile.exists()) await audioFile.delete(); } catch (_) {}
   if (mounted) setState(() => exportingVideo = false);
  }
 }

 Widget _color(String label,Color c)=>ChoiceChip(label:Text(label),selected:bg==c,onSelected:(_)=>setState(()=>bg=c));
}

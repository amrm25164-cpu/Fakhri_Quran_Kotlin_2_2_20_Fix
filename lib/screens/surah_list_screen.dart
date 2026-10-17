import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/app_store.dart';
import '../services/quran_service.dart';
import 'reader_screen.dart';
import 'global_search_screen.dart';

class SurahListScreen extends StatefulWidget {
 const SurahListScreen({super.key,required this.store,required this.quran,this.favoritesOnly=false});
 final AppStore store; final QuranService quran; final bool favoritesOnly;
 @override State<SurahListScreen> createState()=>_SurahListScreenState();
}
class _SurahListScreenState extends State<SurahListScreen>{
 String query='';
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Column(children:[
  Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:Row(children:[Expanded(child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن سورة',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>query=v))),const SizedBox(width:8),IconButton.filled(tooltip:'البحث في القرآن كاملًا',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>GlobalSearchScreen(store:widget.store,quran:widget.quran))),icon:const Icon(Icons.manage_search))])),
  Expanded(child:FutureBuilder<List<Surah>>(future:widget.quran.surahs(),builder:(context,snap){
   if(snap.hasError)return _error(snap.error.toString());
   if(!snap.hasData)return const Center(child:CircularProgressIndicator());
   final list=snap.data!.where((s)=>(s.name.contains(query)||s.englishName.toLowerCase().contains(query.toLowerCase()))&&(!widget.favoritesOnly||widget.store.favorites.contains('${s.number}'))).toList();
   if(list.isEmpty)return const Center(child:Text('لا توجد نتائج'));
   return ListView.builder(itemCount:list.length,itemBuilder:(context,i){final s=list[i];return ListTile(leading:CircleAvatar(child:Text('${s.number}')),title:Text(s.name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w600)),subtitle:Text('${s.englishName} • ${s.ayahCount} آية'),trailing:IconButton(icon:Icon(widget.store.favorites.contains('${s.number}')?Icons.favorite:Icons.favorite_border,color:Colors.amber),onPressed:()=>widget.store.toggleFavorite(s.number)),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReaderScreen(surahNumber:s.number,store:widget.store,quran:widget.quran))));});
  }))
 ]));
 Widget _error(String e)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('تعذر تحميل السور. تحقق من الإنترنت ثم أعد المحاولة.'),const SizedBox(height:8),TextButton(onPressed:()=>setState((){}),child:const Text('إعادة المحاولة')),Text(e,style:const TextStyle(fontSize:10,color:Colors.grey))])));
}

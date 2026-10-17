import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/app_store.dart';
import '../services/quran_service.dart';
import 'reader_screen.dart';
import 'studio_screen.dart';
import 'tools_screen.dart';
import 'surah_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.quran});
  final AppStore store; final QuranService quran;
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int tab=0;
  @override Widget build(BuildContext context) {
    final pages = [
      _dashboard(), SurahListScreen(store: widget.store, quran: widget.quran),
      StudioScreen(store: widget.store, quran: widget.quran),
      ToolsScreen(store: widget.store, quran: widget.quran),
    ];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: IndexedStack(index:tab, children:pages)),
      bottomNavigationBar: NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations: const [
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.menu_book_outlined),selectedIcon:Icon(Icons.menu_book),label:'القرآن'),
        NavigationDestination(icon:Icon(Icons.movie_creation_outlined),selectedIcon:Icon(Icons.movie_creation),label:'استوديو'),
        NavigationDestination(icon:Icon(Icons.more_horiz),label:'أدوات'),
      ]),
    ));
  }
  Widget _dashboard()=>ListView(padding:const EdgeInsets.all(20),children:[
    Row(children:[const Icon(Icons.mosque,size:38,color:Color(0xffc9a44c)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('فخري قرآن',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold)),Text('رفيقك في التلاوة والتدبر') ])),IconButton(onPressed:widget.store.toggleTheme,icon:Icon(widget.store.darkMode?Icons.light_mode:Icons.dark_mode))]),
    const SizedBox(height:22),
    Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[Color(0xff0c4535),Color(0xff24755a)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w600)),
      const SizedBox(height:8),const Text('تابع رحلتك مع كتاب الله',style:TextStyle(color:Colors.white70)),
      const SizedBox(height:18),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReaderScreen(surahNumber:widget.store.lastSurah,store:widget.store,quran:widget.quran))),icon:const Icon(Icons.play_arrow),label:const Text('متابعة القراءة'))
    ])),
    const SizedBox(height:20),const Text('ابدأ رحلتك',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    const SizedBox(height:10),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.25,children:[
      _tile(Icons.menu_book,'تصفح السور','114 سورة',()=>setState(()=>tab=1)),
      _tile(Icons.movie,'تصميم آيات','معاينة مرئية',()=>setState(()=>tab=2)),
      _tile(Icons.favorite,'المفضلة','السور المحفوظة',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SurahListScreen(store:widget.store,quran:widget.quran,favoritesOnly:true)))),
      _tile(Icons.auto_awesome,'التسبيح والأذكار','عداد محفوظ',()=>setState(()=>tab=3)),
    ]),
    const SizedBox(height:12),const Text('مصدر النص القرآني: Quran Uthmani API — AlQuran Cloud. يتطلب اتصال الإنترنت عند أول تحميل للسورة.',style:TextStyle(fontSize:12,color:Colors.grey))
  ]);
  Widget _tile(IconData icon,String title,String subtitle,VoidCallback onTap)=>Card(child:InkWell(borderRadius:BorderRadius.circular(16),onTap:onTap,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:const Color(0xffc9a44c),size:28),const SizedBox(height:8),Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),Text(subtitle,style:const TextStyle(color:Colors.grey,fontSize:12))]))));
}

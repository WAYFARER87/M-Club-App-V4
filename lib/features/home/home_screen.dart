import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../mclub/mclub_screen.dart';
import '../uae_unlocked/uae_screen.dart';
import '../radio/radio_screen.dart';
import '../news/news_screen.dart';
import '../auth/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _primary = Color(0xFF182857);

  final _pages = const [
    MClubScreen(),
    UAEUnlockedScreen(),
    RadioScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,                 // компактная шапка
        automaticallyImplyLeading: false,  // без пустой «назад»-кнопки
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: SvgPicture.asset(
          'assets/images/mclub_logo.svg',
          height: 60,
          fit: BoxFit.contain,
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,       // белый фон
        selectedItemColor: _primary,          // активные — синие
        unselectedItemColor: Colors.grey,     // неактивные — серые
        type: BottomNavigationBarType.fixed,  // все подписи видны
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.tag),
            label: 'М-Клуб',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.map),
            label: 'Рекомендации',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.radio),
            label: 'Радио',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.newspaper),
            label: 'Новости',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

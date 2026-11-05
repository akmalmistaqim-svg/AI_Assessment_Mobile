import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'announcements_page.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

/// Halaman induk penampung navigasi bawah dengan 4 tab tujuan.
/// Menggunakan IndexedStack untuk mempertahankan status gulir dan halaman antar-tab.
class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  static const List<Widget> _pages = [
    HomePage(),
    AnnouncementsPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final currentIndex = appState.currentTabIndex;
    final unreadCount = appState.unreadNotificationCount;

    return PopScope(
      // Jika tidak di tab Beranda (index 0), tombol kembali membawa pengguna kembali ke Beranda
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          appState.setTabIndex(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => appState.setTabIndex(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.navyPrimary,
          unselectedItemColor: AppTheme.textMuted,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Informasi',
            ),
            BottomNavigationBarItem(
              icon: unreadCount > 0
                  ? Badge(
                      label: Text('$unreadCount'),
                      backgroundColor: AppTheme.skyBlue,
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              activeIcon: unreadCount > 0
                  ? Badge(
                      label: Text('$unreadCount'),
                      backgroundColor: AppTheme.skyBlue,
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
              label: 'Notifikasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

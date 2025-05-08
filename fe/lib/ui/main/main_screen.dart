import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../journal/journal_page.dart';
import '../plans/plans_page.dart';
import '../profile/profile_page.dart';

/// MainScreen holds bottom navigation with a center FAB and switches between feature pages
/// kèm hiệu ứng chuyển màn AnimatedSwitcher
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  /// 0: Home, 1: Journal, 2: Plans, 3: Profile
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    JournalPage(),
    PlansPage(),
    ProfilePage(),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          // Kết hợp Fade + Slide animation
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          // mỗi màn phải có Key để AnimatedSwitcher nhận diện
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                icon: Icons.home,
                label: 'Trang chủ',
                index: 0,
                isActive: _currentIndex == 0,
                onTap: () => _onTabSelected(0),
                activeColor: primary,
              ),
              _buildTabItem(
                icon: Icons.book,
                label: 'Nhật ký',
                index: 1,
                isActive: _currentIndex == 1,
                onTap: () => _onTabSelected(1),
                activeColor: primary,
              ),
              // Spacer for FAB
              const SizedBox(width: 48),
              _buildTabItem(
                icon: Icons.list_alt,
                label: 'Thực đơn',
                index: 2,
                isActive: _currentIndex == 2,
                onTap: () => _onTabSelected(2),
                activeColor: primary,
              ),
              _buildTabItem(
                icon: Icons.person,
                label: 'Tài khoản',
                index: 3,
                isActive: _currentIndex == 3,
                onTap: () => _onTabSelected(3),
                activeColor: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

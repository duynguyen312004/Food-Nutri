import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/food/my_food_cubit.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/recent_log/recent_meals_cubit.dart';
import '../home/home_page.dart';
import '../journal/journal_page.dart';
import '../plans/plans_page.dart';
import '../profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
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
  void initState() {
    super.initState();

    final today = DateTime.now();
    // Preload dữ liệu khi mở MainScreen lần đầu
    Future.microtask(() {
      context.read<MetricsCubit>().loadMetricsForDate(today);
      context.read<JournalCubit>().loadLogs(today);
      context.read<RecentMealsCubit>().loadRecentMeals(today);
      context.read<MyFoodsCubit>().loadMyFoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: RawMaterialButton(
          shape: const CircleBorder(),
          onPressed: () {},
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
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
              const SizedBox(width: 48), // Khoảng trống cho FAB
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

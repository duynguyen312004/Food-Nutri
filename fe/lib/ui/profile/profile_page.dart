import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrition_app/ui/profile/weight_stats_page.dart';
import 'package:nutrition_app/ui/welcome/welcome_page.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/metrics/metrics_state.dart';
import '../../blocs/user/user_data_cubit.dart';
import '../../blocs/user/user_data_state.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_state_cleaner.dart';
import '../../utils/dialog_helper.dart';
import 'edit_profile_page.dart';
import 'goal_page.dart';

/// Trang hiển thị thông tin cá nhân và các chức năng quản lý tài khoản
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Màu nền tối phù hợp dark mode
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<UserDataCubit, UserDataState>(
        builder: (context, state) {
          if (state is UserDataLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserDataLoaded) {
            final user = state.profile;
            final metricsState = context.watch<MetricsCubit>().state;
            final metrics =
                metricsState is MetricsLoaded ? metricsState.metrics : null;
            final fullName = [
              user.lastName?.trim(),
              user.firstName?.trim(),
            ].where((e) => e != null && e.isNotEmpty).join(' ');

            final nameToShow = fullName.isNotEmpty
                ? fullName
                : (user.displayName ?? 'Chưa đặt tên');

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildUserHeader(
                    context, nameToShow, user.photoUrl, user, metrics),
                const SizedBox(height: 16),
                _buildWeightGoalCard(user.startingWeight, user.targetWeight),
                const SizedBox(height: 24),
                _buildSection('Chức năng', [
                  _buildNavTile('Theo dõi cân nặng', Icons.monitor_weight,
                      onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WeightStatsPage(targetWeight: user.targetWeight),
                      ),
                    );
                  }),
                  _buildNavTile('Mục tiêu', Icons.flag, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoalPage(
                          startingWeight: user.startingWeight,
                          targetWeight: user.targetWeight,
                          goal: state.goal,
                        ),
                      ),
                    );
                  }),
                  _buildNavTile('Báo cáo dinh dưỡng', Icons.pie_chart,
                      onTap: () {}),
                  _buildNavTile('Kết nối thiết bị', Icons.sync, onTap: () {}),
                ]),
                const SizedBox(height: 24),
                _buildSection('Tài khoản', [
                  _buildNavTile('Xoá dữ liệu và tài khoản', Icons.delete,
                      onTap: () async {
                    final confirm = await confirmDialog(
                      context: context,
                      title: 'Xác nhận xoá tài khoản',
                      message:
                          'Bạn có chắc chắn muốn xoá toàn bộ dữ liệu và tài khoản? Hành động này không thể hoàn tác.',
                    );

                    if (!context.mounted || !confirm) return;

                    // Hiển thị loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await UserService().deleteAccount();
                      final user = FirebaseAuth.instance.currentUser;
                      await user?.delete();
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.of(context).pop(); // đóng loading
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WelcomePage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // đóng loading nếu có lỗi
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Xoá tài khoản thất bại: $e')),
                        );
                      }
                    }
                  }),
                  _buildNavTile('Đăng xuất', Icons.logout, onTap: () async {
                    final shouldLogout = await confirmDialog(
                      context: context,
                      title: 'Xác nhận đăng xuất',
                      message: 'Bạn có chắc chắn muốn đăng xuất?',
                    );

                    if (!context.mounted || shouldLogout != true) return;

                    // Hiển thị loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    AppStateCleaner.clearAll(context);
                    await AuthService().signOut();

                    if (context.mounted) {
                      Navigator.of(context).pop(); // đóng loading
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomePage()),
                        (route) => false,
                      );
                    }
                  }),
                ]),
              ],
            );
          } else if (state is UserDataError) {
            return Center(
                child: Text('Lỗi: ${state.message}',
                    style: const TextStyle(color: Colors.white)));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, String? name, String? avatarUrl,
      dynamic profile, dynamic metrics) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EditProfilePage(profile: profile, metrics: metrics),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF252836),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/avatar_placeholder.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Chưa đặt tên',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                const Text('Hồ sơ cá nhân',
                    style: TextStyle(color: Colors.white60)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightGoalCard(double? start, double? target) {
    return Card(
      color: const Color(0xFF252836),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cân nặng bắt đầu',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 4),
                Text('${start?.toStringAsFixed(1) ?? '--'} Kg',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Cân nặng mục tiêu',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 4),
                Text('${target?.toStringAsFixed(1) ?? '--'} Kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...tiles,
      ],
    );
  }
}

// Màn hình chào mừng, cho phép người dùng đăng nhập bằng Google, Facebook, Apple
// Sau khi đăng nhập thành công, kiểm tra hồ sơ người dùng để điều hướng đến MainScreen hoặc ProfileSetupScreen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/blocs/recent_log/recent_meals_cubit.dart';
import 'package:nutrition_app/ui/main/main_screen.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/user/user_data_cubit.dart';
import '../../blocs/user/user_data_state.dart';
import '../setup_profiles.dart/setup_profiles_screen.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  /// Hàm này dùng để điều hướng sau khi đăng nhập thành công
  /// - Nếu người dùng đã có đầy đủ thông tin (firstName, lastName), chuyển sang MainScreen
  /// - Nếu chưa có hồ sơ, chuyển sang màn hình SetupProfile
  Future<void> _navigateAfterAuth(BuildContext context) async {
    final state = context.read<UserDataCubit>().state;

    if (state is UserDataLoaded) {
      final profile = state.profile;
      final hasProfile = profile.firstName != null && profile.lastName != null;

      if (!context.mounted) return;

      if (hasProfile) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      }
    } else {
      // Trường hợp bất thường nếu chưa load được dữ liệu người dùng
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể tải thông tin người dùng.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          /// Listener sẽ được gọi mỗi khi `AuthState` thay đổi
          listener: (context, state) async {
            if (state is AuthAuthenticated) {
              // Khi đăng nhập thành công, đồng thời preload dữ liệu liên quan
              final today = DateTime.now();
              await Future.wait([
                context
                    .read<UserDataCubit>()
                    .loadUserData(), // Hồ sơ người dùng
                context
                    .read<MetricsCubit>()
                    .loadMetricsForDate(today), // Dữ liệu calories, macros
                context
                    .read<JournalCubit>()
                    .loadLogs(today), // Nhật ký ăn uống, tập luyện, uống nước
                context
                    .read<RecentMealsCubit>()
                    .loadRecentMeals(today), // Gợi ý món ăn gần đây
              ]);
              if (!context.mounted) return;
              await _navigateAfterAuth(context); // Chuyển trang sau khi xong
            } else if (state is AuthError) {
              // Nếu xảy ra lỗi khi đăng nhập, hiển thị snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },

          /// Builder để hiển thị giao diện login hoặc loading indicator
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Stack(
              children: [
                // Giao diện nội dung chính: giới thiệu app + nút đăng nhập
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Image.asset('assets/images/logo.png',
                          width: 100, height: 100),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Kiểm soát chế độ dinh dưỡng của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Cùng một kế hoạch ăn uống cá nhân hóa giúp bạn đạt được mục tiêu, tăng cường năng lượng và thay đổi lối sống.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Trợ lý dinh dưỡng của riêng bạn',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 32),

                      // Các nút đăng nhập bằng mạng xã hội
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildSocialButton(
                              context,
                              asset: 'assets/icons/google.png',
                              label: 'Đăng nhập với Google',
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(AuthSignInWithGoogle()),
                            ),
                            const SizedBox(height: 16),
                            _buildSocialButton(
                              context,
                              asset: 'assets/icons/facebook.png',
                              label: 'Đăng nhập với Facebook',
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(AuthSignInWithFacebook()),
                            ),
                            const SizedBox(height: 16),
                            _buildSocialButton(
                              context,
                              asset: 'assets/icons/apple.png',
                              label: 'Đăng nhập với Apple',
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(AuthSignInWithApple()),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Hiển thị loading overlay khi đang xử lý đăng nhập
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Widget tạo nút đăng nhập đẹp mắt theo từng mạng xã hội
  Widget _buildSocialButton(
    BuildContext context, {
    required String asset,
    required String label,
    required VoidCallback onPressed,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: primary, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

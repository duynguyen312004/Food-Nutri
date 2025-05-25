import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/services/auth_service.dart';
import 'package:nutrition_app/ui/main/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../blocs/log/journal_cubit.dart';
import '../../blocs/metrics/metrics_cubit.dart';
import '../../blocs/recent_log/recent_meals_cubit.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

import '../onboarding/onboarding_screen1.dart';
import '../welcome/welcome_page.dart';

/// Màn hình splash hiển thị logo và xử lý logic điều hướng đầu app:
/// - Nếu chưa hoàn thành onboarding → Onboarding
/// - Nếu chưa đăng nhập → Welcome
/// - Nếu đã đăng nhập nhưng chưa setup hồ sơ → ProfileSetup
/// - Nếu đầy đủ → MainScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  /// Điều hướng sang một page mới với hiệu ứng fade
  void _navigateWithFade(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAppState();
      });
    });
  }

  /// Kiểm tra xem người dùng đã hoàn thành onboarding chưa
  Future<bool> _isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('kOnboardingCompleted') ?? false;
      debugPrint('✔️ Onboarding completed: $completed');
      return completed;
    } catch (e) {
      debugPrint('⚠️ SharedPreferences error: $e');
      return false;
    }
  }

  /// Xác định trạng thái app và điều hướng tương ứng
  Future<void> _checkAppState() async {
    final completed = await _isOnboardingCompleted();
    if (!mounted) return;

    if (!completed) {
      debugPrint('➡️ Chuyển tới Onboarding');
      _navigateWithFade(const OnboardingScreen1());
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('➡️ Chuyển tới WelcomePage vì chưa đăng nhập');
      _navigateWithFade(const WelcomePage());
      return;
    }

    try {
      final UserModel profile = await UserService().fetchProfile();
      final hasProfile = profile.firstName != null && profile.lastName != null;
      debugPrint(
          '👤 UserProfile loaded: ${profile.firstName} ${profile.lastName}');

      if (!mounted) return;

      if (!hasProfile) {
        debugPrint('📝 Thiếu hồ sơ. Thoát tài khoản và quay lại WelcomePage');
        await AuthService().signOut();
        _navigateWithFade(const WelcomePage());
        return;
      }
      final today = DateTime.now();
      context.read<MetricsCubit>().loadMetricsForDate(today);
      context.read<JournalCubit>().loadLogs(today);
      context.read<RecentMealsCubit>().loadRecentMeals(today);
      debugPrint('✅ Hồ sơ đầy đủ. Chuyển tới MainScreen');
      _navigateWithFade(const MainScreen());
    } catch (e) {
      debugPrint('❌ Lỗi lấy profile: $e');
      await AuthService().signOut();

      _navigateWithFade(const WelcomePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/logo.png',
                    width: 80, height: 80),
              ),
              const SizedBox(height: 10),
              const Text(
                'FOODNUTRI',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

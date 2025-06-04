import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../welcome/welcome_page.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  static const _horizontalPadding = 12.0;
  static const _buttonHeight = 50.0;
  static const _pageIndicatorHeight = 4.0;
  static const _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const _PageIndicator(currentIndex: 2),
                const SizedBox(height: 20),
                _SkipRow(onSkip: () => _completeAndNavigate(context)),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/onboarding.png',
                      width: MediaQuery.of(context).size.width * 0.9,
                      fit: BoxFit.contain,
                      opacity: const AlwaysStoppedAnimation(.9),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đặt mục tiêu, theo dõi tiến trình và hình thành thói quen lành mạnh suốt đời',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: _buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => _completeAndNavigate(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.lightGreenAccent,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                    ),
                    child: const Text('Bắt đầu'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeAndNavigate(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('kOnboardingCompleted', true);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WelcomePage(),
        ),
      );
    } catch (e) {
      debugPrint('Error saving onboarding state: \$e');
    }
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentIndex;
  const _PageIndicator({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: OnboardingScreen3._pageIndicatorHeight,
            decoration: BoxDecoration(
              color: i <= currentIndex ? Colors.lightGreenAccent : Colors.grey,
              borderRadius: BorderRadius.circular(56),
            ),
          ),
        );
      }),
    );
  }
}

class _SkipRow extends StatelessWidget {
  final VoidCallback onSkip;
  const _SkipRow({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 40,
          height: 40,
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(OnboardingScreen3._borderRadius),
            ),
            side: BorderSide(color: Colors.purple.withOpacity(.75)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
            'Bỏ qua',
            style: TextStyle(color: Colors.purple),
          ),
        ),
      ],
    );
  }
}

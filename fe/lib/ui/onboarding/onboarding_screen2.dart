import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../welcome/welcome_page.dart';
import 'onboarding_screen3.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  static const _horizontalPadding = 12.0;
  static const _buttonHeight = 50.0;
  static const _pageIndicatorHeight = 4.0;
  static const _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const _PageIndicator(currentIndex: 1),
              const SizedBox(height: 20),
              _SkipRow(onSkip: () => _completeAndNavigate(context)),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/onboarding.png',
                    width: 500,
                    height: 400,
                    opacity: const AlwaysStoppedAnimation(.8),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'onboarding2'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: _buttonHeight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black.withOpacity(.75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                      ),
                      child: Text('Back'.tr()),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    height: _buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen3(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.lightGreenAccent,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                      ),
                      child: Text('Next'.tr()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
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
      debugPrint('Error saving onboarding state: $e');
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
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          height: OnboardingScreen2._pageIndicatorHeight,
          width: 110,
          decoration: BoxDecoration(
            color: i <= currentIndex ? Colors.lightGreenAccent : Colors.grey,
            borderRadius: BorderRadius.circular(56),
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
                  BorderRadius.circular(OnboardingScreen2._borderRadius),
            ),
            side: BorderSide(color: Colors.purple.withOpacity(.75)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text('Skip'.tr()),
        ),
      ],
    );
  }
}

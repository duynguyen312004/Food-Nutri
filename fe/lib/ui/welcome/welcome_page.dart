// lib/ui/welcome/welcome_page.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/ui/main/main_screen.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/user_service.dart';
import '../setup_profiles.dart/setup_profiles_screen.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _navigateAfterAuth(BuildContext context) async {
    final profile = await UserService().fetchProfile();
    final hasProfile =
        profile['first_name'] != null && profile['last_name'] != null;
    if (!context.mounted) return;
    if (hasProfile) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _navigateAfterAuth(context);
                });
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png',
                      width: 100, height: 100),
                  const SizedBox(height: 16),
                  Text(
                    'welcome'.tr(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'welcome_message'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isLoading)
                    CircularProgressIndicator(color: primary)
                  else ...[
                    _buildSocialButton(
                      context,
                      asset: 'assets/icons/google.png',
                      label: 'Login with Google',
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthSignInWithGoogle()),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialButton(
                      context,
                      asset: 'assets/icons/facebook.png',
                      label: 'Login with Facebook',
                      onPressed: () => context
                          .read<AuthBloc>()
                          .add(AuthSignInWithFacebook()),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialButton(
                      context,
                      asset: 'assets/icons/apple.png',
                      label: 'Login with Apple',
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthSignInWithApple()),
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required String asset,
    required String label,
    required VoidCallback onPressed,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: primary, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(asset, width: 28, height: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/ui/setup_profiles/loading_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:nutrition_app/ui/main/main_screen.dart';
import '../welcome/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoadingSetupScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const LoadingSetupScreen({super.key, required this.data});

  @override
  // ignore: library_private_types_in_public_api
  _LoadingSetupScreenState createState() => _LoadingSetupScreenState();
}

class _LoadingSetupScreenState extends State<LoadingSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doSetup();
    });
  }

  Future<void> _doSetup() async {
    try {
      // đảm bảo có user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Chưa login');
      // gọi API
      // sang HomePage
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      // nếu lỗi, đẩy về WelcomePage
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thiết lập thất bại: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = primary.withOpacity(0.3);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // hai vòng vòng quay
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation(secondary),
                ),
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),
              // Biểu tượng chính giữa
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.bar_chart, color: Colors.white, size: 40),
              ),
              Positioned(
                bottom: 40,
                child: Column(
                  children: [
                    Text(
                      'Đang chuẩn bị mục tiêu của bạn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng chờ trong giây lát…',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

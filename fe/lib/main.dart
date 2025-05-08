import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/blocs/auth/auth_bloc.dart';
import 'package:nutrition_app/blocs/metrics/metrics_cubit.dart';
import 'package:nutrition_app/firebase_options.dart';
import 'package:nutrition_app/services/auth_service.dart';

import 'blocs/user/user_data_cubit.dart';
import 'services/user_service.dart';
import 'ui/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();
  final authService = AuthService();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authService),
          ),
          BlocProvider(
            create: (context) => MetricsCubit(UserService()),
          ),
          BlocProvider(
            create: (context) => UserDataCubit(UserService())
              ..loadUserData(), // Fetch user data when the app starts
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Food Nutri',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9B51E0), // tim nhạt như mẫu
            secondary: Color(0xFFBB6BD9), // tím đậm cho accent
            background: Color(0xFF1E1E2F),
            surface: Color(0xFF2A2A3D),
            onPrimary: Colors.white,
            onSurface: Colors.white70,
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1E2F),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF2A2A3D),
            selectedItemColor: Color(0xFFBB6BD9),
            unselectedItemColor: Colors.white54,
          ),
          cardColor: const Color(0xFF2A2A3D),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            titleMedium: TextStyle(color: Colors.white70),
            bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF9B51E0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        home: const SplashScreen());
  }
}

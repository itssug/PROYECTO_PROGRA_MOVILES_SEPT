import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/main_app_shell.dart';
import 'screens/inicio/Principal_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final hasSession = await AuthService.init();
  
  runApp(MyApp(hasSession: hasSession));
}

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final bool hasSession;
  
  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'GlucoWatch',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: hasSession ? const MainAppShell() : const PrincipalScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainAppShell());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const PrincipalScreen());
          default:
            return null;
        }
      },
    );
  }
}

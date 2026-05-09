
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/inicio/principal_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home.dart';
import 'screens/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar AuthService
  final hasSession = await AuthService.init();
  
  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool hasSession;
  
  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlucoWatch',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
      ),
      // NO USAR 'home' Y 'routes' AL MISMO TIEMPO
      // Usamos initialRoute en lugar de home
      initialRoute: hasSession ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (context) => const PrincipalScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      // Manejar rutas no encontradas
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text(
                'Página no encontrada',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
// // ============================================================
// // ARCHIVO: lib/main.dart
// // ============================================================
// import 'package:flutter/material.dart';
// import 'services/auth_service.dart';
// import 'screens/home.dart';
// import 'screens/inicio/Principal_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/auth/register_screen.dart';
// import 'screens/app_colors.dart';
// import 'screens/chat_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   final hasSession = await AuthService.init();
  
//   runApp(MyApp(hasSession: hasSession));
// }

// class MyApp extends StatelessWidget {
//   final bool hasSession;
  
//   const MyApp({super.key, required this.hasSession});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'GlucoWatch',
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: AppColors.bg,
//       ),
//       home: hasSession ? const HomeScreen() : const PrincipalScreen(),
//       onGenerateRoute: (settings) {
//         switch (settings.name) {
//           case '/login':
//             return MaterialPageRoute(builder: (_) => const LoginScreen());
//           case '/register':
//             return MaterialPageRoute(builder: (_) => const RegisterScreen());
//           case '/home':
//             return MaterialPageRoute(builder: (_) => const HomeScreen());
//           case '/onboarding':
//             return MaterialPageRoute(builder: (_) => const PrincipalScreen());
//           case '/chat':
//             return MaterialPageRoute(builder: (_) => const ChatScreen());
//           default:
//             return null;
//         }
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
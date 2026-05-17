import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/date_symbol_data_local.dart'; // For locale initialization
import 'package:berwehsan/login.dart'; // Ensure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAeCWm39LL0bWVanOnz-t9sGQ7xQrW6GWA",
      authDomain: "berwehsan-78e0d.firebaseapp.com",
      databaseURL: "https://berwehsan-78e0d-default-rtdb.firebaseio.com",
      projectId: "berwehsan-78e0d",
      storageBucket: "berwehsan-78e0d.firebasestorage.app",
      messagingSenderId: "443736486269",
      appId: "1:443736486269:web:26b60801451dc1497edc14",
      measurementId: "G-062S5X7BKD",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berwehsan Web App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        primaryColor: const Color(0xFF1B5E37),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E37),
          primary: const Color(0xFF1B5E37),
          secondary: const Color(0xFF2E7D32),
          surface: const Color(0xFFFFFFFF),
          tertiary: const Color(0xFFB87333),
          onPrimary: const Color(0xFFFFFFFF),
          onSecondary: const Color(0xFFFFFFFF),
        ).copyWith(
          primaryContainer: const Color(0xFF0A2B1D),
          onPrimaryContainer: const Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E37),
          foregroundColor: Color(0xFFFFFFFF),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E37),
            foregroundColor: const Color(0xFFFFFFFF),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFB87333),
          foregroundColor: Color(0xFFFFFFFF),
        ),
      ),
      builder: EasyLoading.init(),
      home: const LoginScreenWeb(),
    );
  }
}

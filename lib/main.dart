import 'package:berwehsan/cases.dart';
import 'package:berwehsan/chests.dart';
import 'package:berwehsan/insertCase.dart';
import 'package:berwehsan/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with web-specific configuration
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
        primarySwatch: Colors.blue,
      ),
      builder: EasyLoading.init(), // تهيئة EasyLoading

      home:  CasesPage(), // Default home page set to ChestsPage
    );
  }
}

import 'package:berwehsan/admin/chests.dart'; // Admin page
import 'package:berwehsan/moderator/chests.dart'; // Moderator page
import 'package:berwehsan/user/chests.dart'; // User page
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreenWeb extends StatelessWidget {
  const LoginScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    void login() async {
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();

      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال اسم المستخدم وكلمة المرور'),
          ),
        );
        return;
      }

      try {
        // Query Firestore for the user
        final querySnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .where('FullName', isEqualTo: username)
            .where('Password', isEqualTo: password)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final user = querySnapshot.docs.first.data();
          final fullName = user['FullName'];
          final role = user['Role'];

          if (role == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('مرحبًا بك، المدير $fullName!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminChestsPage()),
            );
          } else if (role == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('مرحبًا بك، المشرف $fullName!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChestsPageModerator()),
            );
          } else if (role == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('مرحبًا بك، المستخدم $fullName!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserChestsPage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('دور المستخدم غير صالح')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('اسم المستخدم أو كلمة المرور غير صحيحة')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display Image
                  Image.asset(
                    'images/image.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'جمعية البر والاحسان',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Login Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Username Field
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم المستخدم',
                                prefixIcon: Icon(Icons.person),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Password Field
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Login Button
                          Center(
                            child: ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

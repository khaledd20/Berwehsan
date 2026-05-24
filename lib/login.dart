import 'package:berwehsan/screens/Feeding.dart';
import 'package:berwehsan/screens/IncomePage.dart';
import 'package:berwehsan/screens/cases.dart';
import 'package:berwehsan/core/user_session.dart';
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
          final fullName = user['FullName'] as String? ?? '';
          final role = user['Role'] as int? ?? 0;

          // Populate the global UserSession singleton
          final session = UserSession();
          session.role = role;
          session.fullName = fullName;

          Widget nextScreen;
          // Roles 1 (User), 2 (Moderator), 3 (Admin) → go to Cases
          if (role == 3 || role == 2 || role == 1) {
            nextScreen = const CasesPage();
          } else if (role == 4 || role == 7) {
            // Secretary / Secretary Moderator → go to Feeding
            nextScreen = const FeedingPage();
          } else if (role == 5 || role == 6) {
            // Accounting / Accounting Moderator → go to IncomePage
            nextScreen = const IncomePage();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('دور المستخدم غير صالح')),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('مرحبًا بك، $fullName!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => nextScreen),
          );
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
        body: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A2B1D), // Dark Slate Green
                    Color(0xFF1B5E37), // Deep Forest Green
                  ],
                ),
              ),
            ),
            // Subtle Background Pattern (Optional, but adding a "frame" feel)
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/image.png'),
                      repeat: ImageRepeat.repeat,
                      scale: 4,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Frame
                      Container(
                        // Adjust height/width ratio if you want it more rectangular
                        width: 150,
                        height: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          // Changed to rounded rectangle
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFB87333), // Golden Ochre
                            width: 2,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/image.png',
                          // BoxFit.contain is best here to keep the logo's proportions
                          // without cutting off the text.
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title with shadow
                      Text(
                        'جمعية البر والاحسان',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Login Form with Frame
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFB87333).withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 40.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E37),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  // Username Field
                                  TextField(
                                    controller: usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'اسم المستخدم',
                                      prefixIcon: const Icon(Icons.person,
                                          color: Color(0xFF2E7D32)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF2E7D32), width: 2),
                                      ),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 20),
                                  // Password Field
                                  TextField(
                                    controller: passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'كلمة المرور',
                                      prefixIcon: const Icon(Icons.lock,
                                          color: Color(0xFF2E7D32)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF2E7D32), width: 2),
                                      ),
                                    ),
                                    obscureText: true,
                                    textAlign: TextAlign.right,
                                    onSubmitted: (_) => login(),
                                  ),
                                  const SizedBox(height: 32),
                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1B5E37),
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'دخول النظام',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Footer info or copyright
                      Text(
                        '© 2024 جميع الحقوق محفوظة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

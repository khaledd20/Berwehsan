import 'package:berwehsan/admin/chests.dart';
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
          const SnackBar(content: Text('Please enter both username and password')),
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, $fullName!')),
          );

          // Navigate to the Chests Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChestsPage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Web Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

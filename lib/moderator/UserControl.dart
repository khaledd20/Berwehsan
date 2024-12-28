import 'package:berwehsan/widgets/admin_drawer.dart';
import 'package:berwehsan/widgets/moderator_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserControlPage extends StatefulWidget {
  const UserControlPage({super.key});

  @override
  State<UserControlPage> createState() => _UserControlPageState();
}

class _UserControlPageState extends State<UserControlPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isEdit = false; // To check if it's edit mode
  String? editingUserId; // Holds the document ID for editing
  int? selectedRoleId; // Holds the selected role ID

  final List<Map<String, dynamic>> roles = [
    {'id': 5, 'name': 'محاسب'},
    {'id': 4, 'name': 'سكرتير'},    
    {'id': 1, 'name': 'مستخدم'},
  ];
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set Right-to-Left alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          centerTitle: true,
        ),
        drawer: ModeratorDrawer(), // Add the AdminDrawer here
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Form Section
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الاسم الكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // Role Dropdown
                    _buildRoleDropdown(),
                    const SizedBox(height: 20),
                    // Add/Edit Button
                    ElevatedButton(
                      onPressed: () {
                        if (isEdit) {
                          _editUser();
                        } else {
                          _addUser();
                        }
                      },
                      child: Text(isEdit ? 'تعديل المستخدم' : 'إضافة المستخدم'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // List of Users
              Expanded(
                child: _buildUserList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Role Dropdown
  Widget _buildRoleDropdown() {
  if (!roles.any((role) => role['id'] == selectedRoleId)) {
    // Reset selectedRoleId if it's not in the current list of roles
    selectedRoleId = null;
  }

  return DropdownButtonFormField<int>(
    value: selectedRoleId,
    items: roles.map((role) {
      return DropdownMenuItem<int>(
        value: role['id'],
        child: Text(role['name']),
      );
    }).toList(),
    decoration: const InputDecoration(
      labelText: 'الدور',
      border: OutlineInputBorder(),
    ),
    onChanged: (value) {
      setState(() {
        selectedRoleId = value;
      });
    },
    validator: (value) => value == null ? 'الرجاء اختيار الدور' : null,
  );
}


  // Add User to Firestore
  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('admins').add({
          'FullName': _fullNameController.text,
          'email': _emailController.text,
          'Password': _passwordController.text, // Store securely in real apps
          'Role': selectedRoleId, // Save selected role ID
          'created_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المستخدم بنجاح')),
        );
        _clearForm();
      } catch (error) {
        print('Error adding user: $error');
      }
    }
  }

  // Edit User in Firestore
  Future<void> _editUser() async {
    if (_formKey.currentState!.validate() && editingUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(editingUserId)
            .update({
          'FullName': _fullNameController.text,
          'email': _emailController.text,
          'Password': _passwordController.text, // Store securely in real apps
          'Role': selectedRoleId, // Save selected role ID
          'updated_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل المستخدم بنجاح')),
        );
        setState(() {
          isEdit = false;
          editingUserId = null;
        });
        _clearForm();
      } catch (error) {
        print('Error editing user: $error');
      }
    }
  }

  // Delete User from Firestore
  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
      );
    } catch (error) {
      print('Error deleting user: $error');
    }
  }

  // Build User List
  Widget _buildUserList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('admins').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text(
            'لا يوجد مستخدمون',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      // Filter users with valid roles
      final users = snapshot.data!.docs.where((doc) {
        final user = doc.data() as Map<String, dynamic>;
        return roles.any((role) => role['id'] == user['Role']);
      }).toList();

      if (users.isEmpty) {
        return const Center(
          child: Text(
            'لا يوجد مستخدمون بالأدوار المحددة',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index].data() as Map<String, dynamic>;
          final userId = users[index].id;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(user['FullName'] ?? 'غير معروف'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? 'بريد غير معروف'),
                  Text(
                    'الدور: ${roles.firstWhere(
                      (role) => role['id'] == user['Role'],
                      orElse: () => {'name': 'غير معروف'}, // Fallback for missing roles
                    )['name']}',
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        isEdit = true;
                        editingUserId = userId;
                        _fullNameController.text = user['FullName'] ?? '';
                        _emailController.text = user['email'] ?? '';
                        _passwordController.text = user['Password'] ?? '';
                        selectedRoleId = roles.any((role) => role['id'] == user['Role'])
                            ? user['Role']
                            : null; // Reset if role is invalid
                      });
                    },
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteUser(userId);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  // Clear Form
  void _clearForm() {
    _fullNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    selectedRoleId = null;
  }
}

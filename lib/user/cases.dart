import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'caseProfile.dart';
import 'insertCase.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  _CasesPageState createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  String searchQuery = ''; // To hold the search query

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الحالات'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value; // Update the search query
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الرقم',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
        drawer: userDrawer(), // Add the drawer here
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cases')
              .orderBy('id')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا توجد بيانات', style: TextStyle(fontSize: 18)),
              );
            }

            final cases = snapshot.data!.docs;

            // Filter cases based on the search query
            final filteredCases = cases.where((doc) {
              final caseData = doc.data() as Map<String, dynamic>;
              final name = caseData['name']?.toString().toLowerCase() ?? '';
              final id = caseData['id']?.toString();

              // If search query is numeric, match ID exactly
              if (RegExp(r'^\d+$').hasMatch(searchQuery)) {
                return id == searchQuery;
              }

              // Otherwise, perform a partial match for the name
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return ListView.builder(
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final caseData =
                    filteredCases[index].data() as Map<String, dynamic>;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(caseData['name'] ?? 'غير معروف'),
                    subtitle:
                        Text('رقم الحالة: ${caseData['id'] ?? 'غير معروف'}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaseProfile(
                                caseId: int.parse(caseData['id'].toString())),
                          ),
                        );
                      },
                      child: const Text('عرض'),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InsertCase(),
              ),
            );
          },
          tooltip: 'إضافة حالة جديدة',
        ),
      ),
    );
  }
}

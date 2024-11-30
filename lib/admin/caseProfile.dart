import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CaseProfile extends StatelessWidget {
  final int caseId; // Ensure `caseId` is defined as an int

  const CaseProfile({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملف الحالة'),
          centerTitle: true,
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('cases')
              .where('id', isEqualTo: caseId) // Query by numeric ID
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا توجد بيانات لهذه الحالة', style: TextStyle(fontSize: 18)),
              );
            }

            final caseData = snapshot.data!.docs.first.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCaseDetailsSection(caseData),
                    const SizedBox(height: 16),
                    _buildQrCodeSection(caseData['id'].toString()), // Pass the `id` to generate QR code
                    const SizedBox(height: 16),
                    _buildChestDetailsSection(caseData['chest_ids'] ?? []),
                    const SizedBox(height: 16),
                    _buildSubDetailsSection(caseData['sub_ids'] ?? []),
                    const SizedBox(height: 16),
                    _buildFamilyDetailsSection(caseData['family_id']),
                    const SizedBox(height: 16),
                    _buildMonthlyPaymentsSection(caseData['id']), // Pass numeric `id` to payments section
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the case details section
  /// Build the case details section
/// Build the case details section
Widget _buildCaseDetailsSection(Map<String, dynamic> caseData) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Align content to the right
        children: [
          Align(
            alignment: Alignment.centerRight, // Align the title to the right
            child: const Text(
              'بيانات الحالة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.right, // Explicitly align text to the right
            ),
          ),
          const SizedBox(height: 8),
          ..._buildDetails(caseData),
        ],
      ),
    ),
  );
}


/// Helper method to generate detail rows with labels and values side by side
List<Widget> _buildDetails(Map<String, dynamic> caseData) {
  final details = [
    {'label': 'رقم الحالة:', 'value': caseData['id']?.toString() ?? 'غير معروف'},
    {'label': 'الاسم:', 'value': caseData['name'] ?? 'غير معروف'},
    {'label': 'الرقم القومي:', 'value': caseData['ID_Number']?.toString() ?? 'غير معروف'},
    {'label': 'رقم الهاتف:', 'value': caseData['number']?.toString() ?? 'غير معروف'},
    {'label': 'العنوان:', 'value': caseData['location'] ?? 'غير معروف'},
    {'label': 'الحالة الاجتماعية:', 'value': caseData['social_status'] ?? 'غير معروف'},
    {'label': 'الدخل:', 'value': caseData['in_come']?.toString() ?? 'غير معروف'},
    {'label': 'عدد أعضاء الأسرة:', 'value': caseData['family_count']?.toString() ?? 'غير معروف'},
    {'label': 'مقاس الملابس:', 'value': caseData['c_size'] ?? 'غير معروف'},
    {'label': 'مقاس جهاز العوسة:', 'value': caseData['S_size'] ?? 'غير معروف'},
    {'label': 'العمر:', 'value': caseData['age']?.toString() ?? 'غير معروف'},
    {'label': 'المرحلة الدراسية:', 'value': caseData['grade_id']?.toString() ?? 'غير معروف'},
    {'label': 'المنطقة:', 'value': caseData['area_id']?.toString() ?? 'غير معروف'},
    {'label': 'القبض:', 'value': caseData['balance']?.toString() ?? 'غير معروف'},
  ];

  return details
      .map((detail) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              textDirection: TextDirection.rtl, // Ensure RTL alignment
              children: [
                Flexible(
                  flex: 1,
                  child: Text(
                    detail['label']!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    detail['value']!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ))
      .toList();
}


  /// Build the QR Code section
  Widget _buildQrCodeSection(String id) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'رمز الاستجابة السريعة (QR Code)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: QrImageView(
                data: id, // Data to encode in the QR code
                version: QrVersions.auto, // Automatically determine QR code version
                size: 200.0, // Size of the QR code
                gapless: true, // Ensures QR code is continuous
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the chest details section
  Widget _buildChestDetailsSection(List<dynamic> chestIds) {
  if (chestIds.isEmpty) {
    return const Center(
      child: Text('لا توجد صناديق مضافة', style: TextStyle(fontSize: 16)),
    );
  }

  // Split chestIds into chunks of 10 (Firestore `whereIn` limit)
  final List<List<dynamic>> idChunks = [];
  for (int i = 0; i < chestIds.length; i += 10) {
    idChunks.add(chestIds.sublist(i, i + 10 > chestIds.length ? chestIds.length : i + 10));
  }

  return FutureBuilder<List<QuerySnapshot>>(
    future: Future.wait(idChunks.map((chunk) => FirebaseFirestore.instance
        .collection('chests')
        .where('id', whereIn: chunk.map((id) => id as int).toList()) // Ensure `id` is treated as a number
        .get())),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final chests = snapshot.data
          ?.expand((querySnapshot) => querySnapshot.docs)
          .toList() ?? [];

      if (chests.isEmpty) {
        return const Center(
          child: Text('لا توجد صناديق مضافة', style: TextStyle(fontSize: 16)),
        );
      }

      return Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الصناديق المرتبطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...chests.map((chest) {
                final chestData = chest.data() as Map<String, dynamic>;
                return Text('• ${chestData['name'] ?? 'غير معروف'}');
              }).toList(),
            ],
          ),
        ),
      );
    },
  );
}



  /// Build the sub details section
  Widget _buildSubDetailsSection(List<dynamic> subIds) {
  if (subIds.isEmpty) {
    return const Center(
      child: Text('لا توجد اشتراكات مضافة', style: TextStyle(fontSize: 16)),
    );
  }

  // Split subIds into chunks of 10 (Firestore `whereIn` limit)
  final List<List<dynamic>> idChunks = [];
  for (int i = 0; i < subIds.length; i += 10) {
    idChunks.add(subIds.sublist(i, i + 10 > subIds.length ? subIds.length : i + 10));
  }

  return FutureBuilder<List<QuerySnapshot>>(
    future: Future.wait(idChunks.map((chunk) => FirebaseFirestore.instance
        .collection('subs')
        .where('id', whereIn: chunk.map((id) => id as int).toList()) // Ensure `id` is treated as a number
        .get())),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final subs = snapshot.data
          ?.expand((querySnapshot) => querySnapshot.docs)
          .toList() ?? [];

      if (subs.isEmpty) {
        return const Center(
          child: Text('لا توجد اشتراكات مضافة', style: TextStyle(fontSize: 16)),
        );
      }

      return Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الاشتراكات المرتبطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...subs.map((sub) {
                final subData = sub.data() as Map<String, dynamic>;
                return Text('• ${subData['name'] ?? 'غير معروف'}');
              }).toList(),
            ],
          ),
        ),
      );
    },
  );
}




  /// Build the family details section
  Widget _buildFamilyDetailsSection(int? familyId) {
    if (familyId == null || familyId == 0) {
      return const Center(
        child: Text('لا توجد بيانات أفراد لهذه العائلة', style: TextStyle(fontSize: 16)),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('cases').where('family_id', isEqualTo: familyId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final familyMembers = snapshot.data?.docs ?? [];

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بيانات أولاد الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (familyMembers.isEmpty)
                  const Center(child: Text('لا يوجد أفراد في الأسرة', style: TextStyle(fontSize: 16))),
                if (familyMembers.isNotEmpty)
                  ...familyMembers.map((member) {
                    final memberData = member.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(memberData['name'] ?? 'غير معروف'),
                      subtitle: Text('العمر: ${memberData['age']}'),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the monthly payments section
  Widget _buildMonthlyPaymentsSection(int caseId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('cashs')
          .where('case_id', isEqualTo: caseId) // Numeric `case_id`
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data?.docs ?? [];

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الدفع الشهري', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  const Center(child: Text('لا توجد بيانات دفع لهذه الحالة', style: TextStyle(fontSize: 16))),
                if (payments.isNotEmpty)
                  ...payments.map((payment) {
                    final paymentData = payment.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('التاريخ: ${paymentData['created_at'] ?? 'غير معروف'}'),
                      subtitle: Text('المبلغ: ${paymentData['credit'] ?? 'غير معروف'}'),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper for detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

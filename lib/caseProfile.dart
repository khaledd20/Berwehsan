import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CaseProfile extends StatelessWidget {
  final String caseId;

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
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('cases').doc(caseId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('لا توجد بيانات لهذه الحالة', style: TextStyle(fontSize: 18)),
              );
            }

            final caseData = snapshot.data!.data() as Map<String, dynamic>;

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
                    _buildFamilyDetailsSection(caseData['family_id']),
                    const SizedBox(height: 16),
                    _buildMonthlyPaymentsSection(caseData['id'].toString()), // Pass `id` to payments section
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
  Widget _buildCaseDetailsSection(Map<String, dynamic> caseData) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _buildDetailRow('رقم الحالة:', caseData['id']?.toString() ?? 'غير معروف'),
            _buildDetailRow('الاسم:', caseData['name'] ?? 'غير معروف'),
            _buildDetailRow('الرقم القومي:', caseData['ID_Number']?.toString() ?? 'غير معروف'),
            _buildDetailRow('رقم الهاتف:', caseData['number']?.toString() ?? 'غير معروف'),
            _buildDetailRow('رقم العائلة:', caseData['family_id']?.toString() ?? 'غير معروف'),
            _buildDetailRow('الصندوق:', caseData['chest_id']?.toString() ?? 'غير معروف'),
            _buildDetailRow('العنوان:', caseData['location'] ?? 'غير معروف'),
            _buildDetailRow('قبض حالة:', caseData['balance']?.toString() ?? 'غير معروف'),
          ],
        ),
      ),
    );
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
    Widget _buildMonthlyPaymentsSection(String caseId) {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('cashs')
            .where('case_id', isEqualTo: int.parse(caseId)) // Filter by `case_id`
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المبلغ: ${paymentData['credit'] ?? 'غير معروف'}'),
                          ],
                        ),
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

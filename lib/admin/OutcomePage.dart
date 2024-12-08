import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OutcomePage extends StatelessWidget {
  const OutcomePage({Key? key}) : super(key: key);

  void _addOutcome(BuildContext context) async {
    final receiptNumber = "R${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة صادر جديد"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "المبلغ"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "ملاحظات"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount != null) {
                await FirebaseFirestore.instance.collection('finance_log').add({
                  "name": "outcome",
                  "receipt_number": receiptNumber,
                  "amount": amount,
                  "type": "out",
                  "date_time": now.toIso8601String(),
                  "notes": noteController.text,
                });

                final financeRef = FirebaseFirestore.instance.collection('finance').doc('outcome');
                final snapshot = await financeRef.get();
                final currentAmount = snapshot.exists ? snapshot['amount'] : 0;
                await financeRef.set({
                  "id": 2,
                  "name": "outcome",
                  "amount": currentAmount + amount,
                  "updated_at": now.toIso8601String(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تمت إضافة الصادر بنجاح!")),
                );
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("سجل الصادر")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('finance_log')
            .where('type', isEqualTo: 'out')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text("رقم الإيصال: ${log['receipt_number']}"),
                subtitle: Text("المبلغ: ${log['amount']} | التاريخ: ${log['date_time']}"),
                trailing: Text(log['notes'] ?? ""),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOutcome(context),
        child: const Icon(Icons.add),
        tooltip: "إضافة صادر جديد",
      ),
    );
  }
}

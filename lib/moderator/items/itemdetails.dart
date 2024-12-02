import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetailsPage extends StatelessWidget {
  final String itemId;

  const ItemDetailsPage({Key? key, required this.itemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العنصر'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('items').doc(itemId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int count = data['count'] ?? 0;
          final String name = data['name'] ?? 'غير معروف';
          final String? note = data.containsKey('note') ? data['note'] : null;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'الاسم: $name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'العدد الحالي: $count',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (note != null && note.isNotEmpty)
                  Text(
                    'ملاحظات: $note',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _updateItemCount(context, itemId, count, isAdd: true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _updateItemCount(context, itemId, count, isAdd: false);
                      },
                      icon: const Icon(Icons.remove),
                      label: const Text('سحب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateItemCount(BuildContext context, String itemId, int currentCount,
    {required bool isAdd}) {
  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController countController = TextEditingController();
      return AlertDialog(
        title: Text(isAdd ? 'إضافة إلى العنصر' : 'سحب من العنصر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('العدد الحالي: $currentCount'),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أدخل العدد',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final int updateCount = int.tryParse(countController.text) ?? 0;
              if (updateCount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أدخل عددًا صحيحًا أكبر من الصفر.')),
                );
                return;
              }

              final int newCount = isAdd
                  ? currentCount + updateCount
                  : (currentCount - updateCount >= 0 ? currentCount - updateCount : 0);

              final String currentTime = DateTime.now().toIso8601String();

              // Fetch the `id` field from the item document
              final DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
                  .collection('items')
                  .doc(itemId)
                  .get();

              final int itemIdField = itemSnapshot['id']; // Fetch `id` from Firestore

              // Update item count and timestamp
              await FirebaseFirestore.instance.collection('items').doc(itemId).update({
                'count': newCount,
                'updated_at': currentTime,
              });

              // Add transaction log using `id` field
              await FirebaseFirestore.instance.collection('store_log').add({
                'item_id': itemIdField, // Use the `id` field from Firestore
                'count': updateCount,
                'status': isAdd ? 'in' : 'out',
                'day': currentTime.split('T').first,
                'created_at': currentTime,
                'updated_at': currentTime,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAdd
                        ? 'تم إضافة $updateCount بنجاح.'
                        : 'تم سحب $updateCount بنجاح.',
                  ),
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );
}


}

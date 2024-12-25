import 'package:berwehsan/accounting/items/addItem.dart';
import 'package:berwehsan/accounting/items/itemdetails.dart';
import 'package:berwehsan/widgets/accounting_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; // Import for ui.TextDirection.
import 'dart:html' as html;

class ViewItemsPage extends StatefulWidget {
  @override
  _ViewItemsPageState createState() => _ViewItemsPageState();
}

class _ViewItemsPageState extends State<ViewItemsPage> {
  String nameFilter = '';
  String noteFilter = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // Use ui.TextDirection.rtl
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض العناصر'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                _printItems(); // Calls the print function
              },
            ),
          ],
        ),
        drawer: AccountingDrawer(), // Add the drawer here
        body: Column(
          children: [
            // Name Filter
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    nameFilter = value.trim();
                  });
                },
              ),
            ),
            // Note Filter
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'بحث بالملاحظات',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    noteFilter = value.trim();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('items').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!.docs.where((item) {
                    final Map<String, dynamic> data =
                        item.data() as Map<String, dynamic>;
                    final String name = data['name'] ?? '';
                    final String note = data['note'] ?? '';

                    // Apply filters
                    final matchesName = name.contains(nameFilter);
                    final matchesNote = note.contains(noteFilter);
                    return matchesName && matchesNote;
                  }).toList();

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final Map<String, dynamic> data =
                          item.data() as Map<String, dynamic>;
                      final String countText = 'العدد الحالي: ${data['count']}';
                      final String note =
                          data.containsKey('note') && data['note'] != null
                              ? data['note']
                              : 'لا توجد ملاحظات';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(
                            data['name'],
                            textAlign: TextAlign.right,
                          ), // Align title to the right
                          subtitle: Text(
                            '$countText\nملاحظات: $note',
                            textAlign: TextAlign.right,
                          ), // Align subtitle text to the right
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.storage,
                                    color: Colors.orange),
                                onPressed: () {
                                  // Navigate to item details page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailsPage(itemId: item.id),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to add item page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddItemPage()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _printItems() async {
  final snapshot = await FirebaseFirestore.instance.collection('items').get();
  final filteredItems = snapshot.docs.where((item) {
    final Map<String, dynamic> data = item.data() as Map<String, dynamic>;
    final String name = data['name'] ?? '';
    final String note = data['note'] ?? '';

    // Apply filters
    final matchesName = name.contains(nameFilter);
    final matchesNote = note.contains(noteFilter);
    return matchesName && matchesNote;
  }).toList();

  final date = DateFormat('dd MMMM yyyy', 'ar').format(DateTime.now());
  final StringBuffer buffer = StringBuffer();

  // Add UTF-8 encoding to the HTML
  buffer.writeln('<html>');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="UTF-8">'); // Ensure proper encoding
  buffer.writeln('<title>طباعة العناصر</title>');
  buffer.writeln('<style>');
  buffer.writeln(
      'table { width: 100%; border-collapse: collapse; margin: 20px 0; }');
  buffer.writeln(
      'th, td { border: 1px solid #ddd; padding: 8px; text-align: right; }');
  buffer.writeln('th { background-color: #f2f2f2; }');
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln(
      '<body style="direction: rtl; font-family: Arial, sans-serif;">');
  buffer.writeln('<h2>التاريخ: $date</h2>');
  buffer.writeln('<h3>العناصر:</h3>');

  // Build table header
  buffer.writeln('<table>');
  buffer.writeln('<thead>');
  buffer.writeln('<tr>');
  buffer.writeln('<th>الاسم</th>');
  buffer.writeln('<th>العدد</th>');
  buffer.writeln('<th>الملاحظات</th>');
  buffer.writeln('</tr>');
  buffer.writeln('</thead>');
  buffer.writeln('<tbody>');

  // Add rows for each filtered item
  for (final item in filteredItems) {
    final Map<String, dynamic> data = item.data() as Map<String, dynamic>;
    final String name = data['name'];
    final int count = data['count'];
    final String note = data.containsKey('note') && data['note'] != null
        ? data['note']
        : 'لا توجد ملاحظات';

    buffer.writeln('<tr>');
    buffer.writeln('<td>$name</td>');
    buffer.writeln('<td>$count</td>');
    buffer.writeln('<td>$note</td>');
    buffer.writeln('</tr>');
  }

  buffer.writeln('</tbody>');
  buffer.writeln('</table>');

  buffer.writeln('</body>');
  buffer.writeln('</html>');

  final html.Blob blob = html.Blob([buffer.toString()], 'text/html');
  final String url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank'); // Open in a new tab
  html.Url.revokeObjectUrl(url);
}

}

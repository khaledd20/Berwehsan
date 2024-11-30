import 'package:berwehsan/admin/items/historyItem.dart';
import 'package:flutter/material.dart';
import '../admin/items/viewItems.dart';
import '../admin/cases.dart';
import '../admin/chests.dart';
import '../admin/insertCase.dart';
import '../login.dart';

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                'القائمة الرئيسية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('ادارة المخزن'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ViewItemsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_rounded),
              title: const Text('سجل المخزن'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryItemPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('الحالات'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CasesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('الصناديق'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ChestsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('تسجيل خروج'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreenWeb()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

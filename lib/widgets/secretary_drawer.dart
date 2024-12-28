import 'package:berwehsan/Secretary/Feeding.dart';
import 'package:berwehsan/Secretary/feedingHistory.dart';
import 'package:berwehsan/Secretary/sub.dart';
import 'package:berwehsan/login.dart';
import 'package:flutter/material.dart';
import '../Secretary/SearchingPage.dart';
import '../Secretary/cases.dart';
import '../Secretary/area.dart';
import '../Secretary/items/viewItems.dart';
import '../Secretary/items/historyItem.dart';

class SecretaryDrawer extends StatelessWidget {
  const SecretaryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'مرحبًا بك، سكرتير',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
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
            leading: const Icon(Icons.folder),
            title: const Text('الكفالة'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SubsPage()),
              );
            },
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
            leading: const Icon(Icons.location_on),
            title: const Text('المناطق'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AreasPage()),
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('الاطعام'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FeedingPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('سجل الإطعام'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FeedingHistoryPage()),
              );
            },
          ),
          ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('بحث الحالات'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SearchingPage()),
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
    );
  }
}

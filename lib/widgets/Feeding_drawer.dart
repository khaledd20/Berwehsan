import 'package:berwehsan/Feeding/cases.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/Feeding/Feeding.dart';
import 'package:berwehsan/Feeding/area.dart';
import 'package:berwehsan/Feeding/feedingHistory.dart';
import 'package:berwehsan/Feeding/items/historyItem.dart';
import 'package:berwehsan/Feeding/items/viewItems.dart';
import 'package:berwehsan/Feeding/sub.dart';
import '../login.dart';

class UserDrawerFeeding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'مستخدم الاطعام',
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
            leading: const Icon(Icons.location_city),
            title: const Text('المناطق'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AreasPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('الاطعام'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FeedingPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('سجل الإطعام'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FeedingHistoryPage()),
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

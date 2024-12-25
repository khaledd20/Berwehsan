import 'package:berwehsan/moderator/CashHistory.dart';
import 'package:berwehsan/moderator/Feeding.dart';
import 'package:berwehsan/moderator/IncomePage.dart';
import 'package:berwehsan/moderator/Itinerary.dart';
import 'package:berwehsan/moderator/OutcomePage.dart';
import 'package:berwehsan/moderator/SearchingPage.dart';
import 'package:berwehsan/moderator/UserControl.dart';
import 'package:berwehsan/moderator/area.dart';
import 'package:berwehsan/moderator/cases.dart';
import 'package:berwehsan/moderator/chests.dart';
import 'package:berwehsan/moderator/feedingHistory.dart';
import 'package:berwehsan/moderator/items/historyItem.dart';
import 'package:berwehsan/moderator/sub.dart';
import 'package:flutter/material.dart';
import '../moderator/items/viewItems.dart';
import '../login.dart';

class ModeratorDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            title: const Text('إدارة المستخدمين'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserControlPage()),
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
              title: const Text('سجل القبض'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CashHistoryPage()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('الصناديق'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChestsPageModerator()),
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
            leading: const Icon(Icons.account_balance),
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
            title: const Text('خط سير'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ItineraryPage()),
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
              title: const Text('الوارد'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => IncomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('الصادر'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => OutcomePage()),
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

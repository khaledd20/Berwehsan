import 'package:berwehsan/accountant/cases.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/user/CashHistory.dart';
import 'package:berwehsan/user/IncomePage.dart';
import 'package:berwehsan/user/Itinerary.dart';
import 'package:berwehsan/user/OutcomePage.dart';
import 'package:berwehsan/user/SearchingPage.dart';
import 'package:berwehsan/user/chests.dart';
import 'package:berwehsan/user/sub.dart';
import '../login.dart';

class UserDrawerAccounting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'مستخدم للمحاسبه',
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
                MaterialPageRoute(builder: (context) => UserChestsPage()),
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

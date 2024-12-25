import 'package:berwehsan/accounting/cases.dart';
import 'package:berwehsan/accounting/sub.dart';
import 'package:berwehsan/login.dart';
import 'package:flutter/material.dart';
import '../accounting/cashHistory.dart';
import '../accounting/chests.dart';
import '../accounting/incomePage.dart';
import '../accounting/outcomePage.dart';
import '../accounting/itinerary.dart';

class AccountingDrawer extends StatelessWidget {
  const AccountingDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'مرحبًا بك، محاسب',
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
            leading: const Icon(Icons.history),
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
            leading: const Icon(Icons.directions),
            title: const Text('خط السير'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ItineraryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward),
            title: const Text('الوارد'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => IncomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_upward),
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

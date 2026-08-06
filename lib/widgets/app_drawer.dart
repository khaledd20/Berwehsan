import 'package:berwehsan/screens/CashHistory.dart';
import 'package:berwehsan/screens/Feeding.dart';
import 'package:berwehsan/screens/IncomePage.dart';
import 'package:berwehsan/screens/Itinerary.dart';
import 'package:berwehsan/screens/ManualBackupPage.dart';
import 'package:berwehsan/screens/OutcomePage.dart';
import 'package:berwehsan/screens/RestoreManager.dart';
import 'package:berwehsan/screens/SearchingPage.dart';
import 'package:berwehsan/screens/UserControl.dart';
import 'package:berwehsan/screens/area.dart';
import 'package:berwehsan/screens/chests.dart';
import 'package:berwehsan/screens/feedingHistory.dart';
import 'package:berwehsan/screens/items/historyItem.dart';
import 'package:berwehsan/screens/sub.dart';
import 'package:berwehsan/screens/unpaid_subs.dart';
import 'package:berwehsan/screens/id_documents.dart';
import 'package:flutter/material.dart';
import '../screens/feeding_change.dart';
import '../screens/items/viewItems.dart';
import '../screens/cases.dart';
import '../screens/sub_id_migration.dart';
import '../login.dart';
import '../core/user_session.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = UserSession();

    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'القائمة الرئيسية\n${session.fullName ?? "مستخدم"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),

            // Cases - Available to Admin, Moderator, User, Accounting, Secretary
            if (session.isAdmin ||
                session.isModerator ||
                session.isAccounting ||
                session.isUser ||
                session.isSecretary ||
                session.isAccountingModerator ||
                session.isSecretaryModerator) ...[
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('الحالات'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CasesPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('الملفات الادارية'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminFilesPage()));
                },
              ),
            ],

            // Chests - Available to Admin, Moderator, User, Accounting
            if (session.isAdmin ||
                session.isModerator ||
                session.isUser ||
                session.isAccounting ||
                session.isAccountingModerator)
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('الصناديق'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminChestsPage()));
                },
              ),

            // Feeding - Available to Admin, Secretary
            if (session.isAdmin ||
                session.isSecretary ||
                session.isSecretaryModerator) ...[
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('الاطعام'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FeedingPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('سجل الإطعام'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FeedingHistoryPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('تغيير الإطعام'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FeedingChangePage()));
                },
              ),
            ],

            // Accounting - Available to Admin, Accounting, Moderator
            if (session.isAdmin ||
                session.isAccounting ||
                session.isModerator ||
                session.isAccountingModerator) ...[
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('الوارد'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const IncomePage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('الصادر'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OutcomePage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('سجل القبض'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CashHistoryPage()));
                },
              ),
            ],

            // Itinerary / Subs / Areas / Searching - Admin, Moderator
            if (session.isAdmin || session.isModerator) ...[
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('خط سير'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ItineraryPage()));
                },
              ),
            ],

            // الكفالة - Available to Admin, Moderator, Accounting (Role 5)
            if (session.isAdmin ||
                session.isModerator ||
                session.isAccounting ||
                session.isAccountingModerator) ...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('الكفالة'),
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SubsPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_off),
                title: const Text('كفالات غير مسددة'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UnpaidSubsPage()));
                },
              ),
            ],

            // المناطق - Available to Admin, Moderator, Secretary (Role 4), Accounting (Role 5)
            if (session.isAdmin ||
                session.isModerator ||
                session.isSecretary ||
                session.isAccounting ||
                session.isAccountingModerator ||
                session.isSecretaryModerator)
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('المناطق'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AreasPage()));
                },
              ),

            // بحث الحالات - Available to Admin, Moderator, Secretary (Role 4)
            if (session.isAdmin ||
                session.isModerator ||
                session.isSecretary ||
                session.isSecretaryModerator)
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('بحث الحالات'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchingPage()));
                },
              ),

            // Inventory - Admin
            if (session.isAdmin ||
                session.isAccounting ||
                session.isAccountingModerator) ...[
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('ادارة المخزن'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViewItemsPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('سجل المخزن'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryItemPage()));
                },
              ),
            ],

            // Admin Only settings
            if (session.isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('عنصر تحكم المستخدم'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserControlPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('عمل نسخة احتياطية'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManualBackupPage()));
                },
              ),
              /* ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('استعادة نسخة احتياطية'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RestoreBackupScreen()));
                },
              ), */
            ],
            /* if (session.isAdmin)
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('أداة ربط معرفات الكفلاء'),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SubIdMigrationPage()));
                },
              ), */

            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('تسجيل خروج'),
              onTap: () {
                session.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginScreenWeb()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

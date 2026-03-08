import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/data_seeder.dart';
import 'admin/manage_users_screen.dart';
import 'admin/edit_content_screen.dart';
import 'admin/safety_management_screen.dart';
import '../services/user_service.dart';
import '../services/place_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color.fromARGB(255, 6, 180, 233),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Quick Stats Row
              Row(
                children: [
                  StreamBuilder<int>(
                    stream: UserService().getUsersCount(),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        'Total Users',
                        snapshot.hasData ? snapshot.data.toString() : '...',
                        Icons.people,
                        Colors.blue,
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    'Active Now',
                    '1', // Semi-real placeholder (at least you are active)
                    Icons.online_prediction,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  StreamBuilder<int>(
                    stream: PlaceService().getPlacesCount(),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        'Places',
                        snapshot.hasData ? snapshot.data.toString() : '...',
                        Icons.place,
                        Colors.orange,
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    'Reports',
                    '0',
                    Icons.report_problem,
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text(
                'Management',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Management Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(context, 'Manage Users', Icons.person_search,
                      Colors.indigo, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageUsersScreen()),
                    );
                  }),
                  _buildMenuCard(context, 'Edit Content',
                      Icons.edit_location_alt, Colors.teal, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditContentScreen()),
                    );
                  }),
                  _buildMenuCard(context, 'Analytics', Icons.bar_chart,
                      Colors.purple, () {}),
                  _buildMenuCard(context, 'System Logs', Icons.history,
                      Colors.blueGrey, () {}),
                  _buildMenuCard(context, 'Promotions', Icons.campaign,
                      Colors.deepOrange, () {}),
                  _buildMenuCard(
                      context, 'Settings', Icons.settings, Colors.grey, () {}),
                  _buildMenuCard(
                      context, 'Seed Initial Data', Icons.storage, Colors.blue,
                      () async {
                    try {
                      await DataSeeder.seedData();
                      Fluttertoast.showToast(msg: 'Data seeded successfully!');
                    } catch (e) {
                      Fluttertoast.showToast(msg: 'Seeding failed: $e');
                    }
                  }),
                  _buildMenuCard(context, 'Safety & Help', Icons.safety_check,
                      Colors.redAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SafetyManagementScreen()),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'business_orders_screen.dart';
import 'business_services_screen.dart';
import 'business_cloth_types_screen.dart';
import 'business_employees_screen.dart';
import 'business_settings_screen.dart';
import '../auth/login_screen.dart';

class BusinessDashboard extends StatelessWidget {
  const BusinessDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaundryCare Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Business Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your laundry business from one place.',
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            Icons.receipt_long,
            'Orders',
            'View and manage customer orders',
            const BusinessOrdersScreen(),
          ),
          _tile(
            context,
            Icons.local_laundry_service,
            'Services',
            'Manage services and prices',
            const BusinessServicesScreen(),
          ),
          _tile(
            context,
            Icons.checkroom,
            'Cloth Types',
            'Manage cloth types and prices',
            const BusinessClothTypesScreen(),
          ),
          _tile(
            context,
            Icons.people,
            'Employees',
            'Manage employee accounts',
            const BusinessEmployeesScreen(),
          ),
          _tile(
            context,
            Icons.settings,
            'Business Settings',
            'Manage business information and preferences',
            const BusinessSettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget screen,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        },
      ),
    );
  }
}
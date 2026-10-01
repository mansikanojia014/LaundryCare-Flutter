import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/business/business_dashboard.dart';
import 'screens/business/employee_dashboard_screen.dart';

class LaundryCareApp extends StatelessWidget {
  const LaundryCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LaundryCare',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC96F4A)),
          scaffoldBackgroundColor: const Color(0xFFF7F1E8),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = context.read<AuthProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final auth = context.watch<AuthProvider>();
        if (!auth.isAuthenticated) return const WelcomeScreen();
        switch (auth.userRole) {
          case 'business': return const BusinessDashboard();
          case 'employee': return const EmployeeDashboard();
          default: return const CustomerDashboard();
        }
      },
    );
  }
}

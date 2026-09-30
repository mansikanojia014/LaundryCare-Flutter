import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';

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
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC96F4A),
          ),
          inputDecorationTheme:
              const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

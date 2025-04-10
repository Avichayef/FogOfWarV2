import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/fog_of_war_provider.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FogOfWarProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Initialize the auth provider
          Future.microtask(() => authProvider.initialize());

          return MaterialApp(
            title: 'Fog of War',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            home: authProvider.isAuthenticated
                ? const MapScreen()
                : const LoginScreen(),
            routes: {
              '/map': (context) => const MapScreen(),
            },
          );
        },
      ),
    );
  }
}

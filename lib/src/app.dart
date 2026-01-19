import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🔄 App widget rebuild - isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}');
        
        if (authProvider.isLoading) {
          print('📱 Mostrando SplashScreen');
          return const SplashScreen();
        }
        
        if (authProvider.isAuthenticated) {
          print('📱 Mostrando HomeScreen');
          return const HomeScreen();
        }
        
        print('📱 Mostrando LoginScreen');
        return const LoginScreen();
      },
    );
  }
}

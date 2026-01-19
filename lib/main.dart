import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/sidebar_provider.dart';
import 'src/app.dart';
import 'src/config/app_routes.dart';
import 'src/services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Portal Web Agrícola',
            theme: themeProvider.currentTheme,
            navigatorKey: NavigationService().navigatorKey,
            home: const App(),
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
            // Configuración de transiciones más suaves
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/delivery_service.dart';
import 'services/driver_service.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialisation des services partagés
  final sharedPreferences = await SharedPreferences.getInstance();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🛑 Erreur Flutter : ${details.exception}');
    debugPrint('📍 Stack : ${details.stack}');
  };

  runApp(
    MultiProvider(
      providers: [
        // Services d'authentification
        ChangeNotifierProvider(
          create: (_) => AuthService(sharedPreferences: sharedPreferences),
        ),
        // Service de gestion des livraisons
        ChangeNotifierProvider(
          create: (context) => DeliveryService(),
        ),
        // Service de gestion des chauffeurs
        ChangeNotifierProvider(
          create: (context) => DriverService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeliveryPro',
      theme: AppTheme.lightTheme,
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.driverHome: (context) => const DriverHomeScreen(),
        Routes.adminHome: (context) => const AdminHomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
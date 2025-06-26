import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!mounted) return;
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      final userRole = await authService.getUserRole();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        userRole == 'admin' ? Routes.adminHome : Routes.driverHome,
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Remplacez par votre logo
            Image.asset(
              'assets/images/delivery.svg',
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
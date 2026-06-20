import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/user_attribute_service.dart';
import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Quitar el splash nativo ahora que la UI de Flutter ya esta visible
    FlutterNativeSplash.remove();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Esperar un poco para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Verificar si el usuario eligió "Remember Me"
      final shouldKeepSession = await StorageService.shouldKeepSession();

      if (!shouldKeepSession) {
        // No eligió "Remember Me" o no hay token, limpiar y ir a login
        await StorageService.clearAll();
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // Verificar autenticación localmente (rápido, sin petición HTTP)
      final isAuthenticated = await AuthService.isAuthenticated(
        verifyWithServer: false,
      );

      if (isAuthenticated) {
        // Usuario autenticado, obtener perfil y verificar atributos desde el API
        try {
          final user = await AuthService.getProfile();
          if (!mounted) return;

          // Verificar si tiene atributos en el servidor
          final attributes = await UserAttributeService.getUserAttributes(user.id);

          if (mounted) {
            if (attributes == null) {
              // No tiene atributos, ir a onboarding
              context.go('/onboarding?userId=${user.id}');
            } else {
              // Ya tiene atributos, ir a main
              context.go('/main');
            }
          }
        } catch (e) {
          // Si falla obtener perfil o atributos, ir a login
          if (mounted) {
            context.go('/login');
          }
        }
      } else {
        // No autenticado, ir a login
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      // Error al verificar, ir a login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF667EEA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 30),
            // Nombre de la app
            const Text(
              'Style AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

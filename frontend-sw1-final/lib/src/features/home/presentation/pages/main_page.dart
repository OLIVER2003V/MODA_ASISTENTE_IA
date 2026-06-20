import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_attribute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/main_navbar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAuth();
  }

  Future<void> _verifyAuth() async {
    try {
      // Verificar autenticación rápidamente
      final isAuthenticated = await AuthService.isAuthenticated();
      if (!isAuthenticated && mounted) {
        context.go('/');
        return;
      }

      // Obtener perfil del usuario
      final user = await AuthService.getProfile();
      if (!mounted) return;

      // Verificar si tiene atributos en el servidor
      final attributes = await UserAttributeService.getUserAttributes(user.id);
      if (!mounted) return;

      if (attributes == null) {
        // No tiene atributos, ir a onboarding
        context.go('/onboarding?userId=${user.id}');
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppPalette.softCoral,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // MainNavbar ya es un Scaffold completo con su propia navegación
    // Solo lo retornamos directamente
    return const MainNavbar();
  }
}

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_attribute_service.dart';
import '../../../../core/services/fcm_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      // Registrar token FCM (no bloquea el login si falla)
      FcmService.registerTokenOnLogin().catchError((_) {});

      if (mounted) {
        // Verificar si tiene atributos en el servidor
        final attributes = await UserAttributeService.getUserAttributes(authResponse.user.id);
        if (mounted) {
          if (attributes == null) {
            // No tiene atributos, ir a onboarding
            context.go('/onboarding?userId=${authResponse.user.id}');
          } else {
            // Ya tiene atributos, ir a main
            context.go('/main');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppPalette.softCoral,
      body: Stack(
        children: [
          // Contenido principal
          SafeArea(
            child: SizedBox(
              height: size.height,
              child: Column(
                children: [
                  // Espacio superior
                  const SizedBox(height: 80),

                  // Card blanco con formulario y curva superior
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: CustomPaint(
                        painter: CurvedTopPainter(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 60),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),

                                  // Título
                                  FadeInDown(
                                    duration: const Duration(milliseconds: 500),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sign in',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppPalette.charcoalGray,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 3,
                                          width: 50,
                                          decoration: BoxDecoration(
                                            color: AppPalette.softCoral,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Campo Email
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 200),
                                    duration: const Duration(milliseconds: 500),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: TextStyle(
                                            color: AppPalette.gray800,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '| demo@email.com',
                                            hintStyle: const TextStyle(
                                              color: Color(0xFFCCCCCC),
                                              fontSize: 14,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: AppPalette.softGray,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppPalette.softCoral,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return l.emailRequired;
                                            }
                                            if (!value.contains('@')) {
                                              return l.emailInvalid;
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Campo Password
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 300),
                                    duration: const Duration(milliseconds: 500),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Password',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: TextStyle(
                                            color: AppPalette.gray800,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '| enter your password',
                                            hintStyle: const TextStyle(
                                              color: Color(0xFFCCCCCC),
                                              fontSize: 14,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outlined,
                                              color: AppPalette.softGray,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: AppPalette.softGray,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppPalette.softCoral,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return l.passwordRequired;
                                            }
                                            if (value.length < 6) {
                                              return l.passwordTooShort;
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Remember me y Forgot password
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 400),
                                    duration: const Duration(milliseconds: 500),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: AppPalette.softCoral,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember Me',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            // TODO: Implementar forgot password
                                          },
                                          child: Text(
                                            'Forget Password?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppPalette.softCoral,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Botón Login
                                  FadeInUp(
                                    delay: const Duration(milliseconds: 500),
                                    duration: const Duration(milliseconds: 500),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppPalette.softCoral,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Link a registro
                                  FadeIn(
                                    delay: const Duration(milliseconds: 600),
                                    duration: const Duration(milliseconds: 500),
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () => context.push('/register'),
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'SF Pro Display',
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: "Don't have an Account? ",
                                                style: TextStyle(
                                                  color: Color(0xFF666666),
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Sign up',
                                                style: TextStyle(
                                                  color: AppPalette.softCoral,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter para la curva superior del card blanco
class CurvedTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 60);

    // Crear una curva suave en la parte superior
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, 60);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

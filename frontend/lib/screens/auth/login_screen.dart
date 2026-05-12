// ============================================================
// ARCHIVO: lib/screens/auth/login_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../app_colors.dart'; // ← Importar AppColors
import 'register_screen.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/perfil_service.dart'; // ← Importar PerfilService para debug

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() { _loading = true; _error = null; });
  try {
    // ✅ Un solo login
    await AuthService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    setState(() => _error = e.toString().replaceAll('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Bienvenido\nde vuelta',
                  style: TextStyle(
                    color: AppColors.textPrim,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Monitorea tu glucosa. Vive mejor.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 36),

                _label('Correo electrónico'),
                const SizedBox(height: 6),
                DarkField(
                  controller: _emailCtrl,
                  hint: 'tu@correo.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (v) => !v!.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 16),

                _label('Contraseña'),
                const SizedBox(height: 6),
                DarkField(
                  controller: _passCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator:
                      (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: AppColors.orange, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 28),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Divisor "o"
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SocialButton(
                  label: 'Continuar con Google',
                  icon: const GoogleIcon(),
                  onTap: () {},
                ),
                const SizedBox(height: 10),

                SocialButton(
                  label: 'Continuar con Apple',
                  icon: const Icon(
                    Icons.apple,
                    color: AppColors.textPrim,
                    size: 20,
                  ),
                  onTap: () {},
                ),
                const SizedBox(height: 28),

                OrangeButton(
                  label: 'Iniciar sesión',
                  loading: _loading,
                  onTap: _login,
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                    child: RichText(
                      text: const TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

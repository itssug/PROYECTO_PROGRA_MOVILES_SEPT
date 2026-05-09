// ============================================================
// ARCHIVO: lib/screens/auth/register_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/shared_widgets.dart';
import '../app_colors.dart'; // ← AppColors está aquí

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _paso = 0;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final _nombreCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confCtrl   = TextEditingController();
  final _aniosCtrl  = TextEditingController();
  final _pesoCtrl   = TextEditingController();
  final _alturaCtrl = TextEditingController();

  String? _sexo;
  int _insulina    = 0;
  int _hiper       = 0;
  int _dislipi     = 0;
  String _actividad = 'sedentario';

  Future<void> _registrar() async {
    // Validar que los campos numéricos sean válidos
    if (_paso == 1) {
      // Validar peso si se ingresó
      if (_pesoCtrl.text.isNotEmpty) {
        if (double.tryParse(_pesoCtrl.text) == null) {
          setState(() => _error = 'El peso debe ser un número válido');
          return;
        }
      }
      
      // Validar altura si se ingresó
      if (_alturaCtrl.text.isNotEmpty) {
        if (double.tryParse(_alturaCtrl.text) == null) {
          setState(() => _error = 'La altura debe ser un número válido');
          return;
        }
      }
      
      // Validar años de diagnóstico
      if (_aniosCtrl.text.isNotEmpty) {
        if (int.tryParse(_aniosCtrl.text) == null) {
          setState(() => _error = 'Los años de diagnóstico deben ser un número válido');
          return;
        }
      }
    }
    
    setState(() { _loading = true; _error = null; });
    
    try {
      print('📝 Iniciando registro...');
      print('Nombre: ${_nombreCtrl.text.trim()}');
      print('Email: ${_emailCtrl.text.trim()}');
      print('Password length: ${_passCtrl.text.length}');
      
      await AuthService.registro(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        confirmarPassword: _confCtrl.text,
        aniosDiagnostico: _aniosCtrl.text.isNotEmpty ? int.tryParse(_aniosCtrl.text) : null,
        peso: _pesoCtrl.text.isNotEmpty ? double.tryParse(_pesoCtrl.text) : null,
        altura: _alturaCtrl.text.isNotEmpty ? double.tryParse(_alturaCtrl.text) : null,
        sexo: _sexo,
        usaInsulina: _insulina,
        tieneHipertension: _hiper,
        tieneDislipidemia: _dislipi,
        nivelActividadBase: _actividad,
      );
      
      print('✅ Registro exitoso!');
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('❌ Error en registro: $e');
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón atrás
                      GestureDetector(
                        onTap: () {
                          if (_paso == 0) Navigator.pop(context);
                          else setState(() => _paso = 0);
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.textMuted, size: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Steps
                      Row(children: [
                        StepDot(n: 1, active: true, done: _paso == 1),
                        Expanded(child: Divider(
                          color: _paso == 1 ? AppColors.orange : AppColors.border,
                          thickness: 1)),
                        StepDot(n: 2, active: _paso == 1, done: false),
                      ]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Datos básicos',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w500,
                            )),
                        Text('Perfil clínico',
                            style: TextStyle(
                              fontSize: 10,
                              color: _paso == 1 ? AppColors.orange : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            )),
                      ]),
                      const SizedBox(height: 24),

                      if (_paso == 0) _buildPaso1() else _buildPaso2(),
                    ],
                  ),
                ),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: _paso == 0
                  ? OrangeButton(
                      label: 'Continuar →',
                      loading: false,
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _paso = 1);
                        }
                      },
                    )
                  : Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _paso = 0),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text('← Atrás',
                              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: OrangeButton(
                          label: 'Crear cuenta',
                          loading: _loading,
                          onTap: _registrar,
                        ),
                      ),
                    ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaso1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Crea tu cuenta',
          style: TextStyle(color: AppColors.textPrim, fontSize: 22,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Tu asistente inteligente de glucosa',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 28),
      _lbl('Nombre completo'),
      const SizedBox(height: 6),
      DarkField(controller: _nombreCtrl, hint: 'Tu nombre', icon: Icons.person_outline,
          validator: (v) => v!.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 16),
      _lbl('Correo electrónico'),
      const SizedBox(height: 6),
      DarkField(controller: _emailCtrl, hint: 'tu@correo.com', icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => !v!.contains('@') ? 'Correo inválido' : null),
      const SizedBox(height: 16),
      _lbl('Contraseña'),
      const SizedBox(height: 6),
      DarkField(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline,
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textHint, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          validator: (v) => v!.length < 8 ? 'Mínimo 8 caracteres' : null),
      const SizedBox(height: 16),
      _lbl('Confirmar contraseña'),
      const SizedBox(height: 6),
      DarkField(controller: _confCtrl, hint: '••••••••', icon: Icons.lock_outline,
          obscure: true,
          validator: (v) => v != _passCtrl.text ? 'No coinciden' : null),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: RichText(text: const TextSpan(
            text: '¿Ya tienes cuenta? ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            children: [TextSpan(text: 'Inicia sesión',
                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600))],
          )),
        ),
      ),
    ],
  );

  Widget _buildPaso2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Perfil clínico',
          style: TextStyle(color: AppColors.textPrim, fontSize: 22,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Personaliza tu experiencia',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 24),
      _lbl('Sexo biológico'),
      const SizedBox(height: 6),
      DarkDropdown(
        value: _sexo,
        hint: 'Seleccionar',
        items: const ['masculino', 'femenino', 'otro'],
        labels: const ['Masculino', 'Femenino', 'Otro'],
        onChanged: (v) => setState(() => _sexo = v),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Peso (kg)'),
          const SizedBox(height: 6),
          DarkField(controller: _pesoCtrl, hint: '70', icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Altura (cm)'),
          const SizedBox(height: 6),
          DarkField(controller: _alturaCtrl, hint: '170', icon: Icons.height,
              keyboardType: TextInputType.number),
        ])),
      ]),
      const SizedBox(height: 16),
      _lbl('Años con diagnóstico'),
      const SizedBox(height: 6),
      DarkField(controller: _aniosCtrl, hint: '0', icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      _lbl('Nivel de actividad'),
      const SizedBox(height: 6),
      DarkDropdown(
        value: _actividad,
        hint: 'Seleccionar',
        items: const ['sedentario', 'moderado', 'activo'],
        labels: const ['Sedentario', 'Moderado', 'Activo'],
        onChanged: (v) => setState(() => _actividad = v!),
      ),
      const SizedBox(height: 20),
      _lbl('Condiciones adicionales'),
      const SizedBox(height: 10),
      DarkToggle(label: 'Usa insulina', value: _insulina == 1,
          onChanged: (v) => setState(() => _insulina = v ? 1 : 0)),
      DarkToggle(label: 'Hipertensión', value: _hiper == 1,
          onChanged: (v) => setState(() => _hiper = v ? 1 : 0)),
      DarkToggle(label: 'Dislipidemia', value: _dislipi == 1,
          onChanged: (v) => setState(() => _dislipi = v ? 1 : 0)),
      const SizedBox(height: 8),
      
      // Información adicional
      Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.textHint, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Estos datos nos ayudarán a personalizar tu experiencia',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500));
}
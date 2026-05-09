// ============================================================
// ARCHIVO: lib/screens/auth/register_screen.dart
// CON TODOS LOS CAMPOS DE DJANGO
// ============================================================
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/shared_widgets.dart';
import '../app_colors.dart';
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

  // Controllers para todos los campos
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  final _fechaNacimientoCtrl = TextEditingController(); // NUEVO
  final _aniosCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _hba1cCtrl = TextEditingController(); // NUEVO

  // Variables para selects
  String? _sexo;
  int _insulina = 0;
  int _hiper = 0;
  int _dislipi = 0;
  int _fumador = 0; // NUEVO
  String _actividad = 'sedentario';

  Future<void> _registrar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.registro(
        // Campos obligatorios
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        confirmarPassword: _confCtrl.text,
        
        // Campos opcionales
        fechaNacimiento: _fechaNacimientoCtrl.text.isNotEmpty 
            ? _fechaNacimientoCtrl.text 
            : null,
        sexo: _sexo,
        peso: double.tryParse(_pesoCtrl.text),
        altura: double.tryParse(_alturaCtrl.text),
        aniosDiagnostico: int.tryParse(_aniosCtrl.text),
        hba1cInicial: double.tryParse(_hba1cCtrl.text), // NUEVO
        usaInsulina: _insulina,
        tieneHipertension: _hiper,
        tieneDislipidemia: _dislipi,
        esFumador: _fumador, // NUEVO
        nivelActividadBase: _actividad,
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
                          width: 36,
                          height: 36,
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

                      // Steps (ahora 3 pasos)
                      Row(children: [
                        StepDot(n: 1, active: _paso == 0, done: _paso > 0),
                        Expanded(child: Divider(
                          color: _paso > 0 ? AppColors.orange : AppColors.border,
                          thickness: 1)),
                        StepDot(n: 2, active: _paso == 1, done: _paso > 1),
                        Expanded(child: Divider(
                          color: _paso > 1 ? AppColors.orange : AppColors.border,
                          thickness: 1)),
                        StepDot(n: 3, active: _paso == 2, done: false),
                      ]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Datos básicos',
                            style: TextStyle(
                              fontSize: 10,
                              color: _paso >= 0 ? AppColors.orange : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            )),
                        Text('Datos físicos',
                            style: TextStyle(
                              fontSize: 10,
                              color: _paso >= 1 ? AppColors.orange : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            )),
                        Text('Historial clínico',
                            style: TextStyle(
                              fontSize: 10,
                              color: _paso >= 2 ? AppColors.orange : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            )),
                      ]),
                      const SizedBox(height: 24),

                      if (_paso == 0) _buildPaso1(),
                      if (_paso == 1) _buildPaso2(),
                      if (_paso == 2) _buildPaso3(),
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
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: _paso < 2
                  ? OrangeButton(
                      label: 'Continuar →',
                      loading: false,
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _paso++);
                        }
                      },
                    )
                  : Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _paso = 1),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text('← Atrás',
                              style: TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w600)),
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

  // PASO 1: Datos básicos (nombre, email, password)
  Widget _buildPaso1() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crea tu cuenta',
              style: TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Ingresa tus datos principales',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 28),
          _lbl('Nombre completo *'),
          const SizedBox(height: 6),
          DarkField(
              controller: _nombreCtrl,
              hint: 'Tu nombre completo',
              icon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Requerido' : null),
          const SizedBox(height: 16),
          _lbl('Correo electrónico *'),
          const SizedBox(height: 6),
          DarkField(
              controller: _emailCtrl,
              hint: 'tu@correo.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => !v!.contains('@') ? 'Correo inválido' : null),
          const SizedBox(height: 16),
          _lbl('Contraseña *'),
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
              validator: (v) => v!.length < 8 ? 'Mínimo 8 caracteres' : null),
          const SizedBox(height: 16),
          _lbl('Confirmar contraseña *'),
          const SizedBox(height: 6),
          DarkField(
              controller: _confCtrl,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: true,
              validator: (v) => v != _passCtrl.text ? 'No coinciden' : null),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                  text: const TextSpan(
                text: '¿Ya tienes cuenta? ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                children: [
                  TextSpan(
                      text: 'Inicia sesión',
                      style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600))
                ],
              )),
            ),
          ),
        ],
      );

  // PASO 2: Datos físicos (fecha nacimiento, peso, altura, sexo, HbA1c)
  Widget _buildPaso2() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos físicos',
              style: TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Cuéntanos sobre ti',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _lbl('Fecha de nacimiento'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.orange,
                        onPrimary: Colors.black,
                        surface: AppColors.surface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() {
                  _fechaNacimientoCtrl.text = date.toIso8601String().split('T')[0];
                });
              }
            },
            child: AbsorbPointer(
              child: DarkField(
                controller: _fechaNacimientoCtrl,
                hint: 'AAAA-MM-DD',
                icon: Icons.cake_outlined,
                validator: (v) => null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Peso (kg)'),
                const SizedBox(height: 6),
                DarkField(
                    controller: _pesoCtrl,
                    hint: '70',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Altura (cm)'),
                const SizedBox(height: 6),
                DarkField(
                    controller: _alturaCtrl,
                    hint: '170',
                    icon: Icons.height,
                    keyboardType: TextInputType.number),
              ],
            )),
          ]),
          const SizedBox(height: 16),
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
          _lbl('HbA1c inicial (%)'),
          const SizedBox(height: 6),
          DarkField(
              controller: _hba1cCtrl,
              hint: '5.7',
              icon: Icons.science_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final value = double.tryParse(v);
                  if (value != null && (value < 3 || value > 15)) {
                    return 'Valor entre 3 y 15';
                  }
                }
                return null;
              }),
          const SizedBox(height: 8),
          Text('Nivel normal: <5.7% | Prediabetes: 5.7-6.4% | Diabetes: ≥6.5%',
              style: TextStyle(color: AppColors.textHint, fontSize: 10)),
        ],
      );

  // PASO 3: Historial clínico
  Widget _buildPaso3() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial clínico',
              style: TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Cuéntanos sobre tu condición',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _lbl('Años con diagnóstico'),
          const SizedBox(height: 6),
          DarkField(
              controller: _aniosCtrl,
              hint: '0',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _lbl('Nivel de actividad física'),
          const SizedBox(height: 6),
          DarkDropdown(
            value: _actividad,
            hint: 'Seleccionar',
            items: const ['sedentario', 'moderado', 'activo'],
            labels: const ['Sedentario', 'Moderado', 'Activo'],
            onChanged: (v) => setState(() => _actividad = v!),
          ),
          const SizedBox(height: 20),
          _lbl('Condiciones médicas'),
          const SizedBox(height: 10),
          DarkToggle(
              label: 'Usa insulina',
              value: _insulina == 1,
              onChanged: (v) => setState(() => _insulina = v ? 1 : 0)),
          DarkToggle(
              label: 'Hipertensión',
              value: _hiper == 1,
              onChanged: (v) => setState(() => _hiper = v ? 1 : 0)),
          DarkToggle(
              label: 'Dislipidemia',
              value: _dislipi == 1,
              onChanged: (v) => setState(() => _dislipi = v ? 1 : 0)),
          DarkToggle(
              label: 'Fumador',
              value: _fumador == 1,
              onChanged: (v) => setState(() => _fumador = v ? 1 : 0)),
          const SizedBox(height: 8),
        ],
      );

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500));
}
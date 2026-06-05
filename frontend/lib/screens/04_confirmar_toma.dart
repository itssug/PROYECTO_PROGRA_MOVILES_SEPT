import 'package:flutter/material.dart';
import '../core/theme.dart';

class ConfirmarTomaScreen extends StatefulWidget {
  const ConfirmarTomaScreen({super.key});

  @override
  State<ConfirmarTomaScreen> createState() => _ConfirmarTomaScreenState();
}

class _ConfirmarTomaScreenState extends State<ConfirmarTomaScreen>
    with SingleTickerProviderStateMixin {
  bool? _fueTomado;
  final _dosisCtrl = TextEditingController(text: '5');
  final _notasCtrl = TextEditingController();
  late AnimationController _checkAnim;
  late Animation<double> _scaleAnim;
  TimeOfDay _horaConfirmada = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    _dosisCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _seleccionar(bool tomado) {
    setState(() => _fueTomado = tomado);
    if (tomado) {
      _checkAnim.forward(from: 0);
    } else {
      _checkAnim.reverse();
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _horaConfirmada,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _horaConfirmada = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Toma')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // ── Medicamento info
          _MedHeader(),
          const SizedBox(height: 24),

          // ── Pregunta principal
          const SectionLabel('¿Tomaste el medicamento?'),
          Row(
            children: [
              Expanded(
                child: _OptionButton(
                  label: 'Sí, lo tomé',
                  icon: Icons.check_circle_rounded,
                  selected: _fueTomado == true,
                  color: AppTheme.success,
                  onTap: () => _seleccionar(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionButton(
                  label: 'No lo tomé',
                  icon: Icons.cancel_rounded,
                  selected: _fueTomado == false,
                  color: AppTheme.danger,
                  onTap: () => _seleccionar(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Animación de confirmación
          if (_fueTomado == true) ...[
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¡Excelente!',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Tu adherencia al tratamiento mejora tu control glucémico.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_fueTomado == false) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.danger, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Omitir dosis puede afectar tu glucosa. Consulta con tu médico si necesitas ajustes.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Detalles del registro (solo si tomado)
          if (_fueTomado == true) ...[
            const SectionLabel('Detalles del registro'),
            AppCard(
              child: Column(
                children: [
                  // Hora exacta
                  GestureDetector(
                    onTap: _pickTime,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppTheme.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hora de toma',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11)),
                                Text(_horaConfirmada.format(context),
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: AppTheme.border, height: 1),
                  // Dosis tomada
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.science_outlined,
                            size: 18, color: AppTheme.accentSoft),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dosis tomada',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11)),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      controller: _dosisCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  const Text(' mg',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Botones +/-
                        Row(
                          children: [
                            _StepButton(
                              icon: Icons.remove_rounded,
                              onTap: () {
                                final v = double.tryParse(_dosisCtrl.text) ?? 0;
                                if (v > 0) _dosisCtrl.text = '${(v - 1).toStringAsFixed(0)}';
                              },
                            ),
                            const SizedBox(width: 8),
                            _StepButton(
                              icon: Icons.add_rounded,
                              onTap: () {
                                final v = double.tryParse(_dosisCtrl.text) ?? 0;
                                _dosisCtrl.text = '${(v + 1).toStringAsFixed(0)}';
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Notas (siempre visible)
          if (_fueTomado != null) ...[
            const SectionLabel('Notas opcionales'),
            AppCard(
              child: TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ej: Tomé con agua, tuve náuseas...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
      // ── FAB de guardar
      floatingActionButton: _fueTomado != null
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: _fueTomado! ? AppTheme.success : AppTheme.danger,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('Guardar registro',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _MedHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.accentDim,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppTheme.accent, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Glibenclamida',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('5 mg · Pastilla · Antes del almuerzo',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const AccentBadge('13:00'),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppTheme.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: selected ? color : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 16),
      ),
    );
  }
}
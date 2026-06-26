
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/alimentacion_service.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _inputBg = Color(0xFF252525);
const _orange = Color(0xFFFF5500);
const _green = Color(0xFF86EFAC);
const _textSub = Color(0xFF9CA3AF);

// Categorías y unidades válidas (deben coincidir con el backend)
const _categorias = [
  ('cereales', 'Cereales'),
  ('legumbres', 'Legumbres'),
  ('frutas', 'Frutas'),
  ('verduras', 'Verduras'),
  ('lacteos', 'Lácteos'),
  ('carnes', 'Carnes'),
  ('bebidas', 'Bebidas'),
  ('snacks', 'Snacks'),
  ('comida_rapida', 'Comida rápida'),
  ('preparado', 'Preparado'),
  ('otro', 'Otro'),
];

const _unidades = [
  ('gramos', 'Gramos (g)'),
  ('ml', 'Mililitros (ml)'),
  ('unidad', 'Unidad'),
  ('taza', 'Taza'),
  ('cucharada', 'Cucharada'),
];

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Campos del formulario
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String _categoria = 'otro';
  String _unidad = 'gramos';
  final _porcionCtrl = TextEditingController(text: '100');
  final _caloriasCtrl = TextEditingController();
  final _carbosCtrl = TextEditingController();
  final _azucaresCtrl = TextEditingController();
  final _proteinasCtrl = TextEditingController();
  final _grasasCtrl = TextEditingController();
  final _fibraCtrl = TextEditingController();
  final _igCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _porcionCtrl.dispose();
    _caloriasCtrl.dispose();
    _carbosCtrl.dispose();
    _azucaresCtrl.dispose();
    _proteinasCtrl.dispose();
    _grasasCtrl.dispose();
    _fibraCtrl.dispose();
    _igCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await AlimentacionService.crearAlimentoPersonalizado(
        nombre: _nombreCtrl.text.trim(),
        categoria: _categoria,
        descripcion: _descripcionCtrl.text.trim().isNotEmpty
            ? _descripcionCtrl.text.trim()
            : null,
        calorias: double.tryParse(_caloriasCtrl.text),
        carbohidratos: double.tryParse(_carbosCtrl.text),
        azucares: double.tryParse(_azucaresCtrl.text),
        proteinas: double.tryParse(_proteinasCtrl.text),
        grasas: double.tryParse(_grasasCtrl.text),
        indiceGlucemico: int.tryParse(_igCtrl.text),
        unidadMedida: _unidad,
        porcionTipica: double.tryParse(_porcionCtrl.text) ?? 100,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('¡"${_nombreCtrl.text.trim()}" creado exitosamente!'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // true = se creó algo nuevo
      }
    } on AlimentacionException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error al crear el alimento. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orange, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Alimento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _guardar,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: _orange, strokeWidth: 2))
                  : const Text('Guardar',
                      style: TextStyle(color: _orange, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Información básica ──────────────────────────
              _buildSectionTitle('Información básica', Icons.restaurant_rounded),
              const SizedBox(height: 12),
              _buildCard([
                _buildTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre del alimento *',
                  hint: 'Ej: Quinua cocida, Galleta integral...',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Categoría *',
                  value: _categoria,
                  items: _categorias,
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descripcionCtrl,
                  label: 'Descripción (opcional)',
                  hint: 'Breve descripción del alimento...',
                  maxLines: 2,
                ),
              ]),

              const SizedBox(height: 24),

              // ── Porción ─────────────────────────────────────
              _buildSectionTitle('Porción de referencia', Icons.scale_rounded),
              const SizedBox(height: 12),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _porcionCtrl,
                        label: 'Cantidad',
                        hint: '100',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Unidad',
                        value: _unidad,
                        items: _unidades,
                        onChanged: (v) => setState(() => _unidad = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Los nutrientes se calcularán proporcionalmente a esta porción.',
                  style: TextStyle(color: _textSub.withOpacity(0.6), fontSize: 11),
                ),
              ]),

              const SizedBox(height: 24),

              // ── Nutrientes ──────────────────────────────────
              _buildSectionTitle('Nutrientes por porción', Icons.pie_chart_rounded),
              const SizedBox(height: 12),
              _buildCard([
                _buildNumberField(
                  controller: _caloriasCtrl,
                  label: 'Calorías (kcal)',
                  hint: 'Ej: 120',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: _orange,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _carbosCtrl,
                        label: 'Carbohidratos (g)',
                        hint: '0.0',
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _azucaresCtrl,
                        label: 'Azúcares (g)',
                        hint: '0.0',
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _proteinasCtrl,
                        label: 'Proteínas (g)',
                        hint: '0.0',
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _grasasCtrl,
                        label: 'Grasas (g)',
                        hint: '0.0',
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildNumberField(
                  controller: _fibraCtrl,
                  label: 'Fibra (g)',
                  hint: '0.0',
                  decimal: true,
                ),
              ]),

              const SizedBox(height: 24),

              // ── Datos glucémicos ────────────────────────────
              _buildSectionTitle('Índice glucémico', Icons.monitor_heart_rounded),
              const SizedBox(height: 12),
              _buildCard([
                _buildNumberField(
                  controller: _igCtrl,
                  label: 'Índice glucémico (0-100)',
                  hint: 'Ej: 55',
                  icon: Icons.speed_rounded,
                  iconColor: _green,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _igLegendDot(const Color(0xFF86EFAC), 'Bajo ≤55'),
                      const SizedBox(width: 16),
                      _igLegendDot(const Color(0xFFFDE68A), 'Medio 56-69'),
                      const SizedBox(width: 16),
                      _igLegendDot(const Color(0xFFFCA5A5), 'Alto ≥70'),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 32),

              // ── Botón guardar ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          'Crear Alimento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets helper del formulario ───────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _orange, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textSub.withOpacity(0.4)),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool decimal = false,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
              : [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textSub.withOpacity(0.4)),
            prefixIcon: icon != null
                ? Icon(icon, color: iconColor ?? _textSub, size: 18)
                : null,
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<(String, String)> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: _card,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            icon: const Icon(Icons.keyboard_arrow_down, color: _textSub, size: 20),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item.$1,
                child: Text(item.$2),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _igLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: _textSub, fontSize: 10)),
      ],
    );
  }
}

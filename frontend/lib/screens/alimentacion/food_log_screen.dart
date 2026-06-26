import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/services/alimentacion_service.dart';
import 'package:frontend/services/in_app_alert_service.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _orange = Color(0xFFFF5500);
const _green = Color(0xFF86EFAC);
const _yellow = Color(0xFFFDE68A);
const _redOrange = Color(0xFFFCA5A5);
const _textSub = Color(0xFF9CA3AF);

// Token de prueba — en producción obtener del sistema de auth (SharedPreferences / Provider)
const _demoToken = 'd43af4dada88bc80639484957f30d603079b5b55395d556d210a5837779a49d5';

// ─── Etiquetas para Tipo de Comida ────────────────────────────────────────────
const _tipoComidaOptions = [
  ('desayuno', 'Desayuno'),
  ('media_manana', 'Media Mañana'),
  ('almuerzo', 'Almuerzo'),
  ('merienda', 'Merienda'),
  ('cena', 'Cena'),
  ('snack', 'Snack'),
];

const _tipoComidaIcons = {
  'desayuno': Icons.wb_sunny_rounded,
  'media_manana': Icons.coffee_rounded,
  'almuerzo': Icons.lunch_dining_rounded,
  'merienda': Icons.apple_rounded,
  'cena': Icons.dinner_dining_rounded,
  'snack': Icons.cookie_rounded,
};

/// Pantalla principal de registro y visualización de alimentos consumidos.
/// Se conecta al backend Django mediante [AlimentacionService].
class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  late final AlimentacionService _service;

  List<RegistroComidaApi> _registros = [];
  ResumenDiario? _resumen;
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  // Límites recomendados
  static const double _limiteCarbos = 150.0;
  static const double _limiteAzucares = 25.0;

  @override
  void initState() {
    super.initState();
    _service = AlimentacionService(token: _demoToken);
    _loadData();
  }

  String get _fechaStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadData({bool checkLimits = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getRegistrosDia(fecha: _fechaStr),
        _service.getResumenDia(fecha: _fechaStr),
      ]);
      setState(() {
        _registros = results[0] as List<RegistroComidaApi>;
        _resumen = results[1] as ResumenDiario;
        _loading = false;
      });

      if (checkLimits && _resumen != null) {
        _verificarLimites(_resumen!);
      }
    } on AlimentacionException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor. Verifica que el backend esté activo.';
        _loading = false;
      });
    }
  }

  void _verificarLimites(ResumenDiario resumen) {
    bool excedioCarbos = resumen.totalCarbohidratos > _limiteCarbos;
    bool excedioAzucares = resumen.totalAzucares > _limiteAzucares;

    if (excedioCarbos || excedioAzucares) {
      String mensaje = 'Has superado el límite diario:\n';
      if (excedioCarbos) {
        mensaje += '• Carbohidratos: ${resumen.totalCarbohidratos.toStringAsFixed(1)}g (Límite: ${_limiteCarbos}g)\n';
      }
      if (excedioAzucares) {
        mensaje += '• Azúcares: ${resumen.totalAzucares.toStringAsFixed(1)}g (Límite: ${_limiteAzucares}g)\n';
      }

      InAppAlertService.show(
        title: 'Alerta Nutricional',
        message: mensaje.trim(),
        type: AlertType.error,
        duration: const Duration(seconds: 8),
      );
    }
  }

  Future<void> _eliminarRegistro(RegistroComidaApi r) async {
    try {
      await _service.eliminarRegistro(r.id);
      _loadData();
    } on AlimentacionException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Navegación entre Fechas ─────────────────────────────────────────────────
  void _prevDay() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _loadData();
  }

  void _nextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_selectedDate.isBefore(tomorrow)) {
      setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDateSelector(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _orange),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openAddFoodSheet(),
        backgroundColor: _orange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Registrar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Cabecera (Header) ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mi Alimentación',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de Fecha ───────────────────────────────────────────────────────
  Widget _buildDateSelector() {
    final hoy = DateTime.now();
    final esHoy = _selectedDate.year == hoy.year &&
        _selectedDate.month == hoy.month &&
        _selectedDate.day == hoy.day;
    final label = esHoy
        ? 'Hoy'
        : DateFormat('d MMM yyyy', 'es').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left_rounded, _prevDay),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          _iconBtn(
            Icons.chevron_right_rounded,
            esHoy ? null : _nextDay,
            disabled: esHoy,
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap,
      {bool disabled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: disabled ? _card.withOpacity(0.4) : _card,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon,
            color: disabled ? Colors.white24 : Colors.white, size: 20),
      ),
    );
  }

  // ── Vista de Error ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Colors.white24, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(30)),
                child: const Text('Reintentar',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contenido Principal ─────────────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_resumen != null) _buildResumenCard(_resumen!),
          const SizedBox(height: 20),
          _buildRegistrosPorTipo(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Tarjeta de Resumen del Día ──────────────────────────────────────────────
  Widget _buildResumenCard(ResumenDiario r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.12),
        border: Border.all(color: _orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: _orange, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Resumen del día',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${r.cantidadRegistros} alimentos',
                style: const TextStyle(color: _textSub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _resumenItem('Calorías',
                  '${r.totalCalorias.toStringAsFixed(0)} kcal', _orange),
              _resumenItem('Carbos',
                  '${r.totalCarbohidratos.toStringAsFixed(1)} g', _yellow, alert: r.totalCarbohidratos > _limiteCarbos),
              _resumenItem('Azúcares',
                  '${r.totalAzucares.toStringAsFixed(1)} g', _redOrange, alert: r.totalAzucares > _limiteAzucares),
              _resumenItem('Carga GL',
                  r.totalCargaGlucemica.toStringAsFixed(1), _green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenItem(String label, String value, Color defaultColor, {bool alert = false}) {
    final color = alert ? Colors.redAccent : defaultColor;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (alert) const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 12),
              if (alert) const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: alert ? Colors.redAccent.withOpacity(0.8) : _textSub, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Lista de Registros Agrupados por Tipo ───────────────────────────────────
  Widget _buildRegistrosPorTipo() {
    if (_registros.isEmpty) {
      return _buildEmptyState();
    }

    // Agrupa por tipo_comida
    final grupos = <String, List<RegistroComidaApi>>{};
    for (final r in _registros) {
      grupos.putIfAbsent(r.tipoComida, () => []).add(r);
    }

    // Muestra en orden
    final widgets = <Widget>[];
    for (final (tipo, _) in _tipoComidaOptions) {
      if (grupos.containsKey(tipo)) {
        widgets.add(_buildGrupoComida(tipo, grupos[tipo]!));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: _card, shape: BoxShape.circle),
            child: const Icon(Icons.no_food_rounded,
                color: Colors.white24, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No hay registros para este día.',
              style: TextStyle(color: _textSub, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Toca "Registrar" para añadir un alimento.',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGrupoComida(
      String tipo, List<RegistroComidaApi> registros) {
    final label = _tipoComidaOptions
        .firstWhere((t) => t.$1 == tipo,
            orElse: () => (tipo, tipo))
        .$2;
    final icon = _tipoComidaIcons[tipo] ?? Icons.restaurant_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _orange, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        ...registros.map((r) => _buildRegistroItem(r)),
      ],
    );
  }

  Widget _buildRegistroItem(RegistroComidaApi r) {
    return Dismissible(
      key: Key('registro_${r.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent),
      ),
      onDismissed: (_) => _eliminarRegistro(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: _orange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.comidaNombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(
                    '${r.cantidad.toStringAsFixed(0)} ${r.unidad}  ·  ${r.hora.substring(0, 5)}',
                    style:
                        const TextStyle(color: _textSub, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(r.caloriasCalculadas ?? 0).toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  'C: ${(r.carbohidratosCalculados ?? 0).toStringAsFixed(1)}g',
                  style: const TextStyle(color: _textSub, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Hoja Inferior (Bottom Sheet): Registrar Alimento ────────────────────────
  void _openAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(
        service: _service,
        selectedDate: _fechaStr,
        onSaved: () {
          Navigator.pop(context);
          _loadData(checkLimits: true);
          
          // Alerta in-app de recordatorio de glucosa post-prandial
          Future.delayed(const Duration(milliseconds: 500), () {
            InAppAlertService.show(
              title: 'Recordatorio de Glucosa',
              message: 'Comida registrada. ¡No olvides medir tu glucosa post-prandial en 2 horas!',
              type: AlertType.info,
              duration: const Duration(seconds: 6),
            );
          });
        },
      ),
    );
  }
}

// ─── Hoja para Registrar Alimento (AddFoodSheet) ──────────────────────────────

class _AddFoodSheet extends StatefulWidget {
  final AlimentacionService service;
  final String selectedDate;
  final VoidCallback onSaved;

  const _AddFoodSheet({
    required this.service,
    required this.selectedDate,
    required this.onSaved,
  });

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _searchCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '100');

  List<ComidaApi> _resultados = [];
  ComidaApi? _selected;
  String _tipoComida = 'almuerzo';
  bool _searching = false;
  bool _saving = false;

  TimeOfDay _hora = TimeOfDay.now();

  Future<void> _buscar(String q) async {
    if (q.length < 2) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await widget.service.buscarAlimentos(q);
      setState(() => _resultados = r);
    } catch (_) {
      setState(() => _resultados = []);
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _guardar() async {
    if (_selected == null) return;
    final cant = double.tryParse(_cantidadCtrl.text);
    if (cant == null || cant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final horaStr =
          '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}:00';
      await widget.service.registrarComida(
        comidaId: _selected!.id,
        cantidad: cant,
        tipoComida: _tipoComida,
        fecha: widget.selectedDate,
        hora: horaStr,
        unidad: _selected!.unidadMedida,
      );
      widget.onSaved();
    } on AlimentacionException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de arrastre (Drag handle)
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Registrar Alimento',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ── Búsqueda ──────────────────────────────────────────────────────
            _label('Buscar alimento'),
            const SizedBox(height: 6),
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Ej: avena, pollo, arroz…',
                  suffix: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: _orange, strokeWidth: 2))
                      : null),
              onChanged: _buscar,
            ),

            // Resultados de búsqueda
            if (_resultados.isNotEmpty && _selected == null) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _resultados.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (_, i) {
                    final c = _resultados[i];
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selected = c;
                          _searchCtrl.text = c.nombre;
                          _resultados = [];
                        });
                      },
                      title: Text(c.nombre,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      subtitle: Text(
                          '${c.calorias?.toStringAsFixed(0) ?? '--'} kcal · ${c.porcionTipica.toStringAsFixed(0)} ${c.unidadMedida}',
                          style: const TextStyle(
                              color: _textSub, fontSize: 12)),
                      trailing: _igChip(c.indiceGlucemico),
                    );
                  },
                ),
              ),
            ],

            // Alimento seleccionado
            if (_selected != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.12),
                  border: Border.all(color: _orange.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: _orange, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_selected!.nombre,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selected = null;
                        _searchCtrl.clear();
                      }),
                      child: const Icon(Icons.close_rounded,
                          color: _textSub, size: 18),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Cantidad ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Cantidad'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cantidadCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco(
                          _selected?.porcionTipica
                                  .toStringAsFixed(0) ??
                              '100',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Unidad'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selected?.unidadMedida ?? 'gramos',
                          style: const TextStyle(color: _textSub),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Tipo de Comida ────────────────────────────────────────────────
            _label('Tipo de comida'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tipoComidaOptions.map((t) {
                final active = _tipoComida == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _tipoComida = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? _orange : _bg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: active ? _orange : Colors.white12),
                    ),
                    child: Text(
                      t.$2,
                      style: TextStyle(
                        color: active ? Colors.white : _textSub,
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Hora ──────────────────────────────────────────────────────────
            _label('Hora de consumo'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _hora,
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: _orange)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _hora = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: _orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _hora.format(context),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón Guardar ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _selected == null || _saving ? null : _guardar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selected == null
                        ? _orange.withOpacity(0.3)
                        : _orange,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Guardar Registro',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Funciones Auxiliares de UI (Helpers) ────────────────────────────────────
  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(color: _textSub, fontSize: 12));
  }

  InputDecoration _inputDeco(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: _bg,
      suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.all(12), child: suffix) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
    );
  }

  Widget? _igChip(int? ig) {
    if (ig == null) return null;
    Color c;
    if (ig <= 55) c = _green;
    else if (ig <= 69) c = _yellow;
    else c = _redOrange;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Text('IG $ig',
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
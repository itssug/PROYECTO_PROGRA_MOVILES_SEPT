
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/diet_model.dart';
import 'package:frontend/screens/alimentacion/diet_detail_screen.dart';
import '../../services/alimentacion_service.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _orange = Color(0xFFFF5500);
const _purple = Color(0xFFD8B4FE);
const _textSub = Color(0xFF9CA3AF);

class DietsScreen extends StatefulWidget {
  const DietsScreen({super.key});

  @override
  State<DietsScreen> createState() => _DietsScreenState();
}

class _DietsScreenState extends State<DietsScreen> {
  int _selectedTab = 0;
  List<Diet> _allDiets = [];
  bool _isLoading = true;
  String? _error;  // ← NUEVO

  List<Diet> get _myDiets => _allDiets.where((d) => d.isMyDiet).toList();

  @override
  void initState() {
    super.initState();
    _loadDiets();
  }

  Future<void> _loadDiets() async {
    setState(() { _isLoading = true; _error = null; });  // ← Limpia error
    try {
      final rawData = await AlimentacionService.getDietasCatalogo();
      final prefs = await SharedPreferences.getInstance();
      final myDietIds = prefs.getStringList('my_diets') ?? [];

      List<Diet> parsed = rawData.map<Diet>((e) {
        String rawId = e['id'].toString().replaceAll(RegExp(r'[^0-9]'), '');
        int dietId = int.tryParse(rawId) ?? 0;

        return Diet(
          id: dietId,
          name: e['name'],
          description: e['description'],
          goal: e['goal'],
          calories: e['calories'],
          proteinGrams: e['proteinGrams'],
          proteinPercent: (e['proteinPercent'] as num).toInt(),
          carbsGrams: e['carbsGrams'],
          carbsPercent: (e['carbsPercent'] as num).toInt(),
          fatGrams: e['fatGrams'],
          fatPercent: (e['fatPercent'] as num).toInt(),
          imageAsset: '',
        );
      }).toList();

      for (var diet in parsed) {
        if (myDietIds.contains(diet.id.toString())) diet.isMyDiet = true;
      }

      setState(() {
        _allDiets = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las dietas.\nVerifica tu conexión.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMyDiet(Diet diet, bool add) async {
    setState(() => diet.isMyDiet = add);
    final prefs = await SharedPreferences.getInstance();
    final myDietIds = _allDiets
        .where((d) => d.isMyDiet)
        .map<String>((d) => d.id.toString())
        .toList();
    await prefs.setStringList('my_diets', myDietIds);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _orange)),
      );
    }

    // ── NUEVO: Vista de error con botón reintentar ──
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 56),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: _textSub, fontSize: 14)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loadDiets,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: _orange, borderRadius: BorderRadius.circular(30)),
                    child: const Text('Reintentar',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabSelector(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedTab == 0
                  ? _buildAllDietsTab()
                  : _buildMyDietsTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cabecera ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dietas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Selector de Pestañas ────────────────────────────────────────────────────
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _tabOption('Todas las Dietas', 0),
          _tabOption('Mis Dietas', 1),
        ],
      ),
    );
  }

  Widget _tabOption(String label, int idx) {
    final active = idx == _selectedTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _orange : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _textSub,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pestaña Todas las Dietas ────────────────────────────────────────────────
  Widget _buildAllDietsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explora Planes de Dieta',
                  style: TextStyle(
                    color: Color(0xFF3B0764),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Planes personalizados para adaptarse a tus metas y estilo de vida.',
                  style: TextStyle(color: Color(0xFF4B0082), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dietas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ..._allDiets.map((diet) => _buildDietCard(diet)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Pestaña Mis Dietas ──────────────────────────────────────────────────────
  Widget _buildMyDietsTab() {
    if (_myDiets.isEmpty) {
      return _buildEmptyMyDiets();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Planes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ..._myDiets.map((diet) => _buildDietCard(diet, showRemove: true)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Estado vacío ────────────────────────────────────────────────────────────
  Widget _buildEmptyMyDiets() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
            ),
            child: Center(child: _EmptyStateIllustration()),
          ),
          const SizedBox(height: 32),
          const Text(
            'Aún no hay Planes de Dieta.',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Inicia una dieta personalizada para hacer\nel seguimiento aún más fácil.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSub, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Text(
                'Explorar Dietas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de Dieta ────────────────────────────────────────────────────────
  Widget _buildDietCard(Diet diet, {bool showRemove = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DietDetailScreen(
              diet: diet,
              onAddToMyDiet: (d) {
                _toggleMyDiet(d, true);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 200,
                width: double.infinity,
                color: const Color(0xFF2A2A2A),
                child: _DietImagePlaceholder(dietName: diet.name),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          diet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (showRemove)
                        GestureDetector(
                          onTap: () {
                            _toggleMyDiet(diet, false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Quitar',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      _macroChip('${diet.calories} kcal'),
                      _macroChip('Proteína: ${diet.proteinGrams}g'),
                      _macroChip('Carbos: ${diet.carbsGrams}g'),
                      _macroChip('Grasas: ${diet.fatGrams}g'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String text) {
    return Text(
      text,
      style: const TextStyle(color: _textSub, fontSize: 12),
    );
  }
}

// ─── Placeholder de imagen de Dieta ───────────────────────────────────────────
class _DietImagePlaceholder extends StatelessWidget {
  final String dietName;
  const _DietImagePlaceholder({required this.dietName});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Estilo de Vida Mediterráneo': [const Color(0xFF2D5016), const Color(0xFF4A7C24)],
      'Quemador de Grasa Bajo en Carbos': [const Color(0xFF1A3A2A), const Color(0xFF2E6644)],
      'Vitalidad Vegana': [const Color(0xFF1A3320), const Color(0xFF2A5530)],
      'Plan de Equilibrio Diabético': [const Color(0xFF1A2A40), const Color(0xFF2A4A6A)],
    };

    final c = colors[dietName] ?? [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text(
              dietName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ilustración del estado vacío ─────────────────────────────────────────────
class _EmptyStateIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: _EmptyPainter(),
    );
  }
}

class _EmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bgPaint = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(Offset(cx, cy + 10), 40, bgPaint);

    final bodyPaint = Paint()..color = const Color(0xFF4A4A5A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 5), width: 24, height: 30),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    canvas.drawCircle(Offset(cx, cy - 16), 12, bodyPaint);

    final leafPaint = Paint()..color = const Color(0xFF3A3A4A);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 30, cy + 8), width: 16, height: 24), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 30, cy + 8), width: 16, height: 24), leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:frontend/models/diet_model.dart';
import 'package:frontend/screens/alimentacion/diet_detail_screen.dart';

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
  int _selectedTab = 0; // 0=All Diets, 1=My Diets

  List<Diet> get _myDiets => mockAllDiets.where((d) => d.isMyDiet).toList();

  @override
  Widget build(BuildContext context) {
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Diets',
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
            child: const Icon(Icons.search_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Tab selector ────────────────────────────────────────────────────────────
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _tabOption('All Diets', 0),
          _tabOption('My Diets', 1),
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

  // ── All Diets tab ───────────────────────────────────────────────────────────
  Widget _buildAllDietsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
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
                  'Explore Diet Plans',
                  style: TextStyle(
                    color: Color(0xFF3B0764),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Personalized plans to match your goals and lifestyle.',
                  style: TextStyle(color: Color(0xFF4B0082), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Diets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...mockAllDiets.map((diet) => _buildDietCard(diet)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── My Diets tab ────────────────────────────────────────────────────────────
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
            'My Plans',
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

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyMyDiets() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _EmptyStateIllustration(),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No Diet Plans Yet.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start a personalized diet to make\ntracking even easier.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSub, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Text(
                'Explore Diets',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diet card ───────────────────────────────────────────────────────────────
  Widget _buildDietCard(Diet diet, {bool showRemove = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DietDetailScreen(
              diet: diet,
              onAddToMyDiet: (d) {
                setState(() => d.isMyDiet = true);
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
            // Image area
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                            setState(() => diet.isMyDiet = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 12),
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
                      _macroChip('Protein: ${diet.proteinGrams}g'),
                      _macroChip('Carbs: ${diet.carbsGrams}g'),
                      _macroChip('Fat: ${diet.fatGrams}g'),
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

// ─── Diet image placeholder ───────────────────────────────────────────────────
class _DietImagePlaceholder extends StatelessWidget {
  final String dietName;
  const _DietImagePlaceholder({required this.dietName});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Mediterranean Lifestyle': [
        const Color(0xFF2D5016),
        const Color(0xFF4A7C24)
      ],
      'Low-Carb Fat Burner': [
        const Color(0xFF1A3A2A),
        const Color(0xFF2E6644)
      ],
      'Vegan Vitality': [const Color(0xFF1A3320), const Color(0xFF2A5530)],
      'Diabetic Balance Plan': [
        const Color(0xFF1A2A40),
        const Color(0xFF2A4A6A)
      ],
    };

    final c = colors[dietName] ??
        [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A)];

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
            const Icon(Icons.restaurant_outlined,
                color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text(
              dietName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state SVG-style illustration ──────────────────────────────────────
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

    // Moon/circle background
    final bgPaint = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(Offset(cx, cy + 10), 40, bgPaint);

    // Person body
    final bodyPaint = Paint()..color = const Color(0xFF4A4A5A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 5), width: 24, height: 30),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // Person head
    canvas.drawCircle(Offset(cx, cy - 16), 12, bodyPaint);

    // Leaves
    final leafPaint = Paint()..color = const Color(0xFF3A3A4A);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - 30, cy + 8), width: 16, height: 24),
        leafPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 30, cy + 8), width: 16, height: 24),
        leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

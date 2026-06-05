import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/diet_model.dart';

const _bg = Color(0xFF0D0D0D);
const _cardDark = Color(0xFF1A1A1A);
const _orange = Color(0xFFFF5500);
const _purple = Color(0xFFD8B4FE);
const _green = Color(0xFF86EFAC);
const _yellow = Color(0xFFFDE68A);
const _redOrange = Color(0xFFFCA5A5);
const _textSub = Color(0xFF9CA3AF);

class DietDetailScreen extends StatefulWidget {
  final Diet diet;
  final void Function(Diet) onAddToMyDiet;

  const DietDetailScreen({
    super.key,
    required this.diet,
    required this.onAddToMyDiet,
  });

  @override
  State<DietDetailScreen> createState() => _DietDetailScreenState();
}

class _DietDetailScreenState extends State<DietDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _added = widget.diet.isMyDiet;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_added) return;
    HapticFeedback.mediumImpact();
    setState(() => _added = true);
    widget.onAddToMyDiet(widget.diet);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.diet.name} added to My Diets!'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diet;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Hero image (top half) ─────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.42,
            width: double.infinity,
            child: _DietHeroImage(dietName: d.name),
          ),
          // ── Back + menu buttons ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(
                    Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  _circleButton(Icons.more_vert_rounded),
                ],
              ),
            ),
          ),
          // ── Slide-up content card ─────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: const BoxDecoration(
                  color: _bg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              d.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Description
                            Text(
                              d.description,
                              style: const TextStyle(
                                color: _textSub,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 4 macro cards
                            Row(
                              children: [
                                Expanded(
                                  child: _macroCard(
                                    'Calories',
                                    '${d.calories} kcal',
                                    null,
                                    _purple,
                                    const Color(0xFF3B0764),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _macroCard(
                                    'Protein',
                                    '${d.proteinGrams}g',
                                    d.proteinPercent / 100,
                                    _green,
                                    const Color(0xFF14532D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _macroCard(
                                    'Carbs',
                                    '${d.carbsGrams}g',
                                    d.carbsPercent / 100,
                                    _yellow,
                                    const Color(0xFF713F12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _macroCard(
                                    'Fat',
                                    '${d.fatGrams}g',
                                    d.fatPercent / 100,
                                    _redOrange,
                                    const Color(0xFF7F1D1D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Goal section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cardDark,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _bg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.track_changes_rounded,
                                        color: _orange,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Goal',
                                          style: TextStyle(
                                            color: _textSub,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          d.goal,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Daily breakdown preview
                            _buildDailyBreakdown(d),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Add to My Diet button ─────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: _handleAdd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 54,
                  decoration: BoxDecoration(
                    color: _added ? const Color(0xFF22C55E) : _orange,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: (_added
                                ? const Color(0xFF22C55E)
                                : _orange)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _added ? '✓ Added to My Diet' : 'Add to My Diet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Macro card ──────────────────────────────────────────────────────────────
  Widget _macroCard(
    String label,
    String value,
    double? progress,
    Color bg,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: textColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(textColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(color: textColor, fontSize: 10)),
                Text('100%',
                    style: TextStyle(color: textColor, fontSize: 10)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Daily breakdown ─────────────────────────────────────────────────────────
  Widget _buildDailyBreakdown(Diet d) {
    final meals = [
      _MealInfo('Breakfast', '7:00 – 9:00 AM',
          '${(d.calories * 0.25).toInt()} kcal', Icons.wb_sunny_rounded),
      _MealInfo('Lunch', '12:00 – 1:30 PM',
          '${(d.calories * 0.35).toInt()} kcal', Icons.lunch_dining_rounded),
      _MealInfo('Snack', '4:00 – 5:00 PM',
          '${(d.calories * 0.10).toInt()} kcal',
          Icons.apple_rounded),
      _MealInfo('Dinner', '7:00 – 8:30 PM',
          '${(d.calories * 0.30).toInt()} kcal',
          Icons.dinner_dining_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Meal Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...meals.map(
          (m) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m.icon, color: _orange, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Text(m.time,
                          style: const TextStyle(
                              color: _textSub, fontSize: 12)),
                    ],
                  ),
                ),
                Text(m.kcal,
                    style: const TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Circle button ───────────────────────────────────────────────────────────
  Widget _circleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _MealInfo {
  final String name;
  final String time;
  final String kcal;
  final IconData icon;
  _MealInfo(this.name, this.time, this.kcal, this.icon);
}

// ─── Hero image ───────────────────────────────────────────────────────────────
class _DietHeroImage extends StatelessWidget {
  final String dietName;
  const _DietHeroImage({required this.dietName});

  @override
  Widget build(BuildContext context) {
    final gradients = {
      'Mediterranean Lifestyle': [
        const Color(0xFF1A3A1A),
        const Color(0xFF2E5A2E),
        const Color(0xFF4A7C3A),
      ],
      'Low-Carb Fat Burner': [
        const Color(0xFF1A2A1A),
        const Color(0xFF2A4A30),
        const Color(0xFF3A6A40),
      ],
      'Vegan Vitality': [
        const Color(0xFF0A2A1A),
        const Color(0xFF1A4A2A),
        const Color(0xFF2A6A3A),
      ],
      'Diabetic Balance Plan': [
        const Color(0xFF1A2A3A),
        const Color(0xFF2A3A5A),
        const Color(0xFF3A5A7A),
      ],
    };
    final colors = gradients[dietName] ??
        [const Color(0xFF1A1A2A), const Color(0xFF2A2A3A), const Color(0xFF3A3A4A)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: colors.last.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.first.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu_rounded,
                    color: Colors.white38, size: 64),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    dietName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

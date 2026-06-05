import 'package:flutter/material.dart';
import 'analysis_screen.dart';
import 'diets_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0D0D0D);
const _navBg = Color(0xFF1A1A1A);
const _orange = Color(0xFFFF5500);

/// Main shell for the Alimentación y Nutrición flow.
/// Hosts a bottom nav with 5 icons as shown in the mockups.
class AlimentacionNavShell extends StatefulWidget {
  const AlimentacionNavShell({super.key});

  @override
  State<AlimentacionNavShell> createState() => _AlimentacionNavShellState();
}

class _AlimentacionNavShellState extends State<AlimentacionNavShell> {
  // Analysis = index 1 (chart icon), Diets = index 3 (plate icon)
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const _PlaceholderScreen(label: 'Home', icon: Icons.home_rounded),
    const AnalysisScreen(),
    const _PlaceholderScreen(
        label: 'AI Assistant', icon: Icons.auto_awesome_rounded),
    const DietsScreen(),
    const _PlaceholderScreen(label: 'Settings', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.show_chart_rounded, label: 'Analysis'),
      _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI'),
      _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Diets'),
      _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      height: 68,
      decoration: BoxDecoration(
        color: _navBg,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 56,
              height: 68,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active ? _orange : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    items[i].icon,
                    color: active ? Colors.white : Colors.white38,
                    size: 22,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

// ─── Placeholder for screens not in this sprint ───────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'En desarrollo',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

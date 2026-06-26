
import 'package:flutter/material.dart';
import 'food_log_screen.dart';
import 'analysis_screen.dart';
import 'diets_screen.dart';
import 'food_log_screen.dart';
import '../app_colors.dart';

class AlimentacionMainScreen extends StatelessWidget {
  const AlimentacionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            'Alimentación',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.orange,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(icon: Icon(Icons.restaurant_rounded), text: 'Registro'),
              Tab(icon: Icon(Icons.show_chart_rounded), text: 'Análisis'),
              Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Dietas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FoodLogScreen(),
            AnalysisScreen(),
            DietsScreen(),
          ],
        ),
      ),
    );
  }
}


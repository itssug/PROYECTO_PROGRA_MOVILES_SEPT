import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../utils/recommendation_engine.dart';
import '../screens/ai_prediction_screen.dart';
import 'ai_model_badge.dart';
import 'ai_gauge_card.dart';
import 'ai_recommendation_list.dart';

/// Plugin del dashboard de IA.
///
/// Muestra el último resultado de predicción si existe,
/// o un prompt para que el usuario ingrese su próxima comida.
class AiDashboardPlugin extends StatefulWidget {
  final int userId;

  /// Datos de contexto del usuario (glucosa basal, sueño, estrés, ejercicio).
  /// Vienen del perfil / últimos registros. NO incluye carbohidratos —
  /// eso lo ingresa el usuario antes de cada comida.
  final Map<String, dynamic> contextData;

  const AiDashboardPlugin({
    Key? key,
    required this.userId,
    this.contextData = const {},
  }) : super(key: key);

  @override
  _AiDashboardPluginState createState() => _AiDashboardPluginState();
}

class _AiDashboardPluginState extends State<AiDashboardPlugin> {
  AIPredictionResult? _lastResult;
  List<String> _lastRecommendations = [];

  /// Abre la pantalla de predicción y captura el resultado al volver
  Future<void> _openPredictionScreen() async {
    final result = await Navigator.push<_PredictionReturn>(
      context,
      MaterialPageRoute(
        builder: (_) => AiPredictionScreen(
          userId: widget.userId,
          contextData: widget.contextData,
        ),
      ),
    );

    // Si el usuario predijo algo, actualizamos el dashboard
    if (result != null && mounted) {
      setState(() {
        _lastResult = result.prediction;
        _lastRecommendations = result.recommendations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header de sección
        _buildHeader(),
        const SizedBox(height: 10),

        // Si hay un resultado previo, lo mostramos
        if (_lastResult != null) ...[
          AiModelBadge(modelUsed: _lastResult!.modelUsed),
          const SizedBox(height: 8),
          AiGaugeCard(
            predictedGlucose: _lastResult!.predictedGlucose,
            riskLevel: _lastResult!.riskLevel,
          ),
          if (_lastRecommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            AiRecommendationList(recommendations: _lastRecommendations),
          ],
          const SizedBox(height: 10),
          // Botón para nueva predicción
          _buildNewPredictionButton(),
        ] else ...[
          // Estado vacío: invitar al usuario a predecir
          _buildEmptyState(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.hub_rounded, color: Color(0xFFFF7A00), size: 16),
        const SizedBox(width: 6),
        const Text(
          'PREDICCIÓN IA',
          style: TextStyle(
            color: Color(0xFF8E8E9A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        if (_lastResult != null)
          Text(
            'Última predicción',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  /// Tarjeta de estado vacío — invita a predecir antes de comer
  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _openPredictionScreen,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C38)),
        ),
        child: Column(
          children: [
            // Ícono central con glow
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFFFF7A00),
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '¿Qué vas a comer?',
              style: TextStyle(
                color: Color(0xFFF5F5F7),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ingresa los datos de tu próxima comida y la IA predecirá tu glucosa ~2h después.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E8E9A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B2500), Color(0xFFFF7A00)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Predecir con IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPredictionButton() {
    return GestureDetector(
      onTap: _openPredictionScreen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2C38)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFFFF7A00), size: 18),
            SizedBox(width: 6),
            Text(
              'Nueva predicción',
              style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dato de retorno de la pantalla de predicción al dashboard
class _PredictionReturn {
  final AIPredictionResult prediction;
  final List<String> recommendations;
  const _PredictionReturn(
      {required this.prediction, required this.recommendations});
}

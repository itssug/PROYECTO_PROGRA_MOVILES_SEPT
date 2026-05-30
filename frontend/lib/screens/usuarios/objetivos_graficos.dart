// ============================================================
// ARCHIVO: lib/screens/usuarios/objetivos_graficos.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_colors.dart';

class ObjetivosGraficosScreen extends StatefulWidget {
  const ObjetivosGraficosScreen({super.key});

  @override
  State<ObjetivosGraficosScreen> createState() => _ObjetivosGraficosScreenState();
}

class _ObjetivosGraficosScreenState extends State<ObjetivosGraficosScreen> {
  // Variables de objetivos (simuladas)
  double glucosaAyunasMin = 80;
  double glucosaAyunasMax = 130;
  double glucosaPostMin = 80;
  double glucosaPostMax = 180;
  int caloriasDiarias = 1800;
  int carbohidratosDia = 200;
  int pasosDiarios = 7000;
  double pesoObjetivo = 70.5;
  double hba1cObjetivo = 7.0;
  
  // Valores reales actuales (simulados para la gráfica)
  final double glucosaActual = 115;
  final double carbohidratosActual = 185;
  final int pasosActual = 5200;
  final double pesoActual = 72.3;
  final double hba1cActual = 6.8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mis Objetivos'),
        backgroundColor: AppColors.bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.orange),
            onPressed: _mostrarDialogoEditarObjetivos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón flotante de edición (alternativa)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _mostrarDialogoEditarObjetivos,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar Objetivos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Gráfico Glucosa en Ayunas
            _ObjetivoCard(
              title: 'Glucosa en Ayunas',
              icon: Icons.bloodtype,
              child: Column(
                children: [
                  _buildGlucosaAyunasChart(),
                  const SizedBox(height: 16),
                  _buildRangoTexto('Meta: $glucosaAyunasMin - $glucosaAyunasMax mg/dL'),
                  _buildProgresoTexto('Actual: $glucosaActual mg/dL'),
                  _buildProgressBar(
                    glucosaActual,
                    glucosaAyunasMin,
                    glucosaAyunasMax,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Gráfico Glucosa Postprandial
            _ObjetivoCard(
              title: 'Glucosa Postprandial',
              icon: Icons.timeline,
              child: Column(
                children: [
                  _buildGlucosaPostChart(),
                  const SizedBox(height: 16),
                  _buildRangoTexto('Meta: $glucosaPostMin - $glucosaPostMax mg/dL'),
                  _buildProgresoTexto('Actual: 145 mg/dL'),
                  _buildProgressBar(145, glucosaPostMin, glucosaPostMax),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Grid de métricas principales
            Row(
              children: [
                Expanded(
                  child: _MetricaCircular(
                    titulo: 'Calorías',
                    valor: '${(caloriasDiarias * 0.85).toInt()}',
                    objetivo: caloriasDiarias.toString(),
                    unidad: 'kcal',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricaCircular(
                    titulo: 'Carbohidratos',
                    valor: carbohidratosActual.toString(),
                    objetivo: carbohidratosDia.toString(),
                    unidad: 'g',
                    icon: Icons.bakery_dining,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _MetricaCircular(
                    titulo: 'Pasos',
                    valor: pasosActual.toString(),
                    objetivo: pasosDiarios.toString(),
                    unidad: 'pasos',
                    icon: Icons.directions_walk,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricaCircular(
                    titulo: 'HbA1c',
                    valor: hba1cActual.toString(),
                    objetivo: hba1cObjetivo.toString(),
                    unidad: '%',
                    icon: Icons.science,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Peso objetivo
            _ObjetivoCard(
              title: 'Control de Peso',
              icon: Icons.monitor_weight,
              child: Column(
                children: [
                  _buildPesoChart(),
                  const SizedBox(height: 16),
                  _buildRangoTexto('Objetivo: $pesoObjetivo kg'),
                  _buildProgresoTexto('Actual: $pesoActual kg'),
                  _buildProgressBar(
                    pesoActual,
                    pesoObjetivo - 10,
                    pesoObjetivo + 5,
                    invertir: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico de glucosa en ayunas (línea)
  Widget _buildGlucosaAyunasChart() {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const semanas = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                  if (value.toInt() >= 0 && value.toInt() < semanas.length) {
                    return Text(semanas[value.toInt()]);
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 82), FlSpot(1, 95), FlSpot(2, 88),
                FlSpot(3, 125), FlSpot(4, 105), FlSpot(5, 98),
                FlSpot(6, 92),
              ],
              isCurved: true,
              color: AppColors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.orange.withOpacity(0.1),
              ),
            ),
            // Línea de objetivo mínimo
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), glucosaAyunasMin)),
              isCurved: false,
              color: Colors.green.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
            // Línea de objetivo máximo
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), glucosaAyunasMax)),
              isCurved: false,
              color: Colors.red.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
          ],
          minY: 50,
          maxY: 200,
        ),
      ),
    );
  }

  // Gráfico de glucosa postprandial
  Widget _buildGlucosaPostChart() {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const horas = ['8', '10', '12', '14', '16', '18', '20'];
                  if (value.toInt() >= 0 && value.toInt() < horas.length) {
                    return Text(horas[value.toInt()]);
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 110), FlSpot(1, 130), FlSpot(2, 155),
                FlSpot(3, 140), FlSpot(4, 120), FlSpot(5, 115),
                FlSpot(6, 105),
              ],
              isCurved: true,
              color: AppColors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.orange.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), glucosaPostMin)),
              isCurved: false,
              color: Colors.green.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), glucosaPostMax)),
              isCurved: false,
              color: Colors.red.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
          ],
          minY: 50,
          maxY: 250,
        ),
      ),
    );
  }

  // Gráfico de peso
  Widget _buildPesoChart() {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const semanas = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7'];
                  if (value.toInt() >= 0 && value.toInt() < semanas.length) {
                    return Text(semanas[value.toInt()]);
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 74), FlSpot(1, 73.5), FlSpot(2, 73.2),
                FlSpot(3, 72.8), FlSpot(4, 72.5), FlSpot(5, 72.3),
                FlSpot(6, 72.1),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), pesoObjetivo)),
              isCurved: false,
              color: Colors.green.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
          ],
          minY: 60,
          maxY: 85,
        ),
      ),
    );
  }

  // Diálogo para editar objetivos
  void _mostrarDialogoEditarObjetivos() {
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Objetivos'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildObjetivoField(
                    'Glucosa en Ayunas (min)',
                    glucosaAyunasMin,
                    (v) => glucosaAyunasMin = double.parse(v),
                  ),
                  _buildObjetivoField(
                    'Glucosa en Ayunas (max)',
                    glucosaAyunasMax,
                    (v) => glucosaAyunasMax = double.parse(v),
                  ),
                  _buildObjetivoField(
                    'Glucosa Post (min)',
                    glucosaPostMin,
                    (v) => glucosaPostMin = double.parse(v),
                  ),
                  _buildObjetivoField(
                    'Glucosa Post (max)',
                    glucosaPostMax,
                    (v) => glucosaPostMax = double.parse(v),
                  ),
                  _buildObjetivoField(
                    'Calorías diarias',
                    caloriasDiarias.toDouble(),
                    (v) => caloriasDiarias = int.parse(v),
                    esEntero: true,
                  ),
                  _buildObjetivoField(
                    'Carbohidratos/día',
                    carbohidratosDia.toDouble(),
                    (v) => carbohidratosDia = int.parse(v),
                    esEntero: true,
                  ),
                  _buildObjetivoField(
                    'Pasos diarios',
                    pasosDiarios.toDouble(),
                    (v) => pasosDiarios = int.parse(v),
                    esEntero: true,
                  ),
                  _buildObjetivoField(
                    'Peso objetivo',
                    pesoObjetivo,
                    (v) => pesoObjetivo = double.parse(v),
                  ),
                  _buildObjetivoField(
                    'HbA1c objetivo',
                    hba1cObjetivo,
                    (v) => hba1cObjetivo = double.parse(v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Objetivos actualizados')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildObjetivoField(String label, double valor, Function(String) onSaved,
      {bool esEntero = false}) {
    final controller = TextEditingController(text: esEntero ? valor.toInt().toString() : valor.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo requerido';
          if (double.tryParse(value) == null) return 'Número válido';
          return null;
        },
        onSaved: (newValue) {
          if (newValue != null) onSaved(newValue);
        },
      ),
    );
  }

  Widget _buildRangoTexto(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
    );
  }

  Widget _buildProgresoTexto(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: AppColors.textPrim,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProgressBar(double actual, double min, double max, {bool invertir = false}) {
    double porcentaje;
    if (invertir) {
      // Para peso: queremos acercarnos al objetivo desde arriba o abajo
      porcentaje = ((max - actual) / (max - min)).clamp(0.0, 1.0);
    } else {
      porcentaje = ((actual - min) / (max - min)).clamp(0.0, 1.0);
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              color: porcentaje >= 0.9 ? Colors.red : 
                     porcentaje >= 0.6 ? Colors.orange : 
                     Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: ${min.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('Actual: ${actual.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: AppColors.orange)),
              Text('Max: ${max.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGETS AUXILIARES
// ============================================================

class _ObjetivoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ObjetivoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricaCircular extends StatelessWidget {
  final String titulo;
  final String valor;
  final String objetivo;
  final String unidad;
  final IconData icon;
  final Color color;

  const _MetricaCircular({
    required this.titulo,
    required this.valor,
    required this.objetivo,
    required this.unidad,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double porcentaje = double.parse(valor) / double.parse(objetivo);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: porcentaje.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[800],
                  color: color,
                  strokeWidth: 6,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      unidad,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obj: $objetivo $unidad',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
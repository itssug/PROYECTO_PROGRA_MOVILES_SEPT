class Diet {
  final int id;
  final String name;
  final String description;
  final String imageAsset;
  final int calories;
  final int proteinPercent;
  final int carbsPercent;
  final int fatPercent;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final String goal;
  bool isMyDiet;

  Diet({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.calories,
    required this.proteinPercent,
    required this.carbsPercent,
    required this.fatPercent,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.goal,
    this.isMyDiet = false,
  });
}

class FoodEntry {
  final String foodName;
  final String mealType;
  final double calories;
  final double carbs;
  final double sugars;
  final double proteins;
  final double fats;
  final double glycemicLoad;
  final String time;

  FoodEntry({
    required this.foodName,
    required this.mealType,
    required this.calories,
    required this.carbs,
    required this.sugars,
    required this.proteins,
    required this.fats,
    required this.glycemicLoad,
    required this.time,
  });
}

// ─── Datos Simulados (Mock Data) ──────────────────────────────────────────────

final List<Diet> mockAllDiets = [
  Diet(
    id: 1,
    name: 'Estilo de Vida Mediterráneo',
    description:
        'Esta dieta se centra en alimentos integrales, incluyendo verduras frescas, aceite de oliva de calidad, pescado magro, nueces nutritivas y cereales integrales. Ofrece una forma equilibrada y sabrosa de comer que favorece tu salud.',
    imageAsset: 'mediterranean',
    calories: 2000,
    proteinPercent: 25,
    carbsPercent: 40,
    fatPercent: 30,
    proteinGrams: 120,
    carbsGrams: 200,
    fatGrams: 70,
    goal: 'Salud Cardiovascular, Mantenimiento de Peso',
  ),
  Diet(
    id: 2,
    name: 'Quemador de Grasa Bajo en Carbos',
    description:
        'Un plan de inspiración cetogénica que limita los carbohidratos y prioriza las grasas saludables y las proteínas. Ideal para el control del azúcar en sangre y la pérdida de grasa.',
    imageAsset: 'lowcarb',
    calories: 1800,
    proteinPercent: 35,
    carbsPercent: 20,
    fatPercent: 45,
    proteinGrams: 160,
    carbsGrams: 100,
    fatGrams: 80,
    goal: 'Control de Azúcar en Sangre, Pérdida de Peso',
  ),
  Diet(
    id: 3,
    name: 'Vitalidad Vegana',
    description:
        'Un plan basado en plantas rico en legumbres, verduras, frutas y cereales integrales. Alto en fibra y antioxidantes, apoyando el bienestar a largo plazo.',
    imageAsset: 'vegan',
    calories: 2000,
    proteinPercent: 25,
    carbsPercent: 55,
    fatPercent: 20,
    proteinGrams: 125,
    carbsGrams: 300,
    fatGrams: 55,
    goal: 'Antiinflamatorio, Impulso de Energía',
    isMyDiet: true,
  ),
  Diet(
    id: 4,
    name: 'Plan de Equilibrio Diabético',
    description:
        'Diseñado específicamente para el manejo de la diabetes tipo II. Incluye alimentos de bajo índice glucémico, macros equilibrados y liberación constante de energía durante todo el día.',
    imageAsset: 'diabetic',
    calories: 1700,
    proteinPercent: 30,
    carbsPercent: 40,
    fatPercent: 30,
    proteinGrams: 130,
    carbsGrams: 170,
    fatGrams: 57,
    goal: 'Control de Glucosa, Energía Constante',
  ),
];

// Datos de tendencias de calorías: [línea de meta, consumo real] para Lunes–Domingo
final List<double> goalCalories = [300, 280, 310, 250, 290, 260, 300];
final List<double> actualCalories = [220, 310, 390, 160, 300, 220, 250];

final List<FoodEntry> mockTodayEntries = [
  FoodEntry(
    foodName: 'Avena cocida',
    mealType: 'Desayuno',
    calories: 71,
    carbs: 12,
    sugars: 0.5,
    proteins: 2.5,
    fats: 1.4,
    glycemicLoad: 6.6,
    time: '07:30',
  ),
  FoodEntry(
    foodName: 'Pechuga de pollo a la plancha',
    mealType: 'Almuerzo',
    calories: 165,
    carbs: 0,
    sugars: 0,
    proteins: 31,
    fats: 3.6,
    glycemicLoad: 0,
    time: '13:00',
  ),
  FoodEntry(
    foodName: 'Arroz integral cocido',
    mealType: 'Almuerzo',
    calories: 123,
    carbs: 26,
    sugars: 0.4,
    proteins: 2.7,
    fats: 1,
    glycemicLoad: 14.3,
    time: '13:05',
  ),
  FoodEntry(
    foodName: 'Manzana',
    mealType: 'Snack',
    calories: 52,
    carbs: 13.8,
    sugars: 10.4,
    proteins: 0.3,
    fats: 0.2,
    glycemicLoad: 5.2,
    time: '16:00',
  ),
];
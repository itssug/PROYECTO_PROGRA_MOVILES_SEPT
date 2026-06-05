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

// ─── Mock Data ───────────────────────────────────────────────────────────────

final List<Diet> mockAllDiets = [
  Diet(
    id: 1,
    name: 'Mediterranean Lifestyle',
    description:
        'This diet focuses on whole foods, featuring fresh vegetables, quality olive oil, lean fish, nutritious nuts, and wholesome grains. It offers a balanced and tasty way to eat that supports your health.',
    imageAsset: 'mediterranean',
    calories: 2000,
    proteinPercent: 25,
    carbsPercent: 40,
    fatPercent: 30,
    proteinGrams: 120,
    carbsGrams: 200,
    fatGrams: 70,
    goal: 'Heart Health, Weight Maintenance',
  ),
  Diet(
    id: 2,
    name: 'Low-Carb Fat Burner',
    description:
        'A ketogenic-inspired plan that limits carbohydrates and prioritizes healthy fats and proteins. Ideal for blood sugar management and fat loss.',
    imageAsset: 'lowcarb',
    calories: 1800,
    proteinPercent: 35,
    carbsPercent: 20,
    fatPercent: 45,
    proteinGrams: 160,
    carbsGrams: 100,
    fatGrams: 80,
    goal: 'Blood Sugar Control, Weight Loss',
  ),
  Diet(
    id: 3,
    name: 'Vegan Vitality',
    description:
        'A plant-based plan rich in legumes, vegetables, fruits and whole grains. High in fiber and antioxidants, supporting long-term wellness.',
    imageAsset: 'vegan',
    calories: 2000,
    proteinPercent: 25,
    carbsPercent: 55,
    fatPercent: 20,
    proteinGrams: 125,
    carbsGrams: 300,
    fatGrams: 55,
    goal: 'Anti-inflammation, Energy Boost',
    isMyDiet: true,
  ),
  Diet(
    id: 4,
    name: 'Diabetic Balance Plan',
    description:
        'Specifically designed for type II diabetes management. Low glycemic index foods, balanced macros, and steady energy release throughout the day.',
    imageAsset: 'diabetic',
    calories: 1700,
    proteinPercent: 30,
    carbsPercent: 40,
    fatPercent: 30,
    proteinGrams: 130,
    carbsGrams: 170,
    fatGrams: 57,
    goal: 'Glucose Control, Steady Energy',
  ),
];

// Calorie trend data: [goal line, actual consumption] for Mon–Sun
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

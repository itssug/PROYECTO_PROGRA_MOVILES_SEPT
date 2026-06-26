
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
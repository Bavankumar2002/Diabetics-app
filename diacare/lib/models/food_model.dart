class FoodItem {
  final int id;
  final String name;
  final String category;
  final String mealSlot;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final bool isDiabetesFriendly;
  final String dietType; // Vegetarian, Non-vegetarian, Vegan, Eggetarian
  final bool isLowCarb;
  final bool isHighFiber;
  final bool isHighProtein;
  final String description;
  final String? imageUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.mealSlot,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.isDiabetesFriendly = true,
    this.dietType = 'Vegetarian',
    this.isLowCarb = false,
    this.isHighFiber = false,
    this.isHighProtein = false,
    this.description = '',
    this.imageUrl,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      mealSlot: json['meal_slot']?.toString() ?? 'Breakfast',
      servingSize: json['serving_size']?.toString() ?? '1 serving',
      calories: double.tryParse(json['calories']?.toString() ?? '0') ?? 0.0,
      protein: double.tryParse(json['protein']?.toString() ?? '0') ?? 0.0,
      carbs: double.tryParse(json['carbs']?.toString() ?? '0') ?? 0.0,
      fat: double.tryParse(json['fat']?.toString() ?? '0') ?? 0.0,
      fiber: double.tryParse(json['fiber']?.toString() ?? '0') ?? 0.0,
      isDiabetesFriendly: json['is_diabetes_friendly'] == 1 || json['is_diabetes_friendly'] == true || json['is_diabetes_friendly'] == '1',
      dietType: json['diet_type']?.toString() ?? 'Vegetarian',
      isLowCarb: json['is_low_carb'] == 1 || json['is_low_carb'] == true || json['is_low_carb'] == '1',
      isHighFiber: json['is_high_fiber'] == 1 || json['is_high_fiber'] == true || json['is_high_fiber'] == '1',
      isHighProtein: json['is_high_protein'] == 1 || json['is_high_protein'] == true || json['is_high_protein'] == '1',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class FoodLogItem {
  final int id;
  final String mealTime;
  final int? foodItemId;
  final String name;
  final double quantity;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String loggedDate;

  FoodLogItem({
    required this.id,
    required this.mealTime,
    this.foodItemId,
    required this.name,
    required this.quantity,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.loggedDate,
  });

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    return FoodLogItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      mealTime: json['meal_time']?.toString() ?? 'Breakfast',
      foodItemId: json['food_item_id'] != null ? int.tryParse(json['food_item_id'].toString()) : null,
      name: json['custom_name']?.toString() ?? json['name']?.toString() ?? 'Food item',
      quantity: double.tryParse(json['quantity']?.toString() ?? '1.0') ?? 1.0,
      servingSize: json['serving_size']?.toString() ?? '1 serving',
      calories: double.tryParse(json['calories']?.toString() ?? '0') ?? 0.0,
      protein: double.tryParse(json['protein']?.toString() ?? '0') ?? 0.0,
      carbs: double.tryParse(json['carbs']?.toString() ?? '0') ?? 0.0,
      fat: double.tryParse(json['fat']?.toString() ?? '0') ?? 0.0,
      fiber: double.tryParse(json['fiber']?.toString() ?? '0') ?? 0.0,
      loggedDate: json['logged_date']?.toString() ?? '',
    );
  }
}

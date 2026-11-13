class UserModel {
  final int id;
  final String phone;
  final String countryCode;
  final String name;
  final int age;
  final String gender;
  final String country;
  final String state;
  final String district;
  final String city;
  final String pincode;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final List<String> healthGoals;
  final String foodPreference;
  final String allergies;
  final String dietaryRestrictions;
  final double sleepHours;
  final String sleepQuality;
  final int waterGoalMl;
  final int stepGoal;
  final int exerciseGoalMins;
  final int calorieGoal;
  final String diabetesType;
  final String diagnosisDate;
  final String durationYears;
  final bool familyHistory;
  final String comorbidities;
  final double? currentFastingGlucose;
  final double? currentPostMealGlucose;
  final double? currentHba1c;
  final double targetGlucoseMin;
  final double targetGlucoseMax;

  UserModel({
    required this.id,
    required this.phone,
    this.countryCode = '+91',
    required this.name,
    this.age = 30,
    this.gender = 'Prefer not to say',
    this.country = 'India',
    this.state = '',
    this.district = '',
    this.city = '',
    this.pincode = '',
    this.heightCm = 170.0,
    this.weightKg = 70.0,
    this.activityLevel = 'Moderately Active',
    this.healthGoals = const [],
    this.foodPreference = 'Vegetarian',
    this.allergies = '',
    this.dietaryRestrictions = '',
    this.sleepHours = 7.5,
    this.sleepQuality = 'Good',
    this.waterGoalMl = 2500,
    this.stepGoal = 8000,
    this.exerciseGoalMins = 30,
    this.calorieGoal = 1800,
    this.diabetesType = 'Type 2 Diabetes',
    this.diagnosisDate = '',
    this.durationYears = '',
    this.familyHistory = false,
    this.comorbidities = '',
    this.currentFastingGlucose,
    this.currentPostMealGlucose,
    this.currentHba1c,
    this.targetGlucoseMin = 70.0,
    this.targetGlucoseMax = 140.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> goals = [];
    if (json['health_goals_list'] is List) {
      goals = List<String>.from(json['health_goals_list']);
    } else if (json['health_goals'] != null) {
      try {
        final parsed = json['health_goals'];
        if (parsed is List) {
          goals = List<String>.from(parsed);
        } else if (parsed is String) {
          goals = parsed.replaceAll(RegExp(r'[\[\]"]'), '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }

    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      phone: json['phone']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? '+91',
      name: json['name']?.toString() ?? 'Diacare User',
      age: int.tryParse(json['age']?.toString() ?? '30') ?? 30,
      gender: json['gender']?.toString() ?? 'Prefer not to say',
      country: json['country']?.toString() ?? 'India',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      heightCm: double.tryParse(json['height_cm']?.toString() ?? '170') ?? 170.0,
      weightKg: double.tryParse(json['weight_kg']?.toString() ?? '70') ?? 70.0,
      activityLevel: json['activity_level']?.toString() ?? 'Moderately Active',
      healthGoals: goals,
      foodPreference: json['food_preference']?.toString() ?? 'Vegetarian',
      allergies: json['allergies']?.toString() ?? '',
      dietaryRestrictions: json['dietary_restrictions']?.toString() ?? '',
      sleepHours: double.tryParse(json['sleep_hours']?.toString() ?? '7.5') ?? 7.5,
      sleepQuality: json['sleep_quality']?.toString() ?? 'Good',
      waterGoalMl: int.tryParse(json['water_goal_ml']?.toString() ?? '2500') ?? 2500,
      stepGoal: int.tryParse(json['step_goal']?.toString() ?? '8000') ?? 8000,
      exerciseGoalMins: int.tryParse(json['exercise_goal_mins']?.toString() ?? '30') ?? 30,
      calorieGoal: int.tryParse(json['calorie_goal']?.toString() ?? '1800') ?? 1800,
      diabetesType: json['diabetes_type']?.toString() ?? 'Type 2 Diabetes',
      diagnosisDate: json['diagnosis_date']?.toString() ?? '',
      durationYears: json['duration_years']?.toString() ?? '',
      familyHistory: json['family_history'] == 1 || json['family_history'] == true || json['family_history'] == '1',
      comorbidities: json['comorbidities']?.toString() ?? '',
      currentFastingGlucose: json['current_fasting_glucose'] != null ? double.tryParse(json['current_fasting_glucose'].toString()) : null,
      currentPostMealGlucose: json['current_post_meal_glucose'] != null ? double.tryParse(json['current_post_meal_glucose'].toString()) : null,
      currentHba1c: json['current_hba1c'] != null ? double.tryParse(json['current_hba1c'].toString()) : null,
      targetGlucoseMin: double.tryParse(json['target_glucose_min']?.toString() ?? '70') ?? 70.0,
      targetGlucoseMax: double.tryParse(json['target_glucose_max']?.toString() ?? '140') ?? 140.0,
    );
  }
}

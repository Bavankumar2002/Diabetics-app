import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diacare/models/user_model.dart';
import 'package:diacare/models/glucose_model.dart';
import 'package:diacare/models/food_model.dart';
import 'package:diacare/models/medication_model.dart';
import 'package:diacare/widgets/glucose_badge.dart';
import 'package:diacare/widgets/nutrient_progress_bar.dart';
import 'package:diacare/widgets/stat_card.dart';
import 'package:diacare/core/constants/colors.dart';

void main() {
  group('Diacare Models Unit Tests', () {
    test('UserModel.fromJson parses complete user profile correctly', () {
      final user = UserModel.fromJson({
        'id': 1,
        'phone': '9876543210',
        'country_code': '+91',
        'name': 'Rahul Sharma',
        'age': 38,
        'gender': 'Male',
        'diabetes_type': 'Type 2 Diabetes',
        'height_cm': 175.0,
        'weight_kg': 74.0,
        'health_goals_list': ['Manage blood sugar', 'Improve nutrition'],
        'target_glucose_min': 70.0,
        'target_glucose_max': 140.0,
      });

      expect(user.id, 1);
      expect(user.name, 'Rahul Sharma');
      expect(user.age, 38);
      expect(user.diabetesType, 'Type 2 Diabetes');
      expect(user.healthGoals.length, 2);
      expect(user.targetGlucoseMin, 70.0);
    });

    test('GlucoseReading.fromJson converts mmol/L accurately', () {
      final reading = GlucoseReading.fromJson({
        'id': 5,
        'reading_value': 126.0,
        'meal_type': 'Fasting',
        'measured_at': '2026-11-13 08:00:00',
        'notes': 'Normal morning test',
        'status': 'normal',
      });

      expect(reading.id, 5);
      expect(reading.readingValue, 126.0);
      expect(reading.mealType, 'Fasting');
      expect(reading.status, 'normal');
      expect((reading.readingMmol * 10).round() / 10, 7.0);
    });

    test('FoodItem.fromJson parses South Indian diabetes food correctly', () {
      final food = FoodItem.fromJson({
        'id': 2,
        'name': 'Ragi Dosa with Mint Chutney',
        'category': 'South Indian',
        'meal_slot': 'Breakfast',
        'serving_size': '1 Medium Dosa',
        'calories': 135.0,
        'protein': 4.2,
        'carbs': 22.0,
        'fat': 2.8,
        'fiber': 5.2,
        'is_diabetes_friendly': 1,
        'diet_type': 'Vegetarian',
        'is_low_carb': 1,
        'is_high_fiber': 1,
      });

      expect(food.name, 'Ragi Dosa with Mint Chutney');
      expect(food.calories, 135.0);
      expect(food.isDiabetesFriendly, true);
      expect(food.isLowCarb, true);
      expect(food.isHighFiber, true);
    });

    test('MedicationItem.fromJson parses dose details correctly', () {
      final med = MedicationItem.fromJson({
        'id': 10,
        'name': 'Metformin',
        'dosage': '500 mg',
        'frequency': 'Twice daily',
        'is_insulin': 0,
        'reminder_time': '08:00 AM',
        'today_status': 'taken',
      });

      expect(med.name, 'Metformin');
      expect(med.dosage, '500 mg');
      expect(med.todayStatus, 'taken');
      expect(med.isInsulin, false);
    });
  });

  group('Diacare Widgets UI Tests', () {
    testWidgets('GlucoseBadge displays correct in-range label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlucoseBadge(status: 'normal'),
          ),
        ),
      );
      expect(find.text('In Target'), findsOneWidget);
    });

    testWidgets('GlucoseBadge displays correct low glucose label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlucoseBadge(status: 'low'),
          ),
        ),
      );
      expect(find.text('Low Glucose'), findsOneWidget);
    });

    testWidgets('NutrientProgressBar renders calories and percentage correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutrientProgressBar(
              label: 'Total Calories',
              consumed: 1200,
              goal: 1800,
              unit: 'kcal',
              progressColor: AppColors.caloriesColor,
            ),
          ),
        ),
      );
      expect(find.text('Total Calories'), findsOneWidget);
      expect(find.text('1200.0 / 1800 kcal (67%)'), findsOneWidget);
    });

    testWidgets('StatCard displays title, value, and subtitle properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Water Hydration',
              value: '1750 ml',
              subtitle: '7 glasses (70%)',
              icon: Icons.water_drop_rounded,
            ),
          ),
        ),
      );
      expect(find.text('Water Hydration'), findsOneWidget);
      expect(find.text('1750 ml'), findsOneWidget);
      expect(find.text('7 glasses (70%)'), findsOneWidget);
    });
  });
}

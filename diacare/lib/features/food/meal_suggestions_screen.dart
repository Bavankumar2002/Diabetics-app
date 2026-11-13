import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/food_provider.dart';
import '../../models/food_model.dart';

class MealSuggestionsScreen extends StatefulWidget {
  const MealSuggestionsScreen({super.key});

  @override
  State<MealSuggestionsScreen> createState() => _MealSuggestionsScreenState();
}

class _MealSuggestionsScreenState extends State<MealSuggestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodProvider>(context, listen: false).fetchMealSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final food = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = food.mealSuggestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabetes-Friendly Meals'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Healthcare Guidance Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        food.suggestionDisclaimer.isNotEmpty
                            ? food.suggestionDisclaimer
                            : 'Curated low glycemic index Indian foods. Always personalize portions and carb counts with your healthcare dietitian.',
                        style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All Diets', food.selectedDietFilter == 'All', () => food.setDietFilter('All')),
                    const SizedBox(width: 8),
                    _filterChip('Vegetarian', food.selectedDietFilter == 'Vegetarian', () => food.setDietFilter('Vegetarian')),
                    const SizedBox(width: 8),
                    _filterChip('Non-Veg', food.selectedDietFilter == 'Non-vegetarian', () => food.setDietFilter('Non-vegetarian')),
                    const SizedBox(width: 8),
                    _filterChip('Low Carb', food.filterLowCarb, () => food.toggleLowCarb()),
                    const SizedBox(width: 8),
                    _filterChip('High Fibre', food.filterHighFiber, () => food.toggleHighFiber()),
                    const SizedBox(width: 8),
                    _filterChip('High Protein', food.filterHighProtein, () => food.toggleHighProtein()),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5 Meal Slot Sections
              _buildSlotSection('Breakfast Suggestions', suggestions['Breakfast'] ?? [], 'Breakfast', isDark),
              _buildSlotSection('Morning Snack Suggestions', suggestions['Morning Snack'] ?? [], 'Morning Snack', isDark),
              _buildSlotSection('Lunch Suggestions', suggestions['Lunch'] ?? [], 'Lunch', isDark),
              _buildSlotSection('Evening Snack Suggestions', suggestions['Evening Snack'] ?? [], 'Evening Snack', isDark),
              _buildSlotSection('Dinner Suggestions', suggestions['Dinner'] ?? [], 'Dinner', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : null,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildSlotSection(String title, List<FoodItem> items, String slotName, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 18, color: AppColors.primary, margin: const EdgeInsets.only(right: 8)),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((food) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primaryDark, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(food.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(food.servingSize, style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.caloriesColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${food.calories.round()} kcal',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.caloriesColor),
                        ),
                      ),
                    ],
                  ),
                  if (food.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(food.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                  const SizedBox(height: 10),
                  // Macro Pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _macroPill('Protein: ${food.protein}g', AppColors.proteinColor),
                      _macroPill('Carbs: ${food.carbs}g', AppColors.carbsColor),
                      _macroPill('Fat: ${food.fat}g', AppColors.fatColor),
                      _macroPill('Fibre: ${food.fiber}g', AppColors.fiberColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text('Log this for $slotName', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final foodProvider = Provider.of<FoodProvider>(context, listen: false);
                        await foodProvider.logFoodItem(
                          mealTime: slotName,
                          foodItemId: food.id,
                          quantity: 1.0,
                          servingSize: food.servingSize,
                          calories: food.calories,
                          protein: food.protein,
                          carbs: food.carbs,
                          fat: food.fat,
                          fiber: food.fiber,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${food.name} to $slotName!'), backgroundColor: AppColors.success),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _macroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

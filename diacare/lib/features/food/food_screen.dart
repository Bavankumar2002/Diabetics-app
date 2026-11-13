import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/food_provider.dart';
import '../../models/food_model.dart';
import '../../widgets/nutrient_progress_bar.dart';
import 'meal_suggestions_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<String> _mealSlots = [
    'Breakfast',
    'Morning Snack',
    'Lunch',
    'Evening Snack',
    'Dinner',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealSlots.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      foodProvider.fetchFoodLogs();
      foodProvider.searchFoods('Idli'); // Pre-populate some popular Indian foods
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddFoodModal(String currentSlot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final foodProvider = Provider.of<FoodProvider>(context);
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add to $currentSlot', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Indian foods (e.g. Idli, Chapati, Dal)...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                foodProvider.searchFoods('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => foodProvider.searchFoods(val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Search Results / Catalog', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Custom Food', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCustomFoodDialog(currentSlot);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  // Search Results List
                  Expanded(
                    child: foodProvider.searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Type above to search from over 25+ diabetes-friendly Indian foods, or add custom.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMutedLight, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: foodProvider.searchResults.length,
                            itemBuilder: (context, index) {
                              final food = foodProvider.searchResults[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.restaurant_rounded, color: AppColors.primaryDark),
                                  ),
                                  title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  subtitle: Text(
                                    '${food.servingSize} • ${food.calories.round()} kcal\nP: ${food.protein}g | C: ${food.carbs}g | F: ${food.fat}g | Fib: ${food.fiber}g',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await foodProvider.logFoodItem(
                                        mealTime: currentSlot,
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
                                          SnackBar(content: Text('Added ${food.name} to $currentSlot'), backgroundColor: AppColors.success),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomFoodDialog(String slot) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final fibCtrl = TextEditingController();
    final servingCtrl = TextEditingController(text: '1 portion');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Custom Food for $slot', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Food Name', hintText: 'e.g. Moong Sprout Bowl')),
                const SizedBox(height: 8),
                TextField(controller: servingCtrl, decoration: const InputDecoration(labelText: 'Serving Size', hintText: 'e.g. 1 Bowl (150g)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: protCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: fibCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fibre (g)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final foodProvider = Provider.of<FoodProvider>(context, listen: false);
                await foodProvider.logFoodItem(
                  mealTime: slot,
                  customName: nameCtrl.text.trim(),
                  quantity: 1.0,
                  servingSize: servingCtrl.text.trim(),
                  calories: double.tryParse(calCtrl.text) ?? 150,
                  protein: double.tryParse(protCtrl.text) ?? 5,
                  carbs: double.tryParse(carbCtrl.text) ?? 20,
                  fat: double.tryParse(fatCtrl.text) ?? 4,
                  fiber: double.tryParse(fibCtrl.text) ?? 3,
                );
              },
              child: const Text('Add Food'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totals = food.dailyTotals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food & Nutrition Tracker'),
        actions: [
          IconButton(
            tooltip: 'Meal Suggestions',
            icon: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MealSuggestionsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Daily Macro Overview Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Nutrition Intake", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.tips_and_updates_rounded, size: 14),
                        label: const Text('Suggestions', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MealSuggestionsScreen()));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  NutrientProgressBar(
                    label: 'Calories',
                    consumed: (totals['calories'] ?? 0).toDouble(),
                    goal: (totals['calorie_goal'] ?? 1800).toDouble(),
                    unit: 'kcal',
                    progressColor: AppColors.caloriesColor,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: NutrientProgressBar(
                          label: 'Protein',
                          consumed: (totals['protein'] ?? 0).toDouble(),
                          goal: (totals['protein_goal'] ?? 80).toDouble(),
                          progressColor: AppColors.proteinColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: NutrientProgressBar(
                          label: 'Carbohydrates',
                          consumed: (totals['carbs'] ?? 0).toDouble(),
                          goal: (totals['carbs_goal'] ?? 180).toDouble(),
                          progressColor: AppColors.carbsColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: NutrientProgressBar(
                          label: 'Fats',
                          consumed: (totals['fat'] ?? 0).toDouble(),
                          goal: (totals['fat_goal'] ?? 60).toDouble(),
                          progressColor: AppColors.fatColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: NutrientProgressBar(
                          label: 'Fibre',
                          consumed: (totals['fiber'] ?? 0).toDouble(),
                          goal: (totals['fiber_goal'] ?? 30).toDouble(),
                          progressColor: AppColors.fiberColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar for 5 Meal Slots
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              tabs: _mealSlots.map((slot) => Tab(text: slot)).toList(),
            ),

            // Tab Content for Each Meal Slot
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _mealSlots.map((slot) {
                  final items = food.loggedSlots[slot] ?? [];

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$slot Items (${items.length})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Food'),
                              onPressed: () => _showAddFoodModal(slot),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.restaurant_outlined, size: 48, color: AppColors.textMutedLight.withOpacity(0.5)),
                                      const SizedBox(height: 12),
                                      Text('No food logged for $slot yet.', style: const TextStyle(color: AppColors.textMutedLight)),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () => _showAddFoodModal(slot),
                                        child: Text('+ Add $slot item', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      child: ListTile(
                                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                          '${item.servingSize} • ${item.calories.round()} kcal\nP: ${item.protein}g | C: ${item.carbs}g | F: ${item.fat}g | Fib: ${item.fiber}g',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                          onPressed: () => food.deleteFoodLog(item.id),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/glucose_provider.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/nutrient_progress_bar.dart';
import '../../widgets/glucose_badge.dart';
import '../glucose/glucose_screen.dart';
import '../food/food_screen.dart';
import '../medication/medication_screen.dart';
import '../activity/activity_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../reports/health_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
    });
  }

  void _showAddGlucoseModal() {
    final valController = TextEditingController();
    final notesController = TextEditingController();
    String mealType = 'Fasting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Log Blood Glucose', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: valController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Glucose Reading Value',
                          hintText: 'e.g. 115',
                          suffixText: 'mg/dL',
                          prefixIcon: Icon(Icons.bloodtype_rounded, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Measurement Timing:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Fasting', 'Before Meal', 'After Meal', 'Bedtime', 'Random'].map((m) {
                          final isSel = mealType == m;
                          return ChoiceChip(
                            label: Text(m),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                            onSelected: (_) => setModalState(() => mealType = m),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'e.g. After 30 min morning walk',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final val = double.tryParse(valController.text);
                          if (val == null || val <= 0) return;
                          final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
                          final glucProvider = Provider.of<GlucoseProvider>(context, listen: false);
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);

                          await glucProvider.addReading(
                            readingValue: val,
                            mealType: mealType,
                            unit: 'mg/dL',
                            measuredAt: DateTime.now(),
                            notes: notesController.text.trim(),
                          );
                          if (!mounted) return;
                          dashProvider.fetchSummary();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Blood glucose logged successfully'), backgroundColor: AppColors.success),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save Reading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _quickAddWater(int ml) async {
    final actProvider = Provider.of<ActivityProvider>(context, listen: false);
    await actProvider.addWater(ml);
    if (!mounted) return;
    Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $ml ml water!'), backgroundColor: AppColors.waterColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = Provider.of<DashboardProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gluc = dash.glucoseSummary;
    final latestGluc = gluc['latest'];
    final nutr = dash.nutritionSummary;
    final water = dash.waterSummary;
    final act = dash.activitySummary;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => dash.fetchSummary(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting, Name, Date, Avatar & Report Shortcut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dash.greeting},',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          dash.userName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dash.todayDate.isNotEmpty ? dash.todayDate : 'Today',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Clinical Health Reports',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.analytics_rounded, color: AppColors.primaryDark, size: 20),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HealthReportScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            dash.userName.isNotEmpty ? dash.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Action Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickActionChip(Icons.add_circle_outline, 'Log Sugar', AppColors.danger, _showAddGlucoseModal),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(Icons.water_drop_outlined, '+250ml Water', AppColors.waterColor, () => _quickAddWater(250)),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(Icons.restaurant_outlined, 'Log Meal', AppColors.primary, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodScreen()));
                      }),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(Icons.medication_outlined, 'Medications', AppColors.purple, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationScreen()));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Blood Glucose Tracking Summary Card
                _buildBloodSugarCard(gluc, latestGluc, isDark),
                const SizedBox(height: 14),

                // 2. Daily Nutrition & Macros Card
                _buildNutritionCard(nutr, isDark),
                const SizedBox(height: 14),

                // 3. Water Tracking & 4. Activity Tracking (2-Column Grid)
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Water Intake',
                        value: '${water['consumed_ml'] ?? 0} ml',
                        subtitle: '${water['glasses'] ?? 0} glasses (${water['percentage'] ?? 0}%)',
                        icon: Icons.water_drop_rounded,
                        iconColor: AppColors.waterColor,
                        trailing: InkWell(
                          onTap: () => _quickAddWater(250),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.waterColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('+250ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.waterColor)),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Daily Steps',
                        value: '${act['steps'] ?? 0}',
                        subtitle: 'Goal: ${act['step_goal'] ?? 8000} (${act['percentage'] ?? 0}%)',
                        icon: Icons.directions_walk_rounded,
                        iconColor: AppColors.success,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Medication Reminders Card
                _buildMedicationsCard(dash.medications, isDark),
                const SizedBox(height: 14),

                // 6. AI Diabetes Assistant Promo Card
                _buildAiAssistantCard(isDark),
                const SizedBox(height: 14),

                // 7. Upcoming Health Reminders Card
                if (dash.reminders.isNotEmpty) ...[
                  _buildRemindersCard(dash.reminders, isDark),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarCard(Map<String, dynamic> gluc, dynamic latestGluc, bool isDark) {
    final status = gluc['status'] ?? 'Normal';
    final targetMin = gluc['target_min'] ?? 70;
    final targetMax = gluc['target_max'] ?? 140;
    final rawVal = latestGluc != null ? latestGluc['reading_value'] : null;
    final String val;
    if (rawVal == null) {
      val = '--';
    } else if (rawVal is num) {
      val = rawVal % 1 == 0 ? rawVal.toInt().toString() : rawVal.toString();
    } else {
      final parsed = double.tryParse(rawVal.toString());
      if (parsed != null) {
        val = parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
      } else {
        val = rawVal.toString();
      }
    }
    final meal = latestGluc != null ? latestGluc['meal_type']?.toString() ?? 'No readings' : 'No readings today';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bloodtype_rounded, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Blood Glucose', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              GlucoseBadge(status: status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                val,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('mg/dL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      meal,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Target: $targetMin - $targetMax mg/dL',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log Reading'),
                  onPressed: _showAddGlucoseModal,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.show_chart_rounded, size: 16, color: Colors.white),
                  label: const Text('View Charts', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GlucoseScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(Map<String, dynamic> nutr, bool isDark) {
    final cals = nutr['calories'] ?? {};
    final consumedCal = (cals['consumed'] ?? 0).toDouble();
    final goalCal = (cals['goal'] ?? 1800).toDouble();

    final prot = nutr['protein'] ?? {};
    final carbs = nutr['carbs'] ?? {};
    final fat = nutr['fat'] ?? {};
    final fib = nutr['fiber'] ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.caloriesColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: AppColors.caloriesColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Daily Nutrition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodScreen()));
                },
                child: const Text('Track Food >', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NutrientProgressBar(
            label: 'Total Calories',
            consumed: consumedCal,
            goal: goalCal,
            unit: 'kcal',
            progressColor: AppColors.caloriesColor,
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: NutrientProgressBar(
                  label: 'Protein',
                  consumed: (prot['consumed'] ?? 0).toDouble(),
                  goal: (prot['goal'] ?? 80).toDouble(),
                  progressColor: AppColors.proteinColor,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NutrientProgressBar(
                  label: 'Carbohydrates',
                  consumed: (carbs['consumed'] ?? 0).toDouble(),
                  goal: (carbs['goal'] ?? 180).toDouble(),
                  progressColor: AppColors.carbsColor,
                  isCompact: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: NutrientProgressBar(
                  label: 'Healthy Fats',
                  consumed: (fat['consumed'] ?? 0).toDouble(),
                  goal: (fat['goal'] ?? 60).toDouble(),
                  progressColor: AppColors.fatColor,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NutrientProgressBar(
                  label: 'Dietary Fibre',
                  consumed: (fib['consumed'] ?? 0).toDouble(),
                  goal: (fib['goal'] ?? 30).toDouble(),
                  progressColor: AppColors.fiberColor,
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsCard(List<dynamic> meds, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppColors.purple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Medication Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationScreen()));
                },
                child: const Text('Manage >', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meds.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No active medications scheduled. Tap Manage to add your prescriptions.', style: TextStyle(fontSize: 13, color: AppColors.textMutedLight)),
            ),
          ] else ...[
            ...meds.map((m) {
              final isTaken = m['today_status'] == 'taken';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isTaken ? AppColors.success : AppColors.textMutedLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${m['name']} (${m['dosage']})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isTaken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Text(m['reminder_time'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAiAssistantCard(bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Diabetes Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 3),
                  Text('Ask questions about Indian meals, blood sugar readings, or exercise safely.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard(List<dynamic> reminders, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Health Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...reminders.take(4).map((r) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(r['reminder_time'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

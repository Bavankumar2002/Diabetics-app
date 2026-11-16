import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../providers/activity_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final act = Provider.of<ActivityProvider>(context, listen: false);
      act.fetchWaterData();
      act.fetchActivityData();
    });
  }

  void _showLogActivityModal() {
    final typeCtrl = TextEditingController(text: 'Walking');
    final stepsCtrl = TextEditingController(text: '2500');
    final durCtrl = TextEditingController(text: '30');

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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Log Physical Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: ['Walking', 'Running', 'Cycling', 'Yoga', 'Gym Workout'].map((t) {
                      final isSel = typeCtrl.text == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                        onSelected: (_) => setModalState(() => typeCtrl.text = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stepsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Steps Count', hintText: 'e.g. 3000'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: durCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Duration (mins)', hintText: 'e.g. 30'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final steps = int.tryParse(stepsCtrl.text) ?? 0;
                      final dur = int.tryParse(durCtrl.text) ?? 20;
                      Navigator.pop(ctx);

                      final act = Provider.of<ActivityProvider>(context, listen: false);
                      await act.logActivity(
                        activityType: typeCtrl.text,
                        steps: steps,
                        durationMins: dur,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Activity recorded successfully'), backgroundColor: AppColors.success),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final act = Provider.of<ActivityProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water & Activity Tracking'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showLogActivityModal,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await act.fetchWaterData();
            await act.fetchActivityData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Water Tracker Card
                _buildWaterCard(act, isDark),
                const SizedBox(height: 18),

                // 2. Activity / Step Counter Card
                _buildActivitySummaryCard(act, isDark),
                const SizedBox(height: 18),

                // 3. Weekly Activity Bar Chart
                _buildWeeklyActivityChart(act, isDark),
                const SizedBox(height: 18),

                // 4. Activity Logs Today
                Text('Today\'s Logged Activities (${act.activities.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (act.activities.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('No workouts or walks logged today.\nTap "+ Log Workout" to add one.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMutedLight)),
                    ),
                  ),
                ] else ...[
                  ...act.activities.map((a) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryDark),
                        ),
                        title: Text(a.activityType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${a.steps} steps • ${a.durationMins} mins • ${a.caloriesBurned} kcal burned', style: const TextStyle(fontSize: 12)),
                        trailing: Text(a.time, style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterCard(ActivityProvider act, bool isDark) {
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
              const Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: AppColors.waterColor, size: 24),
                  SizedBox(width: 8),
                  Text('Water Hydration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.waterColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${act.waterPercentage}% Goal',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.waterColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${act.waterConsumedMl}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.waterColor)),
              const SizedBox(width: 4),
              Text('/ ${act.waterGoalMl} ml (${act.waterGlasses} glasses)', style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: act.waterGoalMl > 0 ? (act.waterConsumedMl / act.waterGoalMl).clamp(0.0, 1.0) : 0,
              minHeight: 10,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.waterColor),
            ),
          ),
          const SizedBox(height: 16),
          // Quick Add Water Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16, color: AppColors.waterColor),
                  label: const Text('+250 ml (1 Cup)', style: TextStyle(color: AppColors.waterColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => act.addWater(250),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.waterColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('+500 ml (Bottle)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => act.addWater(500),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.waterColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummaryCard(ActivityProvider act, bool isDark) {
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
              const Row(
                children: [
                  Icon(Icons.directions_walk_rounded, color: AppColors.success, size: 24),
                  SizedBox(width: 8),
                  Text('Daily Movement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Goal: ${act.stepGoal} steps', style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricColumn('${act.todaySteps}', 'Steps Taken', AppColors.success),
              _metricColumn('${act.todayDurationMins} min', 'Active Time', AppColors.primary),
              _metricColumn('${act.todayCaloriesBurned} kcal', 'Calories Burned', AppColors.caloriesColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
      ],
    );
  }

  Widget _buildWeeklyActivityChart(ActivityProvider act, bool isDark) {
    final history = act.weeklyHistory;
    final bars = <BarChartGroupData>[];

    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      final steps = double.tryParse(item['steps']?.toString() ?? '0') ?? 0;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: steps,
              color: AppColors.primary,
              width: 14,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    if (bars.isEmpty) {
      bars.add(BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 6500, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(6))]));
      bars.add(BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8200, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(6))]));
    }

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
          const Text('Weekly Step Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../providers/glucose_provider.dart';
import '../../models/glucose_model.dart';
import '../../widgets/glucose_badge.dart';

class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({super.key});

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GlucoseProvider>(context, listen: false).fetchReadings();
    });
  }

  void _showAddReadingModal() {
    final valController = TextEditingController();
    final notesController = TextEditingController();
    String mealType = 'Fasting';
    DateTime selectedDateTime = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final glucose = Provider.of<GlucoseProvider>(context);
            final unit = glucose.selectedUnit;

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
                      const Text('Add Blood Glucose Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Glucose Level ($unit)',
                      hintText: unit == 'mg/dL' ? 'e.g. 115' : 'e.g. 6.4',
                      suffixText: unit,
                      prefixIcon: const Icon(Icons.bloodtype_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Measurement Type / Context:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                      labelText: 'Clinical Notes or Symptoms',
                      hintText: 'e.g. Felt slightly dizzy, post 45min walk',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final val = double.tryParse(valController.text);
                      if (val == null || val <= 0) return;
                      Navigator.pop(ctx);

                      await glucose.addReading(
                        readingValue: val,
                        mealType: mealType,
                        unit: unit,
                        measuredAt: selectedDateTime,
                        notes: notesController.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reading saved successfully'), backgroundColor: AppColors.success),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final gluc = Provider.of<GlucoseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = gluc.stats;
    final isMmol = gluc.selectedUnit == 'mmol/L';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Glucose Tracker'),
        actions: [
          // mg/dL <-> mmol/L Toggle
          TextButton(
            onPressed: () => gluc.toggleUnit(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                gluc.selectedUnit,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Reading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddReadingModal,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => gluc.fetchReadings(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector (today, week, month, year)
                Row(
                  children: [
                    _periodButton('Today', 'today', gluc.selectedPeriod, gluc.setPeriod),
                    const SizedBox(width: 8),
                    _periodButton('7 Days', 'week', gluc.selectedPeriod, gluc.setPeriod),
                    const SizedBox(width: 8),
                    _periodButton('30 Days', 'month', gluc.selectedPeriod, gluc.setPeriod),
                    const SizedBox(width: 8),
                    _periodButton('1 Year', 'year', gluc.selectedPeriod, gluc.setPeriod),
                  ],
                ),
                const SizedBox(height: 16),

                // Statistics Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        'Average',
                        isMmol
                            ? '${((stats['average'] ?? 0) / 18.0182).toStringAsFixed(1)}'
                            : '${stats['average'] ?? 0}',
                        gluc.selectedUnit,
                        AppColors.primary,
                      ),
                      _statItem(
                        'In Target',
                        '${stats['in_range_percentage'] ?? 0}%',
                        '${stats['in_range_count'] ?? 0} tests',
                        AppColors.success,
                      ),
                      _statItem(
                        'Highest',
                        isMmol
                            ? '${((stats['highest'] ?? 0) / 18.0182).toStringAsFixed(1)}'
                            : '${stats['highest'] ?? 0}',
                        gluc.selectedUnit,
                        AppColors.danger,
                      ),
                      _statItem(
                        'Lowest',
                        isMmol
                            ? '${((stats['lowest'] ?? 0) / 18.0182).toStringAsFixed(1)}'
                            : '${stats['lowest'] ?? 0}',
                        gluc.selectedUnit,
                        AppColors.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Interactive Glucose Line Chart Card
                _buildGlucoseChartCard(gluc, isDark, isMmol),
                const SizedBox(height: 20),

                // Historical Readings List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Historical Records (${gluc.readings.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Target: ${isMmol ? (gluc.targetMin / 18.0182).toStringAsFixed(1) : gluc.targetMin.round()} - ${isMmol ? (gluc.targetMax / 18.0182).toStringAsFixed(1) : gluc.targetMax.round()} ${gluc.selectedUnit}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Readings List
                if (gluc.readings.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36.0),
                    child: Center(
                      child: Text(
                        'No glucose readings found for this time period.\nTap "Log Reading" below to start tracking.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ] else ...[
                  ...gluc.readings.map((r) {
                    final displayVal = isMmol ? r.readingMmol.toStringAsFixed(1) : r.readingValue.round().toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.bloodtype_rounded,
                              color: r.status == 'low'
                                  ? AppColors.danger
                                  : (r.status == 'high' ? AppColors.warning : AppColors.primary),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              '$displayVal ${gluc.selectedUnit}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            GlucoseBadge(status: r.status),
                          ],
                        ),
                        subtitle: Text(
                          '${r.mealType} • ${r.displayDate}${r.notes.isNotEmpty ? '\n${r.notes}' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                          onPressed: () => gluc.deleteReading(r.id),
                        ),
                      ),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodButton(String label, String value, String current, Function(String) onSelect) {
    final isSel = value == current;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSel ? Colors.white : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildGlucoseChartCard(GlucoseProvider gluc, bool isDark, bool isMmol) {
    final spots = <FlSpot>[];
    final list = gluc.readings.reversed.toList();

    for (int i = 0; i < list.length; i++) {
      final yVal = isMmol ? list[i].readingMmol : list[i].readingValue;
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 100));
      spots.add(const FlSpot(1, 115));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Glucose Trend Curve', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                'Target: 70-140 mg/dL',
                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/pdf_report_service.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  String _timeframe = 'monthly'; // 'weekly', 'monthly', 'annual'
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('${ApiConstants.getAnalytics}?timeframe=$_timeframe');
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _reportData = res['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _exportDoctorPdf() async {
    if (_reportData == null) return;

    final profile = _reportData!['profile'] ?? {};
    final summary = _reportData!['summary'] ?? {};
    final readings = _reportData!['glucose_trends'] ?? [];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating clinical PDF report...')),
    );

    await PdfReportService.generateAndShareDoctorReport(
      patientName: profile['name'] ?? 'Diacare Patient',
      diabetesType: profile['diabetes_type'] ?? 'Type 2 Diabetes',
      age: int.tryParse(profile['age']?.toString() ?? '40') ?? 40,
      gender: profile['gender'] ?? 'Prefer not to say',
      weightKg: double.tryParse(summary['current_weight_kg']?.toString() ?? '70') ?? 70.0,
      avgGlucose: double.tryParse(summary['average_glucose']?.toString() ?? '115') ?? 115.0,
      estimatedHba1c: double.tryParse(summary['estimated_hba1c']?.toString() ?? '6.5') ?? 6.5,
      recordedHba1c: double.tryParse(summary['recorded_hba1c']?.toString() ?? '6.5') ?? 6.5,
      adherenceRate: int.tryParse(summary['medication_adherence_percent']?.toString() ?? '100') ?? 100,
      readings: readings,
      timeframe: _timeframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = _reportData?['summary'] ?? {};
    final glucoseTrends = _reportData?['glucose_trends'] as List? ?? [];
    final nutritionTrends = _reportData?['nutrition_trends'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Health Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export Doctor PDF Report',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            onPressed: _exportDoctorPdf,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeframe Switcher
                    Row(
                      children: [
                        _timeframeButton('7 Days', 'weekly'),
                        const SizedBox(width: 8),
                        _timeframeButton('30 Days', 'monthly'),
                        const SizedBox(width: 8),
                        _timeframeButton('Annual', 'annual'),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Doctor Share Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.8),
                            AppColors.secondaryLight.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.print_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clinical PDF Report for Doctor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                SizedBox(height: 2),
                                Text('Download or print formatted summary for your next endocrinologist visit.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _exportDoctorPdf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Export PDF', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Analytics Summary Tiles
                    Row(
                      children: [
                        _metricTile('Avg Glucose', '${summary['average_glucose'] ?? '--'} mg/dL', 'Target: 70-140', AppColors.primary, isDark),
                        const SizedBox(width: 12),
                        _metricTile('Estimated HbA1c', '${summary['estimated_hba1c'] ?? '--'} %', 'Lab: ${summary['recorded_hba1c'] ?? '--'}%', AppColors.secondary, isDark),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _metricTile('Med Adherence', '${summary['medication_adherence_percent'] ?? 100} %', 'Doses taken on schedule', AppColors.success, isDark),
                        const SizedBox(width: 12),
                        _metricTile('Weight', '${summary['current_weight_kg'] ?? '--'} kg', 'Target in control', AppColors.purple, isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Trend Line Chart
                    Text('Blood Glucose Trend (${_timeframe.toUpperCase()})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildTrendChart(glucoseTrends, isDark),
                    const SizedBox(height: 24),

                    // Nutrition Trends Summary Card
                    Text('Caloric Intake Trend', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildNutritionTrendCard(nutritionTrends, isDark),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _timeframeButton(String label, String value) {
    final isSel = _timeframe == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _timeframe = value);
          _fetchAnalytics();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.primary : AppColors.borderLight),
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

  Widget _metricTile(String title, String val, String sub, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<dynamic> trends, bool isDark) {
    final spots = <FlSpot>[];
    for (int i = 0; i < trends.length; i++) {
      final val = double.tryParse(trends[i]['avg_glucose']?.toString() ?? '110') ?? 110.0;
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 110));
      spots.add(const FlSpot(1, 125));
      spots.add(const FlSpot(2, 118));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5),
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
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionTrendCard(List<dynamic> trends, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: trends.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No nutrition logs in this timeframe.')))
          : Column(
              children: trends.take(5).map((t) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t['logged_date'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${t['calories']} kcal', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.caloriesColor)),
                      Text('P: ${t['protein']}g | C: ${t['carbs']}g', style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

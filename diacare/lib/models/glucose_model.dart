class GlucoseReading {
  final int id;
  final double readingValue; // in mg/dL
  final String mealType; // Fasting, Before Meal, After Meal, Bedtime, Random
  final String unit; // mg/dL or mmol/L
  final DateTime measuredAt;
  final String formattedDate;
  final String displayDate;
  final String notes;
  final String status; // normal, low, high
  final double readingMmol;

  GlucoseReading({
    required this.id,
    required this.readingValue,
    required this.mealType,
    this.unit = 'mg/dL',
    required this.measuredAt,
    required this.formattedDate,
    required this.displayDate,
    this.notes = '',
    this.status = 'normal',
    required this.readingMmol,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    final val = double.tryParse(json['reading_value']?.toString() ?? '100') ?? 100.0;
    final measuredStr = json['measured_at']?.toString() ?? DateTime.now().toIso8601String();
    final dt = DateTime.tryParse(measuredStr) ?? DateTime.now();

    return GlucoseReading(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      readingValue: val,
      mealType: json['meal_type']?.toString() ?? 'Random',
      unit: json['unit']?.toString() ?? 'mg/dL',
      measuredAt: dt,
      formattedDate: json['formatted_date']?.toString() ?? '',
      displayDate: json['display_date']?.toString() ?? '${dt.day}/${dt.month} ${dt.hour}:${dt.minute}',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'normal',
      readingMmol: double.tryParse(json['reading_mmol']?.toString() ?? '') ?? (val / 18.0182),
    );
  }
}

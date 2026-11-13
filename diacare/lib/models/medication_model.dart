class MedicationItem {
  final int id;
  final String name;
  final String dosage;
  final String frequency;
  final bool isInsulin;
  final String? startDate;
  final String? endDate;
  final String reminderTime;
  final String instructions;
  final String todayStatus; // 'taken', 'skipped', 'pending'

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.isInsulin = false,
    this.startDate,
    this.endDate,
    required this.reminderTime,
    this.instructions = '',
    this.todayStatus = 'pending',
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? 'Once daily',
      isInsulin: json['is_insulin'] == 1 || json['is_insulin'] == true || json['is_insulin'] == '1',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      reminderTime: json['reminder_time']?.toString() ?? '08:00 AM',
      instructions: json['instructions']?.toString() ?? '',
      todayStatus: json['today_status']?.toString() ?? 'pending',
    );
  }
}

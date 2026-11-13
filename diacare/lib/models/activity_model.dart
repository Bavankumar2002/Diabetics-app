class ActivityItem {
  final int id;
  final String activityType;
  final int steps;
  final int durationMins;
  final int caloriesBurned;
  final String time;

  ActivityItem({
    required this.id,
    required this.activityType,
    required this.steps,
    required this.durationMins,
    required this.caloriesBurned,
    required this.time,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      activityType: json['activity_type']?.toString() ?? 'Walking',
      steps: int.tryParse(json['steps']?.toString() ?? '0') ?? 0,
      durationMins: int.tryParse(json['duration_mins']?.toString() ?? '0') ?? 0,
      caloriesBurned: int.tryParse(json['calories_burned']?.toString() ?? '0') ?? 0,
      time: json['time']?.toString() ?? '',
    );
  }
}

class WaterLogItem {
  final int id;
  final int amountMl;
  final String time;

  WaterLogItem({
    required this.id,
    required this.amountMl,
    required this.time,
  });

  factory WaterLogItem.fromJson(Map<String, dynamic> json) {
    return WaterLogItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      amountMl: int.tryParse(json['amount_ml']?.toString() ?? '250') ?? 250,
      time: json['time']?.toString() ?? '',
    );
  }
}

class ChatMessage {
  final int? id;
  final String role; // 'user' or 'assistant'
  final String message;
  final String time;
  final bool isEmergency;

  ChatMessage({
    this.id,
    required this.role,
    required this.message,
    required this.time,
    this.isEmergency = false,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      role: json['role']?.toString() ?? 'assistant',
      message: json['message']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isEmergency: json['is_emergency'] == true || json['is_emergency'] == 1,
    );
  }
}

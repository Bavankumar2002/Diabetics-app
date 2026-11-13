import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'welcome_screen.dart';

class RemindersSetupScreen extends StatefulWidget {
  final String userName;

  const RemindersSetupScreen({super.key, required this.userName});

  @override
  State<RemindersSetupScreen> createState() => _RemindersSetupScreenState();
}

class _RemindersSetupScreenState extends State<RemindersSetupScreen> {
  bool _masterNotificationEnabled = true;

  final List<Map<String, dynamic>> _reminderItems = [
    {
      'type': 'medication',
      'title': 'Medication Reminder',
      'time': '08:00 AM',
      'icon': Icons.medication_rounded,
      'enabled': true,
    },
    {
      'type': 'glucose',
      'title': 'Blood Glucose Check',
      'time': '07:30 AM',
      'icon': Icons.bloodtype_rounded,
      'enabled': true,
    },
    {
      'type': 'breakfast',
      'title': 'Breakfast Reminder',
      'time': '08:30 AM',
      'icon': Icons.breakfast_dining_rounded,
      'enabled': true,
    },
    {
      'type': 'lunch',
      'title': 'Lunch Reminder',
      'time': '01:00 PM',
      'icon': Icons.lunch_dining_rounded,
      'enabled': true,
    },
    {
      'type': 'evening_snack',
      'title': 'Evening Snack Reminder',
      'time': '05:00 PM',
      'icon': Icons.bakery_dining_rounded,
      'enabled': true,
    },
    {
      'type': 'dinner',
      'title': 'Dinner Reminder',
      'time': '08:00 PM',
      'icon': Icons.dinner_dining_rounded,
      'enabled': true,
    },
    {
      'type': 'water',
      'title': 'Hydration Water Reminder',
      'time': 'Every 2 Hours',
      'icon': Icons.water_drop_rounded,
      'enabled': true,
    },
    {
      'type': 'exercise',
      'title': 'Exercise & Walk Reminder',
      'time': '06:30 PM',
      'icon': Icons.directions_walk_rounded,
      'enabled': true,
    },
  ];

  Future<void> _pickTime(int index) async {
    final current = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      setState(() {
        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _reminderItems[index]['time'] = '$hour:$minute $period';
      });
    }
  }

  void _onSaveAndContinue() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final list = _reminderItems.map((item) {
      return {
        'type': item['type'],
        'title': item['title'],
        'time': item['time'],
        'enabled': _masterNotificationEnabled ? (item['enabled'] ? 1 : 0) : 0,
      };
    }).toList();

    await auth.saveReminders(list);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WelcomeScreen(userName: widget.userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master Permission Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Notifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Never miss a dose, meal window, or glucose check.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _masterNotificationEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _masterNotificationEnabled = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Individual Health Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the time to change schedule for each reminder.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminders List
                    ...List.generate(_reminderItems.length, (index) {
                      final item = _reminderItems[index];
                      final isEnabled = _masterNotificationEnabled && item['enabled'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isEnabled ? AppColors.primary : AppColors.textMutedLight,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isEnabled
                                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: isEnabled ? () => _pickTime(index) : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isEnabled ? AppColors.primaryLight : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 13,
                                            color: isEnabled ? AppColors.primaryDark : AppColors.textMutedLight,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item['time'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isEnabled ? AppColors.primaryDark : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: item['enabled'] == true,
                              activeColor: AppColors.primary,
                              onChanged: _masterNotificationEnabled
                                  ? (val) => setState(() => item['enabled'] = val)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CustomButton(
                text: 'Save Reminders & Continue',
                onPressed: _onSaveAndContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

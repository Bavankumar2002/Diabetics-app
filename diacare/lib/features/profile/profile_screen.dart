import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../reports/health_report_screen.dart';
import '../onboarding/reminders_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    });
  }

  void _showEditProfileDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final ageCtrl = TextEditingController(text: user?.age.toString() ?? '35');
    final weightCtrl = TextEditingController(text: user?.weightKg.toString() ?? '70');
    final heightCtrl = TextEditingController(text: user?.heightCm.toString() ?? '170');
    final cityCtrl = TextEditingController(text: user?.city ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Personal Vitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 10),
              TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City / Region')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.saveOnboardingProfile({
                'name': nameCtrl.text.trim(),
                'age': int.tryParse(ageCtrl.text) ?? 35,
                'weight_kg': double.tryParse(weightCtrl.text) ?? 70.0,
                'height_cm': double.tryParse(heightCtrl.text) ?? 170.0,
                'city': cityCtrl.text.trim(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of Diacare?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account & Health Records?'),
        content: const Text('This will permanently delete your profile, glucose history, and medication schedule. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.deleteAccount();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.currentUser;

    // Calculate BMI
    double bmi = 0;
    if (user != null && user.heightCm > 0) {
      final hMeters = user.heightCm / 100;
      bmi = user.weightKg / (hMeters * hMeters);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Diacare User',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user?.countryCode} ${user?.phone}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.diabetesType ?? 'Type 2 Diabetes',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vitals Summary Row
              Row(
                children: [
                  _vitalBox('Age', '${user?.age ?? 35} yrs', isDark),
                  const SizedBox(width: 8),
                  _vitalBox('Weight', '${user?.weightKg.round() ?? 70} kg', isDark),
                  const SizedBox(width: 8),
                  _vitalBox('Height', '${user?.heightCm.round() ?? 170} cm', isDark),
                  const SizedBox(width: 8),
                  _vitalBox('BMI', bmi > 0 ? bmi.toStringAsFixed(1) : '--', isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Clinical Diabetes Details Card
              _buildSectionCard('Clinical Details', [
                _infoRow('Diagnosis Date', user?.diagnosisDate.isNotEmpty == true ? user!.diagnosisDate : 'Not specified'),
                _infoRow('Duration', user?.durationYears.isNotEmpty == true ? user!.durationYears : 'Not specified'),
                _infoRow('Family History', user?.familyHistory == true ? 'Yes' : 'No'),
                _infoRow('Other Conditions', user?.comorbidities.isNotEmpty == true ? user!.comorbidities : 'None recorded'),
                _infoRow('Target Glucose', '${user?.targetGlucoseMin.round()} - ${user?.targetGlucoseMax.round()} mg/dL'),
              ], isDark),
              const SizedBox(height: 14),

              // Lifestyle & Preferences Card
              _buildSectionCard('Diet & Lifestyle', [
                _infoRow('Diet Preference', user?.foodPreference ?? 'Vegetarian'),
                _infoRow('Activity Baseline', user?.activityLevel ?? 'Moderately Active'),
                _infoRow('Water Goal', '${user?.waterGoalMl ?? 2500} ml/day'),
                _infoRow('Daily Step Goal', '${user?.stepGoal ?? 8000} steps'),
                _infoRow('Sleep Hours', '${user?.sleepHours ?? 7.5} hrs/night'),
              ], isDark),
              const SizedBox(height: 14),

              // Application & Health Management Settings
              _buildSectionCard('Settings & Reports', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                  title: const Text('Export Doctor Health Report (PDF)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthReportScreen()));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                  title: const Text('Configure Reminder Schedules', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RemindersSetupScreen(userName: user?.name ?? 'User')),
                    );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                  title: const Text('Dark Mode Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: theme.isDarkMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => theme.toggleTheme(),
                ),
              ], isDark),
              const SizedBox(height: 20),

              // Logout & Delete Account Buttons
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _confirmLogout,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _confirmDeleteAccount,
                child: const Text('Delete Account & Clinical Records', style: TextStyle(color: AppColors.textMutedLight, fontSize: 12)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vitalBox(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'reminders_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 15;

  // Form State Values
  // Page 1: Name
  final _nameController = TextEditingController();
  // Page 2: Age
  final _ageController = TextEditingController(text: '35');
  // Page 3: Biological Sex
  String _gender = 'Male';
  // Page 4: Location
  final _countryController = TextEditingController(text: 'India');
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _districtController = TextEditingController(text: 'Mumbai');
  final _cityController = TextEditingController(text: 'Mumbai');
  final _pincodeController = TextEditingController(text: '400001');
  // Page 5: Health Goals
  final List<String> _selectedGoals = ['Manage blood sugar', 'Improve nutrition'];
  final List<String> _availableGoals = [
    'Manage blood sugar',
    'Improve nutrition',
    'Lose weight',
    'Maintain healthy weight',
    'Improve fitness',
    'Monitor diabetes'
  ];
  // Page 6: Activity Level
  String _activityLevel = 'Moderately Active';
  final List<String> _activityLevels = [
    'Sedentary (Little or no exercise)',
    'Lightly Active (1-3 days/week)',
    'Moderately Active (3-5 days/week)',
    'Very Active (6-7 days/week)'
  ];
  // Page 7: Height
  bool _heightInCm = true;
  double _heightCm = 172.0;
  final _feetController = TextEditingController(text: '5');
  final _inchesController = TextEditingController(text: '8');
  final _cmController = TextEditingController(text: '172');
  // Page 8: Weight
  bool _weightInKg = true;
  double _weightKg = 72.0;
  final _weightController = TextEditingController(text: '72');
  // Page 9: Diabetes Info
  String _diabetesType = 'Type 2 Diabetes';
  final List<String> _diabetesTypes = [
    'Type 1 Diabetes',
    'Type 2 Diabetes',
    'Prediabetes',
    'Gestational Diabetes',
    'Not diagnosed',
    'Prefer not to say'
  ];
  // Page 10: History
  final _diagnosisDateController = TextEditingController(text: '2023');
  final _durationController = TextEditingController(text: '3 Years');
  bool _familyHistory = true;
  final _comorbiditiesController = TextEditingController(text: 'Hypertension');
  // Page 11: Blood Sugar Info
  final _fastingController = TextEditingController(text: '115');
  final _postMealController = TextEditingController(text: '155');
  final _hba1cController = TextEditingController(text: '6.8');
  final _lastTestDateController = TextEditingController(text: '2026-10-15');
  // Page 12: Medication Info
  bool _takesMedication = true;
  final _medNameController = TextEditingController(text: 'Metformin');
  final _medDosageController = TextEditingController(text: '500 mg');
  bool _usesInsulin = false;
  final String _medSchedule = '08:00 AM (After Breakfast)';
  // Page 13: Food Preferences
  String _foodPreference = 'Vegetarian';
  final List<String> _foodPreferences = ['Vegetarian', 'Non-vegetarian', 'Vegan', 'Eggetarian'];
  final _allergiesController = TextEditingController(text: 'None');
  final _dietaryRestrictionsController = TextEditingController(text: 'Low refined sugar, low sodium');
  // Page 14: Sleep
  double _sleepHours = 7.5;
  String _sleepQuality = 'Good';
  // Page 15: Daily Health Goals
  int _waterGoal = 2500;
  int _stepGoal = 8000;
  int _exerciseGoal = 30;
  int _calorieGoal = 1800;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _cmController.dispose();
    _weightController.dispose();
    _diagnosisDateController.dispose();
    _durationController.dispose();
    _comorbiditiesController.dispose();
    _fastingController.dispose();
    _postMealController.dispose();
    _hba1cController.dispose();
    _lastTestDateController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    _allergiesController.dispose();
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitOnboarding() async {
    // Calculate final height in cm
    if (!_heightInCm) {
      final ft = double.tryParse(_feetController.text) ?? 5.0;
      final inch = double.tryParse(_inchesController.text) ?? 8.0;
      _heightCm = ((ft * 12) + inch) * 2.54;
    } else {
      _heightCm = double.tryParse(_cmController.text) ?? 172.0;
    }

    // Calculate final weight in kg
    if (!_weightInKg) {
      final lb = double.tryParse(_weightController.text) ?? 150.0;
      _weightKg = lb * 0.453592;
    } else {
      _weightKg = double.tryParse(_weightController.text) ?? 72.0;
    }

    final data = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 35,
      'gender': _gender,
      'country': _countryController.text.trim(),
      'state': _stateController.text.trim(),
      'district': _districtController.text.trim(),
      'city': _cityController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'height_cm': _heightCm,
      'weight_kg': _weightKg,
      'activity_level': _activityLevel,
      'health_goals': _selectedGoals,
      'food_preference': _foodPreference,
      'allergies': _allergiesController.text.trim(),
      'dietary_restrictions': _dietaryRestrictionsController.text.trim(),
      'sleep_hours': _sleepHours,
      'sleep_quality': _sleepQuality,
      'water_goal_ml': _waterGoal,
      'step_goal': _stepGoal,
      'exercise_goal_mins': _exerciseGoal,
      'calorie_goal': _calorieGoal,
      'diabetes_type': _diabetesType,
      'diagnosis_date': _diagnosisDateController.text.trim(),
      'duration_years': _durationController.text.trim(),
      'family_history': _familyHistory ? 1 : 0,
      'comorbidities': _comorbiditiesController.text.trim(),
      'current_fasting_glucose': _fastingController.text.isNotEmpty ? double.tryParse(_fastingController.text) : null,
      'current_post_meal_glucose': _postMealController.text.isNotEmpty ? double.tryParse(_postMealController.text) : null,
      'current_hba1c': _hba1cController.text.isNotEmpty ? double.tryParse(_hba1cController.text) : null,
      'last_hba1c_date': _lastTestDateController.text.isNotEmpty ? _lastTestDateController.text.trim() : null,
      'medication_name': _takesMedication ? _medNameController.text.trim() : '',
      'medication_dosage': _takesMedication ? _medDosageController.text.trim() : '',
      'medication_schedule': _takesMedication ? _medSchedule : '',
      'insulin_usage': _usesInsulin ? 1 : 0,
    };

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.saveOnboardingProfile(data);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RemindersSetupScreen(userName: _nameController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to save onboarding data'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_currentPage + 1) / _totalPages;

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _previousPage,
              )
            : null,
        title: Text(
          'Step ${_currentPage + 1} of $_totalPages',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _currentPage == _totalPages - 1 ? _submitOnboarding : _nextPage,
            child: Text(
              _currentPage == _totalPages - 1 ? 'Finish' : 'Skip',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Enforce step buttons
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage1Name(isDark),
                  _buildPage2Age(isDark),
                  _buildPage3Gender(isDark),
                  _buildPage4Location(isDark),
                  _buildPage5HealthGoals(isDark),
                  _buildPage6ActivityLevel(isDark),
                  _buildPage7Height(isDark),
                  _buildPage8Weight(isDark),
                  _buildPage9DiabetesType(isDark),
                  _buildPage10DiabetesHistory(isDark),
                  _buildPage11BloodSugar(isDark),
                  _buildPage12Medication(isDark),
                  _buildPage13FoodPreferences(isDark),
                  _buildPage14Sleep(isDark),
                  _buildPage15DailyGoals(isDark),
                ],
              ),
            ),
            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Back',
                        isOutlined: true,
                        onPressed: _previousPage,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return CustomButton(
                          text: _currentPage == _totalPages - 1 ? 'Complete Setup' : 'Continue',
                          isLoading: auth.isLoading,
                          onPressed: _nextPage,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 15 INDIVIDUAL STEP PAGES ---

  Widget _buildStepHeader(String title, String subtitle, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // Page 1 – Name
  Widget _buildPage1Name(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('What is your name?', 'Diacare personalizes your diabetes care plan for you.', Icons.person_rounded, isDark),
          TextFormField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Rahul Sharma',
              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Page 2 – Age
  Widget _buildPage2Age(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader("What's your age?", 'Age is crucial for calculating glycemic target curves and metabolism.', Icons.cake_rounded, isDark),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Age (in years)',
              hintText: 'e.g. 42',
              prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Page 3 – Biological Sex
  Widget _buildPage3Gender(bool isDark) {
    final options = ['Male', 'Female', 'Prefer not to say'];
    final icons = [Icons.male_rounded, Icons.female_rounded, Icons.transgender_rounded];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader("What's your biological sex?", 'Affects hormonal insulin resistance and body fat benchmarks.', Icons.wc_rounded, isDark),
          ...List.generate(options.length, (index) {
            final opt = options[index];
            final isSelected = _gender == opt;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(icons[index], color: isSelected ? AppColors.primary : AppColors.textSecondaryLight),
                title: Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () => setState(() => _gender = opt),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 4 – Location
  Widget _buildPage4Location(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Where are you from?', 'Enables regional Indian dietary suggestions and local climate hydration goals.', Icons.location_on_rounded, isDark),
          TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(labelText: 'Country', prefixIcon: Icon(Icons.public, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _stateController,
            decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_rounded, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _districtController,
            decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.navigation_rounded, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_rounded, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Page 5 – Health Goals
  Widget _buildPage5HealthGoals(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('What are you looking for?', 'Select one or more goals to calibrate your daily health targets.', Icons.flag_rounded, isDark),
          ..._availableGoals.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                activeColor: AppColors.primary,
                title: Text(goal, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedGoals.add(goal);
                    } else {
                      _selectedGoals.remove(goal);
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 6 – Activity Level
  Widget _buildPage6ActivityLevel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('How active are you?', 'Determines daily carbohydrate burning capacity and caloric baseline.', Icons.directions_run_rounded, isDark),
          ..._activityLevels.map((lvl) {
            final shortName = lvl.split(' (')[0];
            final isSelected = _activityLevel == shortName;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(shortName, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600)),
                subtitle: Text(lvl.contains('(') ? lvl.split('(')[1].replaceAll(')', '') : ''),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () => setState(() => _activityLevel = shortName),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 7 – Height
  Widget _buildPage7Height(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('How tall are you?', 'Essential for computing BMI and healthy body weight ranges.', Icons.height_rounded, isDark),
          // Unit Switcher
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _unitButton('Centimeters (cm)', _heightInCm, () {
                    if (!_heightInCm) {
                      final ft = double.tryParse(_feetController.text) ?? 5;
                      final inch = double.tryParse(_inchesController.text) ?? 8;
                      _cmController.text = (((ft * 12) + inch) * 2.54).round().toString();
                      setState(() => _heightInCm = true);
                    }
                  }),
                  _unitButton('Feet & Inches', !_heightInCm, () {
                    if (_heightInCm) {
                      final cm = double.tryParse(_cmController.text) ?? 172;
                      final totalInches = cm / 2.54;
                      _feetController.text = (totalInches ~/ 12).toString();
                      _inchesController.text = (totalInches % 12).round().toString();
                      setState(() => _heightInCm = false);
                    }
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_heightInCm) ...[
            TextFormField(
              controller: _cmController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Height in cm',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.straighten_rounded, color: AppColors.primary),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _feetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Feet', suffixText: 'ft'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _inchesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Inches', suffixText: 'in'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Page 8 – Weight
  Widget _buildPage8Weight(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader("What's your current weight?", 'Weight tracking directly correlates with insulin sensitivity improvement.', Icons.monitor_weight_rounded, isDark),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _unitButton('Kilograms (kg)', _weightInKg, () {
                    if (!_weightInKg) {
                      final lb = double.tryParse(_weightController.text) ?? 150;
                      _weightController.text = (lb * 0.453592).round().toString();
                      setState(() => _weightInKg = true);
                    }
                  }),
                  _unitButton('Pounds (lb)', !_weightInKg, () {
                    if (_weightInKg) {
                      final kg = double.tryParse(_weightController.text) ?? 70;
                      _weightController.text = (kg / 0.453592).round().toString();
                      setState(() => _weightInKg = false);
                    }
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: _weightInKg ? 'Weight in kg' : 'Weight in lb',
              suffixText: _weightInKg ? 'kg' : 'lb',
              prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Page 9 – Diabetes Type
  Widget _buildPage9DiabetesType(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Do you have diabetes?', 'Select your diagnosis category so Diacare adjusts clinical thresholds.', Icons.bloodtype_rounded, isDark),
          ..._diabetesTypes.map((type) {
            final isSelected = _diabetesType == type;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(type, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () => setState(() => _diabetesType = type),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 10 – Diabetes History
  Widget _buildPage10DiabetesHistory(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Diabetes History', 'Helps build your clinical health record.', Icons.history_edu_rounded, isDark),
          TextFormField(
            controller: _diagnosisDateController,
            decoration: const InputDecoration(labelText: 'When were you diagnosed? (Year)', hintText: 'e.g. 2021', prefixIcon: Icon(Icons.event, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _durationController,
            decoration: const InputDecoration(labelText: 'How long have you had diabetes?', hintText: 'e.g. 3 years', prefixIcon: Icon(Icons.timelapse, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Family history of diabetes?', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Parent, sibling, or grandparent with diabetes'),
            value: _familyHistory,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _familyHistory = val),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _comorbiditiesController,
            decoration: const InputDecoration(labelText: 'Other health conditions (if any)', hintText: 'e.g. Hypertension, Thyroid, Cholesterol', prefixIcon: Icon(Icons.medical_information, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Page 11 – Blood Sugar Information
  Widget _buildPage11BloodSugar(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Blood Sugar Information', 'Enter your recent test values (leave blank or skip if unknown).', Icons.opacity_rounded, isDark),
          TextFormField(
            controller: _fastingController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Current Fasting Glucose (mg/dL)', hintText: 'e.g. 110', suffixText: 'mg/dL'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _postMealController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Post-Meal Glucose (mg/dL)', hintText: 'e.g. 150', suffixText: 'mg/dL'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hba1cController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Recent HbA1c Level (%)', hintText: 'e.g. 6.8', suffixText: '%'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastTestDateController,
            decoration: const InputDecoration(labelText: 'Last HbA1c Test Date', hintText: 'YYYY-MM-DD'),
          ),
        ],
      ),
    );
  }

  // Page 12 – Medication Information
  Widget _buildPage12Medication(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Medication Information', 'Enable automated dose tracking and reminders.', Icons.medication_rounded, isDark),
          SwitchListTile(
            title: const Text('Are you currently taking diabetes medication?', style: TextStyle(fontWeight: FontWeight.w600)),
            value: _takesMedication,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _takesMedication = val),
          ),
          if (_takesMedication) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _medNameController,
              decoration: const InputDecoration(labelText: 'Medication Name', hintText: 'e.g. Metformin / Glimepiride'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medDosageController,
              decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 500 mg'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Do you use Insulin injections?', style: TextStyle(fontWeight: FontWeight.w600)),
              value: _usesInsulin,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _usesInsulin = val),
            ),
          ],
        ],
      ),
    );
  }

  // Page 13 – Food Preferences
  Widget _buildPage13FoodPreferences(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Food Preferences', 'Diacare customizes delicious Indian low-GI meals based on your palate.', Icons.restaurant_menu_rounded, isDark),
          ..._foodPreferences.map((pref) {
            final isSelected = _foodPreference == pref;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                title: Text(pref, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () => setState(() => _foodPreference = pref),
              ),
            );
          }),
          const SizedBox(height: 14),
          TextFormField(
            controller: _allergiesController,
            decoration: const InputDecoration(labelText: 'Food Allergies (e.g. Peanuts, Gluten)', hintText: 'None'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dietaryRestrictionsController,
            decoration: const InputDecoration(labelText: 'Dietary Restrictions', hintText: 'e.g. Low sodium, Jain'),
          ),
        ],
      ),
    );
  }

  // Page 14 – Sleep Information
  Widget _buildPage14Sleep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Sleep & Recovery', 'Poor sleep directly increases morning cortisol and insulin resistance.', Icons.bedtime_rounded, isDark),
          Text(
            'Average Sleeping Hours: ${_sleepHours.toStringAsFixed(1)} hours/night',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _sleepHours,
            min: 4,
            max: 12,
            divisions: 16,
            activeColor: AppColors.primary,
            label: '${_sleepHours.toStringAsFixed(1)} hrs',
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          const SizedBox(height: 20),
          Text(
            'Sleep Quality',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Poor', 'Fair', 'Good', 'Excellent'].map((sq) {
              final isSel = _sleepQuality == sq;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(sq),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSel ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    onSelected: (val) => setState(() => _sleepQuality = sq),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Page 15 – Daily Health Goals
  Widget _buildPage15DailyGoals(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Daily Health Goals', 'Final step! Set realistic daily targets for optimal diabetes management.', Icons.track_changes_rounded, isDark),
          _goalSlider('Daily Water Intake', '$_waterGoal ml (${(_waterGoal / 250).toStringAsFixed(0)} glasses)', _waterGoal.toDouble(), 1000, 4500, (v) => setState(() => _waterGoal = v.round())),
          _goalSlider('Daily Step Goal', '$_stepGoal steps', _stepGoal.toDouble(), 3000, 20000, (v) => setState(() => _stepGoal = v.round())),
          _goalSlider('Exercise Goal', '$_exerciseGoal minutes/day', _exerciseGoal.toDouble(), 10, 120, (v) => setState(() => _exerciseGoal = v.round())),
          _goalSlider('Calorie Goal', '$_calorieGoal kcal/day', _calorieGoal.toDouble(), 1200, 3200, (v) => setState(() => _calorieGoal = v.round())),
        ],
      ),
    );
  }

  Widget _goalSlider(String title, String valText, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(valText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _unitButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

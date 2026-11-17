import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+91';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA / Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
    {'code': '+65', 'country': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showServerConfigModal() {
    final hostCtrl = TextEditingController(text: ApiConstants.serverHost);
    bool testing = false;
    String? statusMsg;
    bool? testSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          const Row(
                            children: [
                              Icon(Icons.dns_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Backend Server Host', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ensure smartphone and PC are connected to the same Wi-Fi router. Enter your PC IP below:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: hostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Server Host / IP',
                          hintText: '192.168.1.49',
                          prefixIcon: Icon(Icons.wifi_rounded, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('192.168.1.49 (PC Wi-Fi)'),
                            onPressed: () => setModalState(() => hostCtrl.text = '192.168.1.49'),
                          ),
                          ActionChip(
                            label: const Text('10.0.2.2 (Emulator)'),
                            onPressed: () => setModalState(() => hostCtrl.text = '10.0.2.2'),
                          ),
                          ActionChip(
                            label: const Text('localhost (Web)'),
                            onPressed: () => setModalState(() => hostCtrl.text = 'localhost'),
                          ),
                        ],
                      ),
                      if (statusMsg != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                              color: testSuccess == true ? AppColors.success : AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusMsg!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: testSuccess == true ? AppColors.success : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: testing
                            ? null
                            : () async {
                                final target = hostCtrl.text.trim();
                                if (target.isEmpty) return;
                                setModalState(() {
                                  testing = true;
                                  statusMsg = 'Testing connection to http://$target/diabetics_app/backend...';
                                  testSuccess = null;
                                });

                                final ok = await ApiService.testConnection(target);
                                await ApiService.saveServerHost(target);

                                setModalState(() {
                                  testing = false;
                                  testSuccess = ok;
                                  statusMsg = ok
                                      ? 'Connected successfully to backend!'
                                      : 'Could not reach http://$target/diabetics_app/backend. Verify PC IP & Apache.';
                                });

                                if (ok) {
                                  Future.delayed(const Duration(milliseconds: 900), () {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: testing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save & Test Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.sendOtp(phone, countryCode: _selectedCountryCode);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $_selectedCountryCode $phone'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: phone,
            countryCode: _selectedCountryCode,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: AppColors.danger,
          action: SnackBarAction(
            label: 'Server IP',
            textColor: Colors.white,
            onPressed: _showServerConfigModal,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_ethernet_rounded, color: AppColors.primary),
                      tooltip: 'Server Connection Settings',
                      onPressed: _showServerConfigModal,
                    ),
                  ],
                ),
                // Logo & Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Welcome to Diacare',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or register with your mobile number to manage your diabetes with intelligent care.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                // Country Code & Phone Input Card
                Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code Dropdown
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                          items: _countryCodes.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['code'],
                              child: Row(
                                children: [
                                  Text(item['flag']!, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    item['code']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCountryCode = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Phone Number Input
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Enter 10-digit number',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Send OTP Button
                CustomButton(
                  text: 'Send OTP Code',
                  icon: Icons.send_rounded,
                  isLoading: auth.isLoading,
                  onPressed: _onSendOtp,
                ),
                const SizedBox(height: 24),

                // Privacy & Terms Disclaimer
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service & Privacy Policy.\nYour health data is encrypted and HIPAA compliant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

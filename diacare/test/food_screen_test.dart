import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:diacare/providers/theme_provider.dart';
import 'package:diacare/providers/auth_provider.dart';
import 'package:diacare/providers/dashboard_provider.dart';
import 'package:diacare/providers/glucose_provider.dart';
import 'package:diacare/providers/food_provider.dart';
import 'package:diacare/providers/medication_provider.dart';
import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/chat_provider.dart';
import 'package:diacare/features/navigation/main_bottom_nav.dart';

void main() {
  testWidgets('MainBottomNav tab 1 renders FoodScreen properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => GlucoseProvider()),
          ChangeNotifierProvider(create: (_) => FoodProvider()),
          ChangeNotifierProvider(create: (_) => MedicationProvider()),
          ChangeNotifierProvider(create: (_) => ActivityProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const MaterialApp(
          home: MainBottomNav(initialIndex: 1),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Food & Nutrition Tracker'), findsOneWidget);
    expect(find.text("Today's Nutrition Intake"), findsOneWidget);
  });
}

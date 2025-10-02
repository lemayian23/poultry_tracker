import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/batch.dart';
import 'models/daily_record.dart';
import 'models/vaccination.dart';
import 'models/subscription.dart';
import 'screens/subscription_plans_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/batch_list_screen.dart';
import 'screens/batch_detail_screen.dart';
import 'screens/vaccination_screen.dart';
import 'screens/mpesa_payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(BatchAdapter());
  Hive.registerAdapter(DailyRecordAdapter());
  Hive.registerAdapter(VaccinationAdapter());
  Hive.registerAdapter(SubscriptionAdapter());

  // Open boxes
  await Hive.openBox<Batch>('batches');
  await Hive.openBox<DailyRecord>('records');
  await Hive.openBox<Vaccination>('vaccinations');
  await Hive.openBox<Subscription>('subscriptions');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poultry Manager',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(), // Changed to Dashboard as main screen
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/batches': (context) => const BatchListScreen(),
        '/subscription': (context) => const SubscriptionPlansScreen(userId: 'demo_user'),
      },
      // Fallback for unknown routes
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        );
      },
    );
  }
}
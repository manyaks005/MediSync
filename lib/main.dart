import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'screens/registerpage.dart';
import 'screens/alarm_ring_page.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.init();
  await Alarm.init();

  // Listen for alarm ringing
  Alarm.ringStream.stream.listen((alarmSettings) async {
    final alarmId = alarmSettings.id;

    String medicineName = "Medicine Reminder";
    String medicineId = "";
    String mealType = "";

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final remindersSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("reminders")
          .get();

      for (final doc in remindersSnapshot.docs) {
        final data = doc.data();

        if (data["morning_alarm_id"] == alarmId ||
            data["afternoon_alarm_id"] == alarmId ||
            data["night_alarm_id"] == alarmId) {
          medicineName = data["medicine_name"] ?? "Medicine";
          medicineId = data["medicine_id"] ?? "";
          mealType = data["meal_type"] ?? "";

          break;
        }
      }
    }
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AlarmRingPage(
          alarmId: alarmSettings.id,
          medicineName: medicineName,
          medicineId: medicineId,
          mealTime: mealType,
        ),
      ),
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MediSync',
      home: const SplashScreen(),
    );
  }
}

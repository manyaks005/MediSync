import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmRingPage extends StatelessWidget {
  final int alarmId;
  final String medicineName;
  final String medicineId;
  final String mealTime;

  const AlarmRingPage({
    super.key,
    required this.alarmId,
    required this.medicineName,
    required this.medicineId,
    required this.mealTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff4B00B5), Color(0xff6E5BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Title
                const Icon(Icons.alarm, color: Colors.white70),

                const SizedBox(height: 10),

                const Text(
                  "SCHEDULED DOSE",
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "TIME FOR\n${medicineName.toUpperCase()}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.1,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  mealTime,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),

                const SizedBox(height: 45),

                // Medicine circle
                Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 229, 221, 221),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Dose
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 109, 169, 158),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Take your medicine",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 28, 27, 27),
                    ),
                  ),
                ),
                const SizedBox(height: 45),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      "Take Now",
                      style: TextStyle(fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff8EF5E2),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () async {
                      await Alarm.stop(alarmId);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),

                // Bottom buttons
                const SizedBox(height: 20),
                // Info Cards
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        icon: Icons.medication,
                        title: "TYPE",
                        value: "TABLET",
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: _infoCard(
                        icon: Icons.restaurant,
                        title: "MEAL",
                        value: mealTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Take now button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xff8EF5E2)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

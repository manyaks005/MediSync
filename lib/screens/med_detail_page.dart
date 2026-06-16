import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mediscan/screens/homepage.dart';
import 'package:mediscan/screens/medicinelist_page.dart';
import 'package:alarm/alarm.dart';

class MedicineDetailsPage extends StatelessWidget {
  final String medicineId;

  const MedicineDetailsPage({super.key, required this.medicineId});

  Future<void> deleteMedicine(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Get reminders connected to this medicine
      final reminderSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("reminders")
          .where("medicine_id", isEqualTo: medicineId)
          .get();

      // Stop alarms and delete reminders
      for (var doc in reminderSnapshot.docs) {
        final data = doc.data();

        // Stop morning alarm
        if (data["morning_alarm_id"] != null) {
          await Alarm.stop(data["morning_alarm_id"]);
        }

        // Stop afternoon alarm
        if (data["afternoon_alarm_id"] != null) {
          await Alarm.stop(data["afternoon_alarm_id"]);
        }

        // Stop night alarm
        if (data["night_alarm_id"] != null) {
          await Alarm.stop(data["night_alarm_id"]);
        }

        // Delete reminder document
        await doc.reference.delete();
      }

      // Delete the medicine document
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("medicines")
          .doc(medicineId)
          .delete();

      if (!context.mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting medicine: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MedicineListPage()),
            );
          },
        ),

        title: const Text(
          "Medicine Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Column(
                    children: const [
                      Text("Delete Medicine?", textAlign: TextAlign.center),
                    ],
                  ),
                  content: const Text(
                    "This medicine and its details will be permanently removed from your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete"),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        deleteMedicine(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("medicines")
            .doc(medicineId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Medicine not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBB99FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["name"] ?? "Unknown",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildCard(
                  "Strength",
                  data["strength"],
                  Icons.bolt,
                  const Color(0xFF0D9488),
                ),
                _buildCard(
                  "Dosage Form",
                  data["dosage_form"],
                  Icons.category,
                  const Color(0xFF6D28D9),
                ),
                _buildCard(
                  "Expiry Date",
                  data["expiry_date"],
                  Icons.calendar_today,
                  const Color(0xFF0D9488),
                ),
                _buildCard(
                  "Tablets",
                  data["number_of_tablets"],
                  Icons.medication,
                  const Color(0xFF6D28D9),
                ),
                _buildCard(
                  "Uses",
                  data["uses"],
                  Icons.healing,
                  const Color(0xFF0D9488),
                ),
                _buildCard(
                  "Side Effects",
                  data["side_effects"],
                  Icons.warning,
                  Colors.redAccent,
                ),

                const SizedBox(height: 10),

                // 📌 Instructions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6D28D9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Instructions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data["instructions"] ?? "-"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(value?.toString() ?? "-"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

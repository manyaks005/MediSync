import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediscan/screens/homepage.dart';
import 'package:mediscan/screens/med_detail_page.dart';
import 'package:mediscan/screens/scan_page.dart';
import '../services/alarm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  String morningMealType = "Before Food";
  String afternoonMealType = "Before Food";
  String nightMealType = "Before Food";
  String? selectedMedicineName;
  String? selectedMedicineId;

  bool morningEnabled = true;
  bool afternoonEnabled = false;
  bool nightEnabled = false;

  bool isDaily = false;

  TimeOfDay morningTime = const TimeOfDay(hour: 8, minute: 0);

  TimeOfDay afternoonTime = const TimeOfDay(hour: 13, minute: 0);

  TimeOfDay nightTime = const TimeOfDay(hour: 21, minute: 0);

  String mealType = "Before Food";

  Future<void> pickTime(
    TimeOfDay currentTime,
    Function(TimeOfDay) onSelected,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (time != null) {
      setState(() {
        onSelected(time);
      });
    }
  }

  DateTime convertToDateTime(TimeOfDay time) {
    final now = DateTime.now();

    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> saveReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please sign in first")));
        return;
      }

      if (selectedMedicineName == null || selectedMedicineId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a medicine")),
        );
        return;
      }

      if (!morningEnabled && !afternoonEnabled && !nightEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select at least one reminder")),
        );
        return;
      }

      final baseId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Morning Alarm
      if (morningEnabled) {
        await AlarmService.setMedicineAlarm(
          id: baseId + 1,
          medicineName: selectedMedicineName!,
          dateTime: convertToDateTime(morningTime),
        );
      }

      // Afternoon Alarm
      if (afternoonEnabled) {
        await AlarmService.setMedicineAlarm(
          id: baseId + 2,
          medicineName: selectedMedicineName!,
          dateTime: convertToDateTime(afternoonTime),
        );
      }

      // Night Alarm
      if (nightEnabled) {
        await AlarmService.setMedicineAlarm(
          id: baseId + 3,
          medicineName: selectedMedicineName!,
          dateTime: convertToDateTime(nightTime),
        );
      }
      final reminderRef = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("reminders")
          .add({
            "userId": user.uid,
            "medicine_name": selectedMedicineName,
            "medicine_id": selectedMedicineId,

            "morning_enabled": morningEnabled,
            "morning_time": "${morningTime.hour}:${morningTime.minute}",
            "morning_alarm_id": baseId + 1,

            "afternoon_enabled": afternoonEnabled,
            "afternoon_time": "${afternoonTime.hour}:${afternoonTime.minute}",
            "afternoon_alarm_id": baseId + 2,

            "night_enabled": nightEnabled,
            "night_time": "${nightTime.hour}:${nightTime.minute}",
            "night_alarm_id": baseId + 3,

            "meal_type": mealType,
            "createdAt": Timestamp.now(),
            "isDaily": isDaily,
          });

      await reminderRef.update({"reminder_id": reminderRef.id});

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder Saved Successfully")),
      );
    } catch (e) {
      debugPrint("Reminder Save Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(title),
      subtitle: Text(time.format(context)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),

        title: const Text(
          "Set Medicine Reminder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Medicine",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 250,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection("medicines")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No medicines found"));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: selectedMedicineId == doc.id
                              ? const Color(0xFFEDE8FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selectedMedicineId == doc.id
                                ? Colors.deepPurple
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade50,
                            child: const Icon(
                              Icons.medication,
                              color: Colors.deepPurple,
                            ),
                          ),
                          title: Text(data["name"] ?? "Unknown"),

                          trailing: selectedMedicineId == doc.id
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              selectedMedicineId = doc.id;
                              selectedMedicineName = data["name"];
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text("Morning"),
              subtitle: Text(morningTime.format(context)),
              value: morningEnabled,
              onChanged: (value) {
                setState(() {
                  morningEnabled = value;
                });
              },
            ),

            if (morningEnabled) ...[
              buildTimeTile(
                title: "Morning Time",
                time: morningTime,
                onTap: () =>
                    pickTime(morningTime, (time) => morningTime = time),
              ),

              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text("Before Food"),
                    selected: morningMealType == "Before Food",
                    onSelected: (_) {
                      setState(() {
                        morningMealType = "Before Food";
                      });
                    },
                  ),

                  ChoiceChip(
                    label: const Text("After Food"),
                    selected: morningMealType == "After Food",
                    onSelected: (_) {
                      setState(() {
                        morningMealType = "After Food";
                      });
                    },
                  ),
                ],
              ),
            ],
            SwitchListTile(
              title: const Text("Afternoon"),
              subtitle: Text(afternoonTime.format(context)),
              value: afternoonEnabled,
              onChanged: (value) {
                setState(() {
                  afternoonEnabled = value;
                });
              },
            ),

            if (afternoonEnabled) ...[
              buildTimeTile(
                title: "Afternoon Time",
                time: afternoonTime,
                onTap: () =>
                    pickTime(afternoonTime, (time) => afternoonTime = time),
              ),

              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text("Before Food"),
                    selected: afternoonMealType == "Before Food",
                    onSelected: (_) {
                      setState(() {
                        afternoonMealType = "Before Food";
                      });
                    },
                  ),

                  ChoiceChip(
                    label: const Text("After Food"),
                    selected: afternoonMealType == "After Food",
                    onSelected: (_) {
                      setState(() {
                        afternoonMealType = "After Food";
                      });
                    },
                  ),
                ],
              ),
            ],
            SwitchListTile(
              title: const Text("Night"),
              subtitle: Text(nightTime.format(context)),
              value: nightEnabled,
              onChanged: (value) {
                setState(() {
                  nightEnabled = value;
                });
              },
            ),

            if (nightEnabled) ...[
              buildTimeTile(
                title: "Night Time",
                time: nightTime,
                onTap: () => pickTime(nightTime, (time) => nightTime = time),
              ),

              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text("Before Food"),
                    selected: nightMealType == "Before Food",
                    onSelected: (_) {
                      setState(() {
                        nightMealType = "Before Food";
                      });
                    },
                  ),

                  ChoiceChip(
                    label: const Text("After Food"),
                    selected: nightMealType == "After Food",
                    onSelected: (_) {
                      setState(() {
                        nightMealType = "After Food";
                      });
                    },
                  ),
                ],
              ),
            ],

            const Divider(),
            SwitchListTile(
              title: const Text("Repeat Daily"),
              subtitle: const Text("Turn on for everyday reminder"),
              value: isDaily,
              onChanged: (value) {
                setState(() {
                  isDaily = value;
                });
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: saveReminder,
                child: const Text(
                  "Save Reminder",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

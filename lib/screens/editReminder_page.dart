import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mediscan/screens/homepage.dart';
import 'package:mediscan/services/alarm_service.dart';

class EditReminderPage extends StatefulWidget {
  final String reminderId;
  final Map<String, dynamic> reminderData;

  const EditReminderPage({
    super.key,
    required this.reminderId,
    required this.reminderData,
  });

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  late bool morningEnabled;
  late bool afternoonEnabled;
  late bool nightEnabled;

  late TimeOfDay morningTime;
  late TimeOfDay afternoonTime;
  late TimeOfDay nightTime;

  TimeOfDay parseTime(String time) {
    final parts = time.split(":");

    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  late String mealType;

  bool isDaily = true;
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

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
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
  @override
  void initState() {
    super.initState();

    morningEnabled = widget.reminderData["morning_enabled"] ?? false;

    afternoonEnabled = widget.reminderData["afternoon_enabled"] ?? false;

    nightEnabled = widget.reminderData["night_enabled"] ?? false;

    morningTime = parseTime(widget.reminderData["morning_time"] ?? "08:00");

    afternoonTime = parseTime(widget.reminderData["afternoon_time"] ?? "13:00");

    nightTime = parseTime(widget.reminderData["night_time"] ?? "21:00");

    mealType = widget.reminderData["meal_type"] ?? "Before Food";

    isDaily = widget.reminderData["isDaily"] ?? true;
  }

  Future deleteReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Get saved alarm IDs
      int morningId = widget.reminderData["morning_alarm_id"] ?? 0;
      int afternoonId = widget.reminderData["afternoon_alarm_id"] ?? 0;
      int nightId = widget.reminderData["night_alarm_id"] ?? 0;

      // Stop alarms
      if (morningId != 0) {
        await Alarm.stop(morningId);
      }

      if (afternoonId != 0) {
        await Alarm.stop(afternoonId);
      }

      if (nightId != 0) {
        await Alarm.stop(nightId);
      }

      // Delete reminder document from Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("reminders")
          .doc(widget.reminderId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder deleted successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Delete Reminder Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting reminder: $e")));
    }
  }

  Future updateReminder() async {
    final user = FirebaseAuth.instance.currentUser!;

    // Get old alarm IDs
    int oldMorningId = widget.reminderData["morning_alarm_id"] ?? 0;
    int oldAfternoonId = widget.reminderData["afternoon_alarm_id"] ?? 0;
    int oldNightId = widget.reminderData["night_alarm_id"] ?? 0;

    // Stop old alarms
    await Alarm.stop(oldMorningId);
    await Alarm.stop(oldAfternoonId);
    await Alarm.stop(oldNightId);

    // Create new IDs
    final baseId = widget.reminderData["medicine_id"].hashCode.abs();

    int newMorningId = baseId + 1;
    int newAfternoonId = baseId + 2;
    int newNightId = baseId + 3;

    // -------------------
    // CREATE NEW ALARMS
    // -------------------

    if (morningEnabled) {
      await AlarmService.setMedicineAlarm(
        id: newMorningId,
        medicineName: widget.reminderData["medicine_name"],
        dateTime: convertToDateTime(morningTime),
      );
    }

    if (afternoonEnabled) {
      await AlarmService.setMedicineAlarm(
        id: newAfternoonId,
        medicineName: widget.reminderData["medicine_name"],
        dateTime: convertToDateTime(afternoonTime),
      );
    }

    if (nightEnabled) {
      await AlarmService.setMedicineAlarm(
        id: newNightId,
        medicineName: widget.reminderData["medicine_name"],
        dateTime: convertToDateTime(nightTime),
      );
    }

    // -------------------
    // UPDATE FIRESTORE
    // -------------------

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("reminders")
        .doc(widget.reminderId)
        .update({
          "morning_enabled": morningEnabled,
          "afternoon_enabled": afternoonEnabled,
          "night_enabled": nightEnabled,

          "morning_time": "${morningTime.hour}:${morningTime.minute}",
          "afternoon_time": "${afternoonTime.hour}:${afternoonTime.minute}",
          "night_time": "${nightTime.hour}:${nightTime.minute}",

          "morning_alarm_id": newMorningId,
          "afternoon_alarm_id": newAfternoonId,
          "night_alarm_id": newNightId,

          "meal_type": mealType,
          "isDaily": isDaily,

          "updatedAt": Timestamp.now(),
        });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminder Updated Successfully")),
    );

    Navigator.pop(context);
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
          "Edit Medicine Reminder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.medication, color: Colors.deepPurple),

                title: Text(widget.reminderData["medicine_name"] ?? "Medicine"),

                subtitle: const Text("Edit your reminder details"),
              ),
            ),

            const SizedBox(height: 20),

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

            if (morningEnabled)
              buildTimeTile(
                title: "Morning Time",
                time: morningTime,
                onTap: () {
                  pickTime(morningTime, (time) => morningTime = time);
                },
              ),

            const SizedBox(height: 15),

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

            if (afternoonEnabled)
              buildTimeTile(
                title: "Afternoon Time",
                time: afternoonTime,
                onTap: () {
                  pickTime(afternoonTime, (time) => afternoonTime = time);
                },
              ),

            const SizedBox(height: 15),

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

            if (nightEnabled)
              buildTimeTile(
                title: "Night Time",
                time: nightTime,
                onTap: () {
                  pickTime(nightTime, (time) => nightTime = time);
                },
              ),

            const Divider(height: 30),

            RadioListTile(
              value: "Before Food",
              groupValue: mealType,
              title: const Text("Before Food"),
              onChanged: (value) {
                setState(() {
                  mealType = value!;
                });
              },
            ),

            RadioListTile(
              value: "After Food",
              groupValue: mealType,
              title: const Text("After Food"),
              onChanged: (value) {
                setState(() {
                  mealType = value!;
                });
              },
            ),

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

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDF6F6),
                  side: BorderSide(color: Colors.green.shade700, width: 0.7),
                ),
                icon: const Icon(Icons.save, color: Colors.green),
                label: const Text(
                  "Update Reminder",
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: updateReminder,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDF6F6),
                  side: BorderSide(color: Colors.red.shade700, width: 0.7),
                ),

                icon: const Icon(Icons.delete, color: Color(0xFFBA1A1A)),
                label: const Text(
                  "Delete Reminder",
                  style: TextStyle(color: Color(0xFFBA1A1A)),
                ),

                onPressed: deleteReminder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

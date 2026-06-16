import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediscan/screens/editReminder_page.dart';
import 'package:mediscan/screens/loginpage.dart';
import 'package:mediscan/screens/medicinelist_page.dart';
import 'package:mediscan/screens/reminder_page.dart';
import 'package:intl/intl.dart';
import 'package:mediscan/screens/scan_page.dart';
import 'package:mediscan/screens/med_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String formatTime(String time) {
    final parts = time.split(":");

    final dateTime = DateTime(
      2025,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    return DateFormat("h:mm a").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                user.email![0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 22),
            const Text(
              "MediSync",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Image.asset("assets/images/logo.png", width: 60, height: 60),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Loginpage()),
              );
            },
            icon: const Icon(Icons.logout_outlined, color: Colors.deepPurple),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: const Color(0xFFEBDDFF)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              Row(
                children: [
                  Text(
                    "Welcome back, ",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 43, 40, 40),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.displayName ?? "User",
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // DASHBOARD CARDS
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection("medicines")
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Medicine Icon
                                Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6A5AE0),
                                        Color(0xFF8B7CFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.medication_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Count
                                Text(
                                  "$count",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Label
                                const Text(
                                  "Medicines",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection("reminders")
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Alarm Icon
                                Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFA726),
                                        Color(0xFFFF7043),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.alarm_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Reminder Count
                                Text(
                                  "$count",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Label
                                const Text(
                                  "Reminders",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // SCAN BUTTON
              SizedBox(
                width: double.infinity,
                height: 75,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 148, 97, 249),
                        Color.fromARGB(255, 43, 83, 242),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 30,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Scan Medicine",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.deepPurple.shade700,
                        width: 0.9,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanPage()),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // REMINDER BUTTON
              SizedBox(
                width: double.infinity,
                height: 75,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 207, 136),
                        Color.fromARGB(255, 255, 156, 126),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.orange.shade700,
                        width: 0.9,
                      ),
                    ),
                    icon: const Icon(
                      Icons.alarm,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 30,
                    ),
                    label: const Text(
                      "Set Reminder",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 113, 34, 34),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReminderPage()),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "My Reminders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .collection("reminders")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No reminders set",
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }

                    final reminders = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: reminders.length,

                      itemBuilder: (context, index) {
                        final doc = reminders[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),

                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.alarm),
                            ),

                            title: Text(
                              data["medicine_name"] ?? "Medicine",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${data["meal_type"]}"),

                                if (data["morning_enabled"] == true)
                                  Text(
                                    "🌅 Morning: ${formatTime(data["morning_time"])}",
                                  ),

                                if (data["afternoon_enabled"] == true)
                                  Text(
                                    "☀️ Afternoon: ${formatTime(data["afternoon_time"])}",
                                  ),

                                if (data["night_enabled"] == true)
                                  Text(
                                    "🌙 Night: ${formatTime(data["night_time"])}",
                                  ),
                              ],
                            ),

                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditReminderPage(
                                    reminderId: doc.id,
                                    reminderData: data,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          if (index == 0) return;

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ScanPage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MedicineListPage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReminderPage()),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: "Medicines",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: "Scan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Reminders",
          ),
        ],
      ),
    );
  }
}

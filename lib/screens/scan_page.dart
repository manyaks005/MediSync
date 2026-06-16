import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediscan/screens/homepage.dart';
import 'package:mediscan/screens/med_detail_page.dart';
import 'package:mediscan/screens/medicinelist_page.dart';
import 'package:mediscan/screens/reminder_page.dart';
import 'package:mediscan/services/medicine_firebase.dart';

import '../services/ocr_service.dart';
import '../services/openrouter_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController formulationController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController numberTabletsController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController instructionController = TextEditingController();
  final TextEditingController usesController = TextEditingController();
  final TextEditingController sideEffectController = TextEditingController();

  List<File> imageFiles = [];

  bool isLoading = false;
  String extractedText = "";
  Map<String, dynamic>? medicineData;

  // ---------------- IMAGE PICK ----------------
  Future pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedFile == null) return;

    setState(() {
      imageFiles.add(File(pickedFile.path));
    });
  }

  // ---------------- NAME EXTRACTION (LIGHT RULE) ----------------
  String? extractName(String text) {
    final lines = text.split('\n');

    for (final line in lines) {
      final l = line.toLowerCase();

      if (RegExp(r'\d+').hasMatch(l)) continue;
      if (l.contains('tablet') || l.contains('capsule')) continue;
      if (l.contains('batch') || l.contains('exp')) continue;

      if (l.trim().isNotEmpty) {
        return line.trim();
      }
    }
    return null;
  }

  // ---------------- SCAN ----------------
  Future scanText() async {
    if (imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final text = await OCRService.extractTextFromMultipleImages(imageFiles);

      final name = extractName(text);

      final result = await OpenRouterService.extractMedicineInfo(
        jsonEncode({"name": name ?? "", "raw_text": text}),
      );

      final List medicinesList = result["medicines"] ?? [];

      if (medicinesList.isEmpty) {
        throw Exception("No medicine detected");
      }

      final medicine = medicinesList[0];

      setState(() {
        extractedText = text;
        medicineData = medicine;
      });

      nameController.text = medicine["name"] ?? name ?? "";
      formulationController.text = medicine["dosage_form"] ?? "";
      dosageController.text = medicine["strength"] ?? "";
      expiryController.text = medicine["expiry_date"] ?? "";
      instructionController.text = medicine["instructions"] ?? "";
      usesController.text = medicine["uses"] ?? "";
      sideEffectController.text = medicine["side_effects"] ?? "";
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  // ---------------- SAVE ----------------
  Future saveMedicine() async {
    if (medicineData == null) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    try {
      await MedicineFirebaseService.saveMedicine({
        "name": nameController.text.trim(),
        "generic_name": medicineData!["generic_name"],
        "strength": dosageController.text.trim(),
        "dosage_form": formulationController.text.trim(),
        "manufacturer": medicineData!["manufacturer"],
        "batch_number": medicineData!["batch_number"],
        "expiry_date": expiryController.text.trim(),
        "instructions": instructionController.text.trim(),
        "uses": usesController.text.trim(),
        "side_effects": sideEffectController.text.trim(),
        "number_of_tablets": int.tryParse(numberTabletsController.text) ?? 0,
        "quantity": medicineData!["quantity"],
        "ocr_text": extractedText,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicine saved successfully")),
      );

      clearImages();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ---------------- CLEAR ----------------
  void clearImages() {
    setState(() {
      imageFiles.clear();
      medicineData = null;
      extractedText = "";

      nameController.clear();
      formulationController.clear();
      dosageController.clear();
      numberTabletsController.clear();
      expiryController.clear();
      instructionController.clear();
      usesController.clear();
      sideEffectController.clear();
    });
  }

  // ---------------- UI ----------------
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
          "Medicine Scanner",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Scan your medicine strips and get important details instantly. \nFor best results, capture clear images with good lighting from different angles.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color.fromARGB(179, 97, 91, 91),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            // IMAGE PREVIEW
            if (imageFiles.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.file(imageFiles[index]),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageFiles[index],
                                width: 120,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            top: 5,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  imageFiles.removeAt(index);
                                });
                              },
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text(
                        "Camera",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D51FA),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text(
                        "Gallery",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8D51FA),
                        elevation: 4,
                        side: const BorderSide(
                          color: Color(0xFF8D51FA),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: scanText,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  "Analyze the Image",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D51FA),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: clearImages,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  "Clear Images",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 2,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Analyzing Medicine..."),
                ],
              ),

            const SizedBox(height: 20),

            // FORM
            if (medicineData != null)
              Form(
                key: _formKey,
                child: Card(
                  elevation: 6,
                  shadowColor: Colors.deepPurple.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Medicine Name",
                          ),
                        ),
                        TextField(
                          controller: formulationController,
                          decoration: const InputDecoration(
                            labelText: "Dosage Form",
                          ),
                        ),
                        TextField(
                          controller: dosageController,
                          decoration: const InputDecoration(
                            labelText: "Strength",
                          ),
                        ),
                        TextFormField(
                          controller: numberTabletsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Required field";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: "Number of Tablets",
                          ),
                        ),
                        TextField(
                          controller: expiryController,
                          decoration: const InputDecoration(
                            labelText: "Expiry Date",
                          ),
                        ),
                        TextField(
                          controller: instructionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Instructions",
                          ),
                        ),
                        TextField(
                          controller: usesController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: "Uses"),
                        ),
                        TextField(
                          controller: sideEffectController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Side Effects",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (medicineData != null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: saveMedicine,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Save Medicine",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D51FA),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          if (index == 2) return;

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReminderPage()),
            );
          }

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MedicineListPage()),
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

import 'package:flutter/material.dart';

class MedicineReminder {
  String medicineId;
  String medicineName;

  bool morning;
  bool afternoon;
  bool night;

  TimeOfDay? morningTime;
  TimeOfDay? afternoonTime;
  TimeOfDay? nightTime;

  bool isActive;

  MedicineReminder({
    required this.medicineId,
    required this.medicineName,
    this.morning = false,
    this.afternoon = false,
    this.night = false,
    this.morningTime,
    this.afternoonTime,
    this.nightTime,
    this.isActive = true,
  });
}

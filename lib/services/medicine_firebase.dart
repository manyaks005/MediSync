import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicineFirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> saveMedicine(Map<String, dynamic> medicine) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      print("SAVE USER = ${user?.uid}");

      if (user == null) {
        throw Exception("User not logged in");
      }

      await _db.collection("users").doc(user.uid).collection("medicines").add({
        "userId": user.uid,

        "name": medicine["name"],
        "generic_name": medicine["generic_name"],
        "strength": medicine["strength"],
        "dosage_form": medicine["dosage_form"],
        "manufacturer": medicine["manufacturer"],
        "batch_number": medicine["batch_number"],
        "expiry_date": medicine["expiry_date"],
        "instructions": medicine["instructions"],
        "uses": medicine["uses"],
        "side_effects": medicine["side_effects"],
        "number_of_tablets": medicine["number_of_tablets"],
        "quantity": medicine["quantity"],
        "ocr_text": medicine["ocr_text"],

        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to save medicine: $e");
    }
  }
}

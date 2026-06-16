import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static String? extractMedicineName(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // remove obvious noise
    final filtered = lines.where((line) {
      return !RegExp(
        r'\d{2,4}\s?(mg|ml|tablets|capsules)',
        caseSensitive: false,
      ).hasMatch(line);
    }).toList();

    // usually first meaningful line is name
    if (filtered.isNotEmpty) {
      return filtered.first;
    }

    return null;
  }

  static Future<String> extractTextFromMultipleImages(List<File> images) async {
    final textRecognizer = TextRecognizer();

    try {
      String combinedText = "";

      for (File image in images) {
        final inputImage = InputImage.fromFile(image);

        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );

        combinedText += "\n${recognizedText.text}";
      }

      final uniqueLines = combinedText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      return uniqueLines.join('\n');
    } catch (e) {
      throw Exception("OCR Error: $e");
    } finally {
      await textRecognizer.close();
    }
  }
}

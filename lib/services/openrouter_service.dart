import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String apiKey = "YOUR_OPENROUTER_API_KEY";

  static Future<Map<String, dynamic>> extractMedicineInfo(
    String ocrText,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": """
You are a medicine information extraction system.

Extract medicine details from OCR text.

Return ONLY valid JSON.

Format:
{
  "medicines": [
    {
      "name": null,
      "generic_name": null,
      "strength": null,
      "dosage_form": null,
      "manufacturer": null,
      "batch_number": null,
      "manufacturing_date": null,
      "expiry_date": null,
      "price": null,
      "number_of_tablets": null,
      "quantity": null,
      "instructions": null,
      "uses": null,
      "side_effects": null
    }
  ]
}

Rules:
- Return only JSON
- No markdown
- No explanation
- Use null if unknown
- Keep uses and side_effects short and factual
""",
            },
            {"role": "user", "content": ocrText},
          ],
          "temperature": 0,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("OpenRouter Error: ${response.body}");
      }

      final data = jsonDecode(response.body);

      String content = data["choices"][0]["message"]["content"];

      // clean possible markdown
      content = content.replaceAll("```json", "").replaceAll("```", "").trim();

      return jsonDecode(content);
    } catch (e) {
      throw Exception("Medicine extraction failed: $e");
    }
  }
}

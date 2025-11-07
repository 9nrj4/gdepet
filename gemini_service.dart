import 'dart:convert';
import 'package:gde_pet/models/pet_model.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // ВАЖНО: API-ключ должен быть пустой строкой.
  // Платформа Canvas автоматически предоставит его во время выполнения.
  static const String _apiKey = ""; 
  static const String _model = "gemini-2.5-flash-preview-09-2025";
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';

  static Future<String> generateDescription({
    required PetStatus status,
    required PetType type,
    required String petName,
  }) async {
    final statusText =
        status == PetStatus.lost ? 'потерялся' : 'найден';
    final typeText = type.displayName.toLowerCase();
    final nameText = petName.isNotEmpty ? 'по кличке "$petName"' : '';

    final systemPrompt =
        'Ты — помощник, который пишет объявления о животных. '
        'Твоя задача — сгенерировать краткое, но емкое описание (2-3 предложения) '
        'для объявления. Описание должно быть написано на русском языке, от первого лица '
        '(например, "Пропала собака..."). '
        'Пользователь предоставит кличку, тип и статус животного. '
        'Попроси пользователя добавить больше деталей, таких как цвет, порода, '
        'особые приметы и местоположение.';

    final userQuery =
        'Сгенерируй описание для объявления. Статус: $statusText, '
        'Тип: $typeText, Кличка: $nameText.';

    // Таймаут для запроса
    const timeoutDuration = Duration(seconds: 20);

    try {
      final payload = {
        'contents': [
          {
            'parts': [
              {'text': userQuery}
            ]
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        
        // Проверка на наличие контента
        if (body['candidates'] != null &&
            body['candidates'].isNotEmpty &&
            body['candidates'][0]['content'] != null &&
            body['candidates'][0]['content']['parts'] != null &&
            body['candidates'][0]['content']['parts'].isNotEmpty) {
          final text =
              body['candidates'][0]['content']['parts'][0]['text'] as String;
          return text;
        } else {
          // Обработка случая, когда ответ 200, но без контента (например, из-за safety settings)
          throw 'AI не смог сгенерировать ответ. Попробуйте изменить запрос.';
        }
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw 'Ошибка ${response.statusCode}: ${errorBody['error']['message']}';
      }
    } catch (e) {
      print('Ошибка GeminiService: $e');
      throw 'Не удалось сгенерировать описание. Попробуйте позже.';
    }
  }
}

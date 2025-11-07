import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/vet_clinic_model.dart';

class VetClinicService {
  
  static const String _apiKey = "ПОМЕСТИТЕ_СЮДА_ВАШ_API_КЛЮЧ_GOOGLE_PLACES"; 
  // -------------------------------------------

  final String _nearbySearchUrl = 
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  final String _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  Future<List<VetClinic>> fetchVetClinics(LatLng userLocation) async {
    // Формируем URL запроса
    final String url = 
        '$_nearbySearchUrl?location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=10000' // Ищем в радиусе 10 км
        '&type=veterinary_care'
        '&keyword=ветклиника|ветеринарная'
        '&language=ru'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List results = data['results'];
          List<VetClinic> clinics = results
              .map((place) => VetClinic.fromGooglePlaces(place))
              .toList();
              
          // Сортируем по расстоянию
          clinics.sort((a, b) => 
            a.getDistanceFrom(userLocation).compareTo(b.getDistanceFrom(userLocation))
          );
          
          return clinics;
        } else {
          // Обработка ошибок API (например, REQUEST_DENIED, ZERO_RESULTS)
          print('Google Places API Error: ${data['status']}');
          throw 'Ошибка Google API: ${data['error_message'] ?? data['status']}';
        }
      } else {
        // Ошибка HTTP
        throw 'Ошибка сети: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Не удалось загрузить клиники: $e';
    }
  }

  // +++ ДОБАВЛЕН НОВЫЙ МЕТОД: getClinicDetails +++
  /// Загружает детальную информацию для одной клиники
  Future<VetClinic> getClinicDetails(String placeId, VetClinic existingClinic) async {
    // Запрашиваем только нужные поля: номер, сайт и часы работы
    final String url = 
        '$_placeDetailsUrl?placeid=$placeId'
        '&fields=formatted_phone_number,website,opening_hours'
        '&language=ru'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          
          // Парсим часы работы, если они есть
          String? workingHours;
          if (result['opening_hours'] != null && result['opening_hours']['weekday_text'] != null) {
            workingHours = (result['opening_hours']['weekday_text'] as List<dynamic>).join('\n');
          }

          // Возвращаем обновленную модель, используя copyWith
          return existingClinic.copyWith(
            phone: result['formatted_phone_number'],
            website: result['website'],
            workingHours: workingHours,
          );
        } else {
          throw 'Ошибка Google Details API: ${data['error_message'] ?? data['status']}';
        }
      } else {
        throw 'Ошибка сети: ${response.statusCode}';
      }
    } catch (e) {
      print('Ошибка getClinicDetails: $e');
      // Возвращаем старую клинику, если произошла ошибка
      return existingClinic;
    }
  }
  // +++ КОНЕЦ +++
}

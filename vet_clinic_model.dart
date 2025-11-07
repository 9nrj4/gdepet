import 'package:latlong2/latlong.dart';

class VetClinic {
  final String id;
  final String? placeId;
  final String name;
  final String address;
  final LatLng location;
  final String? phone;
  final String? website;
  final String? workingHours;
  final double? rating;
  final bool isEmergency; 

  VetClinic({
    required this.id,
    this.placeId,
    required this.name,
    required this.address,
    required this.location,
    this.phone, 
    this.website,
    this.workingHours, 
    this.rating,
    this.isEmergency = false,
  });

  factory VetClinic.fromGooglePlaces(Map<String, dynamic> json) {
    final lat = json['geometry']['location']['lat'];
    final lng = json['geometry']['location']['lng'];
    
    return VetClinic(
      id: json['place_id'],
      placeId: json['place_id'],
      name: json['name'],
      address: json['vicinity'] ?? 'Адрес не указан',
      location: LatLng(lat, lng),
      rating: (json['rating'] as num?)?.toDouble(),
      isEmergency: json['opening_hours']?['open_now'] ?? false,
      phone: json['formatted_phone_number'], 
      website: json['website'], 
    );
  }
  VetClinic copyWith({
    String? phone,
    String? website,
    String? workingHours,
  }) {
    return VetClinic(
      id: id,
      placeId: placeId,
      name: name,
      address: address,
      location: location,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      workingHours: workingHours ?? this.workingHours,
      rating: rating,
      isEmergency: isEmergency,
    );
  }
  double getDistanceFrom(LatLng userLocation) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, userLocation, location);
  }

  String getFormattedDistance(LatLng userLocation) {
    final distanceKm = getDistanceFrom(userLocation);
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} м';
    }
    return '${distanceKm.toStringAsFixed(1)} км';
  }
}

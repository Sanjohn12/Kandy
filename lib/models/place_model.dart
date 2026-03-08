import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final String name;
  final String location;
  final double rating;
  final String description;
  final LatLng coordinates;
  final String image;
  final String category;
  final String history;
  final String? historyImage;
  final bool isHiddenGem;
  bool isSaved;

  Place({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.description,
    required this.coordinates,
    required this.image,
    required this.category,
    this.history = '',
    this.historyImage,
    this.isHiddenGem = false,
    this.isSaved = false,
  });

  factory Place.fromFirestore(Map<String, dynamic> data, String id) {
    return Place(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      coordinates: LatLng(
        (data['latitude'] as num?)?.toDouble() ?? 0.0,
        (data['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      image: data['image'] ?? '',
      category: data['category'] ?? 'All',
      history: data['history'] ?? '',
      historyImage: data['historyImage'],
      isHiddenGem: data['isHiddenGem'] ?? false,
      isSaved: data['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'rating': rating,
      'description': description,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'image': image,
      'category': category,
      'history': history,
      'historyImage': historyImage,
      'isHiddenGem': isHiddenGem,
      'isSaved': isSaved,
    };
  }
}

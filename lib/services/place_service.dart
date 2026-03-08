import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';

class PlaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'places';

  // Fallback data for when Firestore is unreachable or permissions are denied
  static final List<Place> _fallbackPlaces = [
    Place(
      id: 'fallback_1',
      name: 'Temple of the Tooth Relic',
      location: 'Kandy, 1.2km',
      rating: 4.9,
      description:
          'The Sri Dalada Maligawa or the Temple of the Sacred Tooth Relic is a Buddhist temple in the city of Kandy, Sri Lanka.',
      coordinates: const LatLng(7.2936, 80.6413),
      image: 'assets/images/templeoftooth.jpeg',
      category: 'Temples',
    ),
    Place(
      id: 'fallback_2',
      name: 'Sigiriya Rock Fortress',
      location: 'Dambulla, 12km',
      rating: 5.0,
      description:
          'Sigiriya or Sinhagiri is an ancient rock fortress located in the northern Matale District near the town of Dambulla.',
      coordinates: const LatLng(7.9570, 80.7603),
      image: 'assets/images/sigiriya.jpeg',
      category: 'Temples',
    ),
    Place(
      id: 'fallback_3',
      name: 'Royal Botanical Gardens',
      location: 'Peradeniya, 5km',
      rating: 4.7,
      description:
          'Royal Botanic Gardens, Peradeniya are about 5.5 km to the west of the city of Kandy in the Central Province of Sri Lanka.',
      coordinates: const LatLng(7.2689, 80.5964),
      image: 'assets/images/garden.jpeg',
      category: 'Nature',
    ),
    Place(
      id: 'fallback_4',
      name: 'Kandy Lake',
      location: 'City Centre',
      rating: 4.5,
      description:
          'Kandy Lake, also known as Kiri Muhuda or the Sea of Milk, is an artificial lake in the heart of the hill city of Kandy.',
      coordinates: const LatLng(7.2931, 80.6403),
      image: 'assets/images/kandylake.jpeg',
      category: 'City',
    ),
  ];

  // Get all places
  Stream<List<Place>> getPlaces() {
    return _db.collection(_collection).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return _fallbackPlaces;
      return snapshot.docs
          .map((doc) => Place.fromFirestore(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      // Fallback to local data on permission error or network issue
      return _fallbackPlaces;
    });
  }

  // Stream of places count
  Stream<int> getPlacesCount() {
    return _db
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Stream of places count by category
  Stream<int> getPlacesCountByCategory(String category) {
    return _db
        .collection(_collection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get places by category
  Stream<List<Place>> getPlacesByCategory(String category) {
    if (category == 'All') return getPlaces();
    return _db
        .collection(_collection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _fallbackPlaces.where((p) => p.category == category).toList();
      }
      return snapshot.docs
          .map((doc) => Place.fromFirestore(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      return _fallbackPlaces.where((p) => p.category == category).toList();
    });
  }

  // Add a new place
  Future<void> addPlace(Place place) {
    return _db.collection(_collection).add(place.toFirestore());
  }

  // Update a place
  Future<void> updatePlace(Place place) {
    return _db
        .collection(_collection)
        .doc(place.id)
        .update(place.toFirestore());
  }

  // Delete a place
  Future<void> deletePlace(String id) {
    return _db.collection(_collection).doc(id).delete();
  }
}

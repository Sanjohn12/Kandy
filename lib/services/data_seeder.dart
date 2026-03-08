import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// This is a one-time script that can be called from main.dart or a button to seed data
class DataSeeder {
  static Future<void> seedData() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final collection = db.collection('places');

    // Check if data already exists to avoid duplicates
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      debugPrint('Data already seeded. Skipping.');
      return;
    }

    final List<Map<String, dynamic>> initialData = [
      {
        'name': 'Temple of the Tooth Relic',
        'location': 'Kandy, 1.2km',
        'rating': 4.9,
        'description':
            'The Sri Dalada Maligawa or the Temple of the Sacred Tooth Relic is a Buddhist temple in the city of Kandy, Sri Lanka.',
        'latitude': 7.2936,
        'longitude': 80.6413,
        'image': 'assets/images/templeoftooth.jpeg',
        'category': 'Temples',
      },
      {
        'name': 'Sigiriya Rock Fortress',
        'location': 'Dambulla, 12km',
        'rating': 5.0,
        'description':
            'Sigiriya or Sinhagiri is an ancient rock fortress located in the northern Matale District near the town of Dambulla.',
        'latitude': 7.9570,
        'longitude': 80.7603,
        'image': 'assets/images/sigiriya.jpeg',
        'category': 'Temples',
      },
      {
        'name': 'Royal Botanical Gardens',
        'location': 'Peradeniya, 5km',
        'rating': 4.7,
        'description':
            'Royal Botanic Gardens, Peradeniya are about 5.5 km to the west of the city of Kandy in the Central Province of Sri Lanka.',
        'latitude': 7.2689,
        'longitude': 80.5964,
        'image': 'assets/images/garden.jpeg',
        'category': 'Nature',
      },
      {
        'name': 'Udawatta Kele Sanctuary',
        'location': 'Kandy, 2km',
        'rating': 4.6,
        'description':
            'A historic forest reserve on a hill-ridge in the city of Kandy. It is famous for its extensive avifauna.',
        'latitude': 7.2989,
        'longitude': 80.6425,
        'image': 'assets/images/sanctuary.jpeg',
        'category': 'Nature',
        'isHiddenGem': true,
      },
      {
        'name': 'Kandy Lake',
        'location': 'City Centre',
        'rating': 4.5,
        'description':
            'Kandy Lake, also known as Kiri Muhuda or the Sea of Milk, is an artificial lake in the heart of the hill city of Kandy.',
        'latitude': 7.2931,
        'longitude': 80.6403,
        'image': 'assets/images/kandylake.jpeg',
        'category': 'City',
      },
      {
        'name': 'The Empire Cafe',
        'location': 'Temple Street',
        'rating': 4.5,
        'description':
            'A charming cafe located in a colonial building, serving a mix of Sri Lankan and Western dishes.',
        'latitude': 7.2940,
        'longitude': 80.6400,
        'image': 'assets/images/cafe.jpeg',
        'category': 'Food',
        'isHiddenGem': true,
      },
    ];

    for (var data in initialData) {
      await collection.add(data);
    }
    debugPrint('Seeding complete.');
  }
}

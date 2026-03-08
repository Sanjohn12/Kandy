import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';

class UserService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Stream of all users for admin management
  Stream<List<AppUser>> getUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  // Stream of users count
  Stream<int> getUsersCount() {
    return _usersCollection.snapshots().map((snapshot) => snapshot.size);
  }

  // Create or update user data
  Future<void> saveUser(AppUser user) async {
    await _usersCollection
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  // Get user by ID
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    await _usersCollection.doc(uid).update({'role': role});
  }

  // Get current user role
  Future<String> getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'user';

    // Special case for initial admin
    if (user.email == 'sanoadksano@gmail.com') return 'admin';

    final appUser = await getUserById(user.uid);
    return appUser?.role ?? 'user';
  }

  // Check-in logic with badge awarding
  Future<Map<String, dynamic>> checkIn(String userId, Place place) async {
    final user = await getUserById(userId);
    if (user == null) throw Exception('User not found');

    if (user.visitedPlaces.contains(place.id)) {
      return {'success': false, 'message': 'You have already checked in here!'};
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition();

    // Calculate distance (in meters)
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.coordinates.latitude,
      place.coordinates.longitude,
    );

    // Must be within 200 meters
    if (distance > 200) {
      return {
        'success': false,
        'message':
            'You are too far away to check in! (Distance: ${distance.toInt()}m)'
      };
    }

    // Update visited places
    List<String> updatedVisited = List.from(user.visitedPlaces)..add(place.id);
    List<Map<String, dynamic>> updatedBadges = List.from(user.earnedBadges);

    List<String> newBadgeNames = [];

    // Award "Kandy Explorer" on first check-in
    if (updatedVisited.length == 1) {
      _addBadge(updatedBadges, 'Kandy Explorer', '🗺️',
          'Checked in for the first time!');
      newBadgeNames.add('Kandy Explorer');
    }

    // Award "Hidden Gem Hunter" after 3 hidden gems
    if (place.isHiddenGem) {
      // Future logic for multiple hidden gems can go here
    }

    await _usersCollection.doc(userId).update({
      'visitedPlaces': updatedVisited,
      'earnedBadges': updatedBadges,
    });

    return {
      'success': true,
      'message': 'Successfully checked in!',
      'newBadges': newBadgeNames,
    };
  }

  void _addBadge(List<Map<String, dynamic>> badges, String name, String icon,
      String description) {
    if (!badges.any((b) => b['name'] == name)) {
      badges.add({
        'name': name,
        'icon': icon,
        'description': description,
        'earnedAt': Timestamp.now(),
      });
    }
  }
}

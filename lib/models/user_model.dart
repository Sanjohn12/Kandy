import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final DateTime createdAt;
  final List<String> visitedPlaces;
  final List<Map<String, dynamic>> earnedBadges;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.visitedPlaces = const [],
    this.earnedBadges = const [],
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      visitedPlaces: List<String>.from(data['visitedPlaces'] ?? []),
      earnedBadges: List<Map<String, dynamic>>.from(data['earnedBadges'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'visitedPlaces': visitedPlaces,
      'earnedBadges': earnedBadges,
    };
  }
}

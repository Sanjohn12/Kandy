import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final String type; // 'user' or 'admin'
  final String? imageUrl;
  final String? replyToId;
  final String? replyToMessage;
  final String? replyToUserName;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.type = 'user',
    this.imageUrl,
    this.replyToId,
    this.replyToMessage,
    this.replyToUserName,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'user',
      imageUrl: data['imageUrl'],
      replyToId: data['replyToId'],
      replyToMessage: data['replyToMessage'],
      replyToUserName: data['replyToUserName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToMessage != null) 'replyToMessage': replyToMessage,
      if (replyToUserName != null) 'replyToUserName': replyToUserName,
    };
  }
}

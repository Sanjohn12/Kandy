import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('community_messages');

  final _supabase = Supabase.instance.client;

  // Stream of community messages (ordered by timestamp)
  Stream<List<ChatMessage>> getMessages() {
    return _messagesCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Upload image to Supabase Storage (bucket: 'chat_media')
  Future<String?> uploadChatImage(XFile imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      await _supabase.storage.from('chat_media').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl =
          _supabase.storage.from('chat_media').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Chat image upload error: $e');
      return null;
    }
  }

  // Send a new message
  Future<void> sendMessage(ChatMessage message) async {
    await _messagesCollection.add(message.toMap());
  }

  // Delete a message and its associated image if it exists
  Future<void> deleteMessage(String messageId, {String? imageUrl}) async {
    try {
      if (imageUrl != null) {
        await deleteChatImage(imageUrl);
      }
      await _messagesCollection.doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Delete image from Supabase Storage
  Future<void> deleteChatImage(String imageUrl) async {
    try {
      // Extract filename from public URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage.from('chat_media').remove([fileName]);
    } catch (e) {
      print('Error deleting chat image: $e');
    }
  }
}

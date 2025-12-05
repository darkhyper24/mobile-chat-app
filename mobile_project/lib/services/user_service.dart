import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db.dart';

class UserService {
  final SupabaseClient _client = DatabaseService().client;
  final ImagePicker _picker = ImagePicker();

  // Update user profile information
  Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    String? firstname,
    String? lastname,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (firstname != null) updates['firstname'] = firstname;
      if (lastname != null) updates['lastname'] = lastname;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;

      if (updates.isEmpty) return null;

      final response = await _client
          .from('users')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Upload profile picture to Supabase storage
  Future<String?> uploadProfilePicture({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileExt = imagePath.split('.').last.toLowerCase();
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      // Delete old profile picture if exists
      try {
        final existingFiles = await _client.storage
            .from('images')
            .list(path: userId);

        for (var file in existingFiles) {
          await _client.storage.from('images').remove(['$userId/${file.name}']);
        }
      } catch (e) {
        // Ignore errors when deleting old files
      }

      // Upload to Supabase storage bucket 'images'
      final uploadResponse = await _client.storage
          .from('images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from('images').getPublicUrl(filePath);

      // Update user's profile_pic in database
      await _client
          .from('users')
          .update({'profile_pic': publicUrl})
          .eq('user_id', userId)
          .select()
          .single();

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
}

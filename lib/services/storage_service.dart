import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class StorageService {
  final SupabaseClient _supabase = SupabaseService.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Compress image for better performance
  Future<File?> compressImage(File file) async {
    try {
      final String targetPath = file.path.replaceAll('.jpg', '_compressed.jpg');
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1920,
        minHeight: 1080,
      );
      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }

  // Upload photo to public bucket
  Future<Map<String, String>?> uploadPhoto({
    required File imageFile,
    required String bucketName,
  }) async {
    try {
      final String userId = _supabase.auth.currentUser?.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '$timestamp.jpg';
      final String filePath = '$userId/$fileName';

      await _supabase.storage.from(bucketName).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(filePath);

      return {
        'url': publicUrl,
        'path': filePath,
      };
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  // Delete photo from storage
  Future<bool> deletePhoto({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      await _supabase.storage.from(bucketName).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}

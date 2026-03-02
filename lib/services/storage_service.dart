import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for picking and saving images to local device storage.
///
/// Images are saved to the app's documents directory under an `item_images/` folder.
class StorageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery.
  Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Take a photo with the camera.
  Future<File?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Saves an image file to the app's documents directory and returns the local path.
  Future<String> saveImageLocally(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/item_images');

    // Create the folder if it doesn't exist
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    // Generate a unique filename
    final ext = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path)
        : '.jpg';
    final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await imageFile.copy('${imageDir.path}/$fileName');

    return savedFile.path;
  }

  /// Deletes a locally saved image by its path.
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Silently fail — file may already be deleted
    }
  }

  /// Checks if a local image file exists at the given path.
  static bool imageExists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}

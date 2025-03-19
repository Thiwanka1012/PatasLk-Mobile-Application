import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class EditPhotoScreen extends StatefulWidget {
  final String? currentImageUrl;
  
  const EditPhotoScreen({super.key, this.currentImageUrl});

  @override
  State<EditPhotoScreen> createState() => _EditPhotoScreenState();
}

class _EditPhotoScreenState extends State<EditPhotoScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _hasSelectedNewImage = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, 
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _hasSelectedNewImage = true;
        });
        _showMessage('Photo selected successfully');
      }
    } catch (e) {
      _showMessage('Error selecting photo');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildOptionButton(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit photo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_hasSelectedNewImage && _image != null) {
                Navigator.of(context).pop(_image);
              } else if (widget.currentImageUrl != null && !_hasSelectedNewImage) {
                Navigator.of(context).pop(null);
              } else {
                _showMessage('Please select an image first');
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _hasSelectedNewImage && _image != null 
                  ? FileImage(_image!) 
                  : null,
              child: _hasSelectedNewImage == false && _image == null
                  ? widget.currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            imageUrl: widget.currentImageUrl!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => 
                                const Icon(Icons.person, size: 60, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 24),
            _buildOptionButton(
              Icons.photo_library_outlined,
              'Choose from Gallery',
              () => _pickImage(ImageSource.gallery),
            ),
            _buildOptionButton(
              Icons.camera_alt_outlined,
              'Take Photo',
              () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

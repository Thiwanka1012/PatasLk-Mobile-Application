import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/firebase_firestore_helper.dart';
import '../../../utils/firebase_storage_helper.dart';
import '../../customer/location/location_picker_screen.dart';
import 'service_provider_photo_upload_screen.dart';

class ServiceProviderProfileScreen extends StatefulWidget {
  const ServiceProviderProfileScreen({super.key});

  @override
  State<ServiceProviderProfileScreen> createState() => _ServiceProviderProfileScreenState();
}

class _ServiceProviderProfileScreenState extends State<ServiceProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedJobRole;
  File? _profileImage;
  String? _profileImageUrl;
  
  // Location-related variables
  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _selectedDistrict;
  bool _locationUpdated = false;

  final List<String> _jobRoles = [
    'AC Repair',
    'Beauty',
    'Appliance',
    'Painting',
    'Cleaning',
    'Plumbing',
    'Electronics',
    'Men\'s Salon',
    'Shifting'
  ];

  bool _isLoading = true;
  // Firebase Auth: Access to authentication services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firebase Firestore: Helper for database operations
  final FirestoreHelper _firestoreHelper = FirestoreHelper();
  // Firebase Storage: Helper for file storage operations
  final FirebaseStorageHelper _storageHelper = FirebaseStorageHelper();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Helper method to extract district from address
  String _extractDistrict(String address) {
    final List<String> parts = address.split(',');
    for (String part in parts) {
      part = part.trim();
      if (part.contains('District')) {
        return part;
      }
    }
    return 'District not specified';
  }

  /// Loads the current service provider's profile from Firestore.
  Future<void> _loadProfile() async {
    // Firebase Auth: Get current user
    User? user = _auth.currentUser;
    if (user != null) {
      // Firebase Firestore: Get provider document from serviceProviders collection
      DocumentSnapshot doc = await _firestoreHelper
          .getUserStream(collection: 'serviceProviders', uid: user.uid)
          .first;
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        // Remove +94 prefix for editing.
        if (data['phone'] != null) {
          String phone = data['phone'];
          _phoneController.text = phone.startsWith('+94') ? phone.substring(3) : phone;
        }
        _emailController.text = data['email'] ?? '';
        _selectedJobRole = data['jobRole'];
        
        // Load location data if stored
        if (data['location'] != null) {
          _selectedAddress = data['location'];
          _selectedDistrict = data['district'];
          
          // If coordinates are stored, retrieve them
          if (data['latitude'] != null && data['longitude'] != null) {
            _selectedLocation = LatLng(
              data['latitude'],
              data['longitude']
            );
          }
        }
        
        // Load profile image URL if stored
        setState(() {
          _profileImageUrl = data['profileImageUrl'];
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  /// Select location using the LocationPickerScreen
  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result['coordinates'] as LatLng;
        _selectedAddress = result['address'] as String;
        _selectedDistrict = _extractDistrict(_selectedAddress!);
        _locationUpdated = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location selected successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Updates the profile image by navigating to the photo upload screen
  Future<void> _editProfilePhoto() async {
    final File? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServiceProviderPhotoUploadScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _profileImage = result;
      });
      
      // Upload immediately when a new photo is selected
      _uploadProfileImage();
    }
  }

  /// Uploads the profile image to Firebase Storage
  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Firebase Auth: Get current user
    User? user = _auth.currentUser;
    if (user != null) {
      // Firebase Storage: Delete old image if exists
      if (_profileImageUrl != null) {
        await _storageHelper.deleteFileByUrl(_profileImageUrl!);
      }
      
      // Firebase Storage: Upload new image
      String? downloadUrl = await _storageHelper.uploadFile(
        file: _profileImage!, 
        userId: user.uid, 
        folder: 'profile_images',
      );
      
      if (downloadUrl != null) {
        // Firebase Firestore: Update profile with new image URL
        await _firestoreHelper.saveUserData(
          collection: 'serviceProviders',
          uid: user.uid,
          data: {'profileImageUrl': downloadUrl},
        );
        
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload profile photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  /// Saves the profile to Firestore.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Firebase Auth: Get current user
      User? user = _auth.currentUser;
      if (user != null) {
        // Prepare location data
        Map<String, dynamic> locationData = {};
        if (_selectedLocation != null) {
          locationData = {
            'location': _selectedAddress,
            'district': _selectedDistrict, 
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          };
        }
        
        // Firebase Firestore: Update user profile data
        await _firestoreHelper.saveUserData(
          collection: 'serviceProviders',
          uid: user.uid,
          data: {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': '+94' + _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'jobRole': _selectedJobRole,
            'userType': 'serviceProvider',
            'updatedAt': Timestamp.now(), // Firebase server timestamp
            ...locationData, // Add location data if available
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user signed in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
        _locationUpdated = false;
      });
    }
  }

  /// Builds a profile field section with a label.
  Widget _buildProfileField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds a text field with consistent decoration.
  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType? keyboardType, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  /// Builds a location field with map preview.
  Widget _buildLocationField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location selection button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectLocation,
                    icon: const Icon(Icons.location_on),
                    label: Text(
                      _selectedAddress == null ? 'Select Service Location' : 'Change Location',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show selected location details
          if (_selectedAddress != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _locationUpdated ? Colors.green : Colors.grey.shade300,
                  width: _locationUpdated ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // District badge - important for service providers
                  if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'District: $_selectedDistrict',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  
                  // Full address
                  const Text(
                    'Service Area:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddress!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  
                  // Coordinates
                  if (_selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                  // If location was just updated, show a success indicator
                  if (_locationUpdated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Location updated - Save profile to apply changes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Service Provider Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save Profile',
              style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: GestureDetector(
                        onTap: _editProfilePhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                              child: _profileImage == null
                                  ? _profileImageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: CachedNetworkImage(
                                            imageUrl: _profileImageUrl!,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => 
                                                const Icon(Icons.person, size: 50, color: Colors.blue),
                                          ),
                                        )
                                      : const Icon(Icons.person, size: 50, color: Colors.blue)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First Name
                          _buildProfileField(
                            'First Name',
                            _buildTextField('Enter first name', _firstNameController),
                          ),
                          // Last Name
                          _buildProfileField(
                            'Last Name',
                            _buildTextField('Enter last name', _lastNameController),
                          ),
                          // Phone Number (with "+94" displayed separately)
                          _buildProfileField(
                            'Phone Number',
                            Row(
                              children: [
                                const Text('+94 '),
                                Expanded(
                                  child: _buildTextField('Enter phone number', _phoneController, keyboardType: TextInputType.phone),
                                ),
                              ],
                            ),
                          ),
                          // Email (read-only)
                          _buildProfileField(
                            'E-mail',
                            _buildTextField('Enter email', _emailController, keyboardType: TextInputType.emailAddress, readOnly: true),
                          ),
                          // Job Role (dropdown)
                          _buildProfileField(
                            'Job Role',
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedJobRole,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                hint: const Text('Select job role'),
                                items: _jobRoles.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJobRole = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a job role';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          
                          // Service Location section - new enhanced section
                          _buildProfileField(
                            'Service Location',
                            _buildLocationField(),
                          ),
                          
                          const SizedBox(height: 24),
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _locationUpdated ? 'Save Profile with New Location' : 'Save Profile',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          // Display warning if no location is set
                          if (_selectedLocation == null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.amber.shade800, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Setting your service location is required to receive job requests in your area.',
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

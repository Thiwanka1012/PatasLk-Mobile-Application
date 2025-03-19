import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  String? _address;
  bool _isLoading = false;
  bool _mapReady = false;
  bool _isMounted = true; // Track if widget is still mounted

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);
  static const double _defaultZoom = 8.0;

  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;

  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!_isMounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!_isMounted) return;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = [
            if (place.street?.isNotEmpty ?? false) place.street,
            if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
            if (place.locality?.isNotEmpty ?? false) place.locality,
            if (place.subAdministrativeArea?.isNotEmpty ?? false)
              '${place.subAdministrativeArea} District',
            if (place.administrativeArea?.isNotEmpty ?? false)
              place.administrativeArea,
            if (place.country?.isNotEmpty ?? false) place.country,
          ].where((element) => element != null).join(', ');
        });

        // Debug print to verify the data
        debugPrint('District: ${place.subAdministrativeArea}');
        debugPrint('Full Address: $_address');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (_isMounted) {
        setState(() {
          _address = 'Unable to fetch address';
        });
      }
    } finally {
      if (_isMounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _getCurrentLocation();
      
      if (!_isMounted || !_mapReady) return;
      
      final userLocation = LatLng(position.latitude, position.longitude);
      
      // Check if the coordinates are within Sri Lanka's bounding box
      if (_isWithinSriLanka(userLocation)) {
        if (_isMounted) {
          setState(() => _selectedLocation = userLocation);
        }
        _mapController.move(userLocation, 15.0);
        await _getAddressFromLatLng(userLocation);
      } else {
        // If outside Sri Lanka, stay at Sri Lanka center
        if (_isMounted) {
          setState(() => _selectedLocation = _sriLankaCenter);
        }
        _mapController.move(_sriLankaCenter, _defaultZoom);
      }
    } catch (error) {
      debugPrint('Error getting location: $error');
      // Fallback to Sri Lanka center
      if (_isMounted && _mapReady) {
        setState(() => _selectedLocation = _sriLankaCenter);
        _mapController.move(_sriLankaCenter, _defaultZoom);
      }
    }
  }

  bool _isWithinSriLanka(LatLng position) {
    // Sri Lanka's approximate bounding box
    const minLat = 5.916667;
    const maxLat = 9.850000;
    const minLng = 79.683333;
    const maxLng = 81.883333;

    return position.latitude >= minLat &&
        position.latitude <= maxLat &&
        position.longitude >= minLng &&
        position.longitude <= maxLng;
  }

  void _showCoordinates(LatLng position) {
    if (!_isMounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  void _toggleLocationTracking() async {
    if (!_isTracking) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) return;

      try {
        if (_isMounted) {
          setState(() => _isTracking = true);
        }

        // Get initial position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (!_isMounted) return;

        final currentLocation = LatLng(position.latitude, position.longitude);
        setState(() => _currentLocation = currentLocation);

        if (_isWithinSriLanka(currentLocation)) {
          _mapController.move(currentLocation, 15.0);
        }

        // Start position stream
        _positionStreamSubscription?.cancel(); // Cancel any existing subscription
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (Position position) {
            if (!_isMounted || !_isTracking) return;

            final newLocation = LatLng(position.latitude, position.longitude);
            setState(() => _currentLocation = newLocation);

            if (_isWithinSriLanka(newLocation)) {
              _mapController.move(newLocation, _mapController.camera.zoom);
            }
          },
          onError: (e) {
            debugPrint('Location stream error: $e');
            if (_isMounted) {
              _stopTracking();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error tracking location')),
              );
            }
          },
          cancelOnError: true,
        );
      } catch (e) {
        debugPrint('Error starting location tracking: $e');
        if (_isMounted) {
          _stopTracking();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get current location')),
          );
        }
      }
    } else {
      _stopTracking();
    }
  }

  void _stopTracking() {
    if (_isTracking && _isMounted) {
      setState(() => _isTracking = false);
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    }
  }

  Future<void> _searchLocation(String query) async {
    // Cancel any previous debounce timer
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      if (_isMounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    // Use debounce to avoid too many API calls
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!_isMounted) return;
      
      setState(() => _isSearching = true);
      
      try {
        // Add "Sri Lanka" to the search query to focus on Sri Lankan locations
        List<Location> locations = await locationFromAddress("$query, Sri Lanka");
        
        if (!_isMounted) return;
        
        setState(() {
          _searchResults = locations.where((loc) {
            final position = LatLng(loc.latitude, loc.longitude);
            return _isWithinSriLanka(position);
          }).toList();
        });
      } catch (e) {
        debugPrint('Error searching location: $e');
        if (_isMounted) {
          setState(() => _searchResults = []);
        }
      } finally {
        if (_isMounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _selectSearchResult(Location location) {
    if (!_isMounted) return;
    
    final position = LatLng(location.latitude, location.longitude);
    setState(() {
      _selectedLocation = position;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(position, 15.0);
    _getAddressFromLatLng(position);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      // Format that maintains backward compatibility
      final result = {
        'coordinates': _selectedLocation, // Return the actual LatLng object
        'address': _address ?? 'Unknown location',
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      };
      debugPrint('Returning location data: $result');
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _searchController.dispose();
    _searchDebounce?.cancel();
    _stopTracking();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize with Sri Lanka center
    _selectedLocation = _sriLankaCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _selectedLocation != null ? _confirmLocation : null,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sriLankaCenter, // Always start with Sri Lanka
              initialZoom: _defaultZoom,
              minZoom: 4.0,
              maxZoom: 18.0,
              onMapReady: () {
                if (_isMounted) {
                  setState(() => _mapReady = true);
                  _initializeLocation();
                }
              },
              onTap: (tapPosition, point) async {
                if (_isWithinSriLanka(point)) {
                  if (_isMounted) {
                    setState(() => _selectedLocation = point);
                  }
                  await _getAddressFromLatLng(point);
                } else if (_isMounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a location within Sri Lanka'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Add current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Add search bar at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location in Sri Lanka',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => _searchLocation(value),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(
                            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                          ),
                          onTap: () => _selectSearchResult(location),
                        );
                      },
                    ),
                  ),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          // Add location tracking button
          Positioned(
            right: 16,
            bottom: 200, // Above zoom controls
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: _isTracking ? Colors.blue : Colors.grey,
                ),
                onPressed: _toggleLocationTracking,
                tooltip: _isTracking ? 'Stop tracking' : 'Track my location',
              ),
            ),
          ),
          // Replace the existing zoom controls Positioned widget with this:
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          var currentCenter = _mapController.camera.center;
                          var currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            currentCenter,
                            currentZoom + 1,
                          );
                        },
                      ),
                      Container(
                        height: 1,
                        width: 20,
                        color: Colors.grey[300],
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          var currentCenter = _mapController.camera.center;
                          var currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            currentCenter,
                            currentZoom - 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      Text(
                        'Address:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _address ?? 'Fetching address...',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

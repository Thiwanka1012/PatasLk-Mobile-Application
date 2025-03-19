import 'package:latlong2/latlong.dart';

class LocationHelper {
  /// Extract location data from Firestore booking document
  static LatLng? extractLocationFromBooking(Map<String, dynamic> bookingData) {
    try {
      // Case 1: Check if location exists as a map with coordinates
      if (bookingData['location'] != null && bookingData['location'] is Map) {
        var locationMap = bookingData['location'] as Map;
        
        // Try to get from 'coordinates' map first
        if (locationMap['coordinates'] is Map) {
          var coordMap = locationMap['coordinates'] as Map;
          var lat = coordMap['latitude'];
          var lng = coordMap['longitude'];
          if (lat != null && lng != null) {
            return LatLng(
              lat is num ? lat.toDouble() : 0.0,
              lng is num ? lng.toDouble() : 0.0
            );
          }
        }
        
        // Try to get from top level keys in location map
        var lat = locationMap['latitude'];
        var lng = locationMap['longitude'];
        if (lat != null && lng != null) {
          return LatLng(
            lat is num ? lat.toDouble() : 0.0,
            lng is num ? lng.toDouble() : 0.0
          );
        }
      }
      
      // Case 2: Check if latitude/longitude are directly on the booking
      if (bookingData['latitude'] != null && bookingData['longitude'] != null) {
        var lat = bookingData['latitude'];
        var lng = bookingData['longitude'];
        return LatLng(
          lat is num ? lat.toDouble() : 0.0,
          lng is num ? lng.toDouble() : 0.0
        );
      }
      
      return null;
    } catch (e) {
      print('Error extracting location: $e');
      return null;
    }
  }
  
  /// Extract address from booking data
  static String extractAddressFromBooking(Map<String, dynamic> bookingData) {
    // Try to get address from various possible locations in the data
    if (bookingData['address'] != null && bookingData['address'] is String) {
      return bookingData['address'] as String;
    }
    
    if (bookingData['location'] != null && bookingData['location'] is Map) {
      var locationMap = bookingData['location'] as Map;
      if (locationMap['address'] != null && locationMap['address'] is String) {
        return locationMap['address'] as String;
      }
    }
    
    return 'Address not available';
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for OpenStreetMap Nominatim Geocoding API
/// Free and open-source alternative to Google Places
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  // User agent is required by Nominatim API
  static const String _userAgent = 'GoHelperApp/1.0';

  /// Search for locations using Nominatim Search API
  /// Returns list of places matching the query
  static Future<List<NominatimPlace>> searchPlaces(
    String query, {
    String countryCode = 'PK', // Default to Pakistan
    int limit = 10,
  }) async {
    if (query.isEmpty || query.length < 2) return [];

    try {
      // Add delay to respect Nominatim usage policy (max 1 req/sec)
      await Future.delayed(const Duration(milliseconds: 100));

      final params = {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'countrycodes': countryCode.toLowerCase(),
        'accept-language': 'en',
      };

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NominatimPlace.fromJson(json)).toList();
      } else {
        print('Nominatim error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Nominatim search error: $e');
      return [];
    }
  }

  /// Reverse geocode: Get address from coordinates
  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final params = {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'en',
      };

      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
      return null;
    } catch (e) {
      print('Reverse geocode error: $e');
      return null;
    }
  }

  /// Get detailed place information by OSM ID
  static Future<NominatimPlace?> getPlaceDetails(String placeId, String osmType) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final params = {
        'osm_ids': '$osmType$placeId',
        'format': 'json',
        'addressdetails': '1',
      };

      final uri = Uri.parse('$_baseUrl/lookup').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return NominatimPlace.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Get place details error: $e');
      return null;
    }
  }
}

/// Model for Nominatim Place
class NominatimPlace {
  final String placeId;
  final String osmType;
  final String osmId;
  final String displayName;
  final double lat;
  final double lon;
  final String? name;
  final String? city;
  final String? state;
  final String? country;
  final String? road;
  final String? suburb;
  final String? neighbourhood;
  final String type;
  final String? icon;

  NominatimPlace({
    required this.placeId,
    required this.osmType,
    required this.osmId,
    required this.displayName,
    required this.lat,
    required this.lon,
    this.name,
    this.city,
    this.state,
    this.country,
    this.road,
    this.suburb,
    this.neighbourhood,
    required this.type,
    this.icon,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    
    return NominatimPlace(
      placeId: json['place_id'].toString(),
      osmType: json['osm_type'] ?? '',
      osmId: json['osm_id'].toString(),
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
      name: json['name'],
      city: address?['city'] ?? 
            address?['town'] ?? 
            address?['village'] ?? 
            address?['municipality'],
      state: address?['state'] ?? address?['province'],
      country: address?['country'],
      road: address?['road'],
      suburb: address?['suburb'],
      neighbourhood: address?['neighbourhood'],
      type: json['type'] ?? 'place',
      icon: json['icon'],
    );
  }

  /// Get a short display name (main text)
  String get mainText {
    if (name != null && name!.isNotEmpty) return name!;
    if (road != null && road!.isNotEmpty) return road!;
    if (suburb != null && suburb!.isNotEmpty) return suburb!;
    if (city != null && city!.isNotEmpty) return city!;
    return displayName.split(',').first;
  }

  /// Get secondary text (location context)
  String get secondaryText {
    List<String> parts = [];
    if (city != null && city != mainText) parts.add(city!);
    if (state != null) parts.add(state!);
    if (parts.isEmpty && country != null) parts.add(country!);
    return parts.join(', ');
  }

  /// Get a clean formatted address
  String get formattedAddress {
    List<String> parts = [];
    if (name != null && name!.isNotEmpty) parts.add(name!);
    if (road != null && road!.isNotEmpty) parts.add(road!);
    if (suburb != null && suburb!.isNotEmpty) parts.add(suburb!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    
    if (parts.isEmpty) return displayName;
    return parts.join(', ');
  }
}

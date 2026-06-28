import 'package:flutter/material.dart';
import 'package:go_helper/utils/Constants/image_strings.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_helper/shared/widgets/osm_location_search.dart';

class SimpleFromToSection extends StatefulWidget {
  final String fromText;
  final String toText;
  final Function(String, double, double) onFromChanged;
  final Function(String, double, double) onToChanged;
  final VoidCallback onAddMore;
  final VoidCallback? onFromTap;
  final VoidCallback? onToTap;

  const SimpleFromToSection({
    super.key,
    required this.fromText,
    required this.toText,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onAddMore,
    this.onFromTap,
    this.onToTap,
  });

  @override
  State<SimpleFromToSection> createState() => _SimpleFromToSectionState();
}

class _SimpleFromToSectionState extends State<SimpleFromToSection> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  bool _isFetchingLocation = false;

  // Search variables
  bool _showFromSearch = false;
  bool _showToSearch = false;
  final TextEditingController _fromSearchController = TextEditingController();
  final TextEditingController _toSearchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  // Pakistan cities for suggestions
  final List<String> _pakistanCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Hyderabad',
    'Gujranwala',
    'Peshawar',
    'Quetta',
    'Sargodha',
    'Bahawalpur',
    'Sialkot',
    'Sukkur',
    'Larkana',
    'Sheikhupura',
    'Rahim Yar Khan',
    'Jhang',
    'Gujrat',
    'Mardan',
  ];

  // Coordinates for major Pakistan cities
  final Map<String, Map<String, double>> _cityCoordinates = {
    'Karachi': {'lat': 24.8607, 'lng': 67.0011},
    'Lahore': {'lat': 31.5497, 'lng': 74.3436},
    'Islamabad': {'lat': 33.6844, 'lng': 73.0479},
    'Rawalpindi': {'lat': 33.5651, 'lng': 73.0169},
    'Faisalabad': {'lat': 31.4504, 'lng': 73.1350},
    'Multan': {'lat': 30.1575, 'lng': 71.5249},
    'Hyderabad': {'lat': 25.3969, 'lng': 68.3778},
    'Gujranwala': {'lat': 32.1877, 'lng': 74.1945},
    'Peshawar': {'lat': 34.0151, 'lng': 71.5249},
    'Quetta': {'lat': 30.1798, 'lng': 66.9750},
    'Sargodha': {'lat': 32.0836, 'lng': 72.6711},
    'Bahawalpur': {'lat': 29.3544, 'lng': 71.6911},
    'Sialkot': {'lat': 32.4945, 'lng': 74.5229},
    'Sukkur': {'lat': 27.7131, 'lng': 68.8482},
    'Larkana': {'lat': 27.5600, 'lng': 68.2264},
    'Sheikhupura': {'lat': 31.7167, 'lng': 73.9850},
    'Rahim Yar Khan': {'lat': 28.4200, 'lng': 70.2950},
    'Jhang': {'lat': 31.2682, 'lng': 72.3180},
    'Gujrat': {'lat': 32.5736, 'lng': 74.0789},
    'Mardan': {'lat': 34.1958, 'lng': 72.0447},
  };

  // Common places in each city
  final Map<String, List<String>> _cityPlaces = {
    'Karachi': [
      'Airport',
      'Railway Station',
      'Sea View',
      'Port Grand',
      'Dolmen Mall',
    ],
    'Lahore': [
      'Airport',
      'Railway Station',
      'Badshahi Mosque',
      'Lahore Fort',
      'Mall Road',
    ],
    'Islamabad': [
      'Airport',
      'Railway Station',
      'Faisal Mosque',
      'Margalla Hills',
      'Centaurus Mall',
    ],
    'Rawalpindi': [
      'Airport',
      'Railway Station',
      'Raja Bazaar',
      'Liaquat Bagh',
      'Sixth Road',
    ],
  };

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.fromText);
    _toController = TextEditingController(text: widget.toText);

    // Initialize with current location if empty
    if (widget.fromText.isEmpty || widget.fromText == 'Current Location') {
      _fetchCurrentLocation();
    }
  }

  @override
  void didUpdateWidget(SimpleFromToSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromText != oldWidget.fromText) {
      _fromController.text = widget.fromText;
    }
    if (widget.toText != oldWidget.toText) {
      _toController.text = widget.toText;
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      setState(() {
        _isFetchingLocation = true;
      });

      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        // Get address from coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address = _formatAddress(place);

          _fromController.text = address;
          // Call with coordinates
          widget.onFromChanged(address, position.latitude, position.longitude);
        } else {
          _fromController.text = 'My Current Location';
          widget.onFromChanged(
            'My Current Location',
            position.latitude,
            position.longitude,
          );
        }
      } else {
        _fromController.text = 'Tap to enable location';
        widget.onFromChanged('Tap to enable location', 0, 0);
      }
    } catch (e) {
      print("Location error: $e");
      _fromController.text = 'Location unavailable';
      widget.onFromChanged('Location unavailable', 0, 0);
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      addressParts.add(place.subAdministrativeArea!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }
    return addressParts.isNotEmpty
        ? addressParts.join(', ')
        : 'Current Location';
  }

  void _clearFromField() {
    _fromController.clear();
    widget.onFromChanged('', 0, 0);
    _fetchCurrentLocation(); // Refetch current location
  }

  void _clearToField() {
    _toController.clear();
    widget.onToChanged('', 0, 0);
  }

  // REAL-TIME SEARCH FUNCTION FOR ENTIRE PAKISTAN
  void _performSearch(String query, {required bool isFrom}) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _pakistanCities.take(5).toList();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Search in cities first
      final cityResults =
          _pakistanCities
              .where((city) => city.toLowerCase().contains(query.toLowerCase()))
              .toList();

      // Search in city places
      List<String> placeResults = [];
      _cityPlaces.forEach((city, places) {
        for (var place in places) {
          if (place.toLowerCase().contains(query.toLowerCase())) {
            placeResults.add('$place, $city');
          }
        }
      });

      // Combine results
      List<String> allResults = [...cityResults, ...placeResults];

      // If no results found, show option to search as custom location
      if (allResults.isEmpty) {
        allResults.add('Search for "$query"');
      }

      // Limit to 10 results
      allResults = allResults.take(10).toList();

      setState(() {
        _searchResults = allResults;
        _isSearching = false;
      });
    } catch (e) {
      print("Search error: $e");
      setState(() {
        _searchResults = _pakistanCities.take(5).toList();
        _isSearching = false;
      });
    }
  }

  void _showSearchSheet(BuildContext context, {required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return OSMLocationSearch(
          title: isFrom ? 'Search Pickup Location' : 'Search Destination',
          hint: isFrom ? 'Enter pickup location...' : 'Enter destination...',
          showCurrentLocation: isFrom,
          onLocationSelected: (address, lat, lng) {
            if (isFrom) {
              _fromController.text = address;
              widget.onFromChanged(address, lat, lng);
            } else {
              _toController.text = address;
              widget.onToChanged(address, lat, lng);
            }
          },
        );
      },
    );
  }

  // REALTIME GEOCODING FOR ANY LOCATION IN PAKISTAN
  Future<void> _selectLocation(String location, {required bool isFrom}) async {
    double lat = 0;
    double lng = 0;
    String displayLocation = location;

    // Check if it's in format "Place, City"
    if (location.contains(', ')) {
      List<String> parts = location.split(', ');
      String place = parts[0];
      String city = parts[1];

      // Try to get coordinates for the city
      if (_cityCoordinates.containsKey(city)) {
        lat = _cityCoordinates[city]!['lat']!;
        lng = _cityCoordinates[city]!['lng']!;

        // Add small offset for places within city
        lat += 0.005;
        lng += 0.005;

        print("📍 Using city coordinates for: $place, $city ($lat, $lng)");
      }
    }
    // Check if it's a major city
    else if (_cityCoordinates.containsKey(location)) {
      lat = _cityCoordinates[location]!['lat']!;
      lng = _cityCoordinates[location]!['lng']!;
      print("📍 Using city coordinates for: $location ($lat, $lng)");
    }
    // Otherwise, geocode the location
    else {
      try {
        print("🔍 Geocoding: $location");

        // Add Pakistan for better results
        String searchQuery =
            location.contains("Pakistan") ? location : "$location, Pakistan";

        List<Location> locations = await locationFromAddress(
          searchQuery,
          localeIdentifier: "en",
        );

        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
          print("✅ Geocoded successfully: $location ($lat, $lng)");
        } else {
          // Fallback: Try without Pakistan
          try {
            List<Location> locations2 = await locationFromAddress(location);
            if (locations2.isNotEmpty) {
              lat = locations2.first.latitude;
              lng = locations2.first.longitude;
              print(
                "✅ Geocoded successfully (without country): $location ($lat, $lng)",
              );
            } else {
              // Fallback to approximate Pakistan coordinates
              lat = 30.3753; // Center of Pakistan
              lng = 69.3451;
              print("⚠️ Geocoding failed, using Pakistan center coordinates");
            }
          } catch (e) {
            lat = 30.3753;
            lng = 69.3451;
            print("❌ Geocoding error: $e");
          }
        }
      } catch (e) {
        print("❌ Geocoding error for '$location': $e");
        // Center of Pakistan as fallback
        lat = 30.3753;
        lng = 69.3451;
      }
    }

    if (isFrom) {
      _fromController.text = displayLocation;
      widget.onFromChanged(displayLocation, lat, lng);
    } else {
      _toController.text = displayLocation;
      widget.onToChanged(displayLocation, lat, lng);
    }
  }

  void _handleCustomSearch(
    String query, {
    required bool isFrom,
    required BuildContext context,
  }) {
    // For custom search, just select it directly (geocoding will handle it)
    _selectLocation(query, isFrom: isFrom);
    Navigator.pop(context); // Close search sheet
  }

  void _showManualEntryDialog(BuildContext context, {required bool isFrom}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final controller = TextEditingController(
      text: isFrom ? _fromController.text : _toController.text,
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFrom ? 'Enter Pickup Location' : 'Enter Destination',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter complete address (City, Area, Street)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: HColors.primary, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  'Example: G-9 Markaz, Islamabad or Main Boulevard, Lahore',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          _selectLocation(
                            controller.text.trim(),
                            isFrom: isFrom,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HColors.primary,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        children: [
          SizedBox(height: screenWidth * 0.04),

          // FROM Section
          Row(
            children: [
              // Home Icon
              Image.asset(
                HImages.homeIcon,
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                color: HColors.primary,
              ),
              SizedBox(width: screenWidth * 0.03),

              // FROM Text
              Text(
                'FROM',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),

              // Editable FROM Text Field
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.onFromTap != null) {
                      widget.onFromTap!();
                    } else {
                      _showSearchSheet(context, isFrom: true);
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _isFetchingLocation
                                ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: HColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Getting location...',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                                : Text(
                                  _fromController.text,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.grey.shade700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.grey.shade400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                      ),
                      if (_fromController.text.isNotEmpty &&
                          !_isFetchingLocation)
                        GestureDetector(
                          onTap: _clearFromField,
                          child: Icon(
                            Icons.close,
                            size: screenWidth * 0.045,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.04),

          // TO Section with Plus Icon
          Row(
            children: [
              // Flag Icon
              Image.asset(
                HImages.flagIcon,
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                color: Colors.green,
              ),
              SizedBox(width: screenWidth * 0.03),

              // TO Text
              Text(
                'TO',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),

              // Editable TO Text Field
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.onToTap != null) {
                      widget.onToTap!();
                    } else {
                      _showSearchSheet(context, isFrom: false);
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _toController.text,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey.shade700,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey.shade400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (_toController.text.isNotEmpty)
                        GestureDetector(
                          onTap: _clearToField,
                          child: Icon(
                            Icons.close,
                            size: screenWidth * 0.045,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Plus Icon
              GestureDetector(
                onTap: widget.onAddMore,
                child: Container(
                  margin: EdgeInsets.only(left: screenWidth * 0.02),
                  width: screenWidth * 0.08,
                  height: screenWidth * 0.08,
                  decoration: BoxDecoration(
                    color: HColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: HColors.primary,
                    size: screenWidth * 0.045,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromSearchController.dispose();
    _toSearchController.dispose();
    super.dispose();
  }
}

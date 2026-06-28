import 'package:flutter/material.dart';
import 'package:go_helper/services/nominatim_service.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class OSMLocationSearch extends StatefulWidget {
  final String title;
  final String hint;
  final Function(String address, double lat, double lng) onLocationSelected;
  final bool showCurrentLocation;

  const OSMLocationSearch({
    super.key,
    required this.title,
    required this.hint,
    required this.onLocationSelected,
    this.showCurrentLocation = true,
  });

  @override
  State<OSMLocationSearch> createState() => _OSMLocationSearchState();
}

class _OSMLocationSearchState extends State<OSMLocationSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<NominatimPlace> _places = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _places = [];
        _isSearching = false;
      });
      return;
    }

    // Don't search for very short queries
    if (query.length < 2) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Debounce to avoid too many API calls
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final results = await NominatimService.searchPlaces(query, limit: 15);
        
        if (mounted) {
          setState(() {
            _places = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        print('Search error: $e');
        if (mounted) {
          setState(() {
            _places = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _selectPlace(NominatimPlace place) {
    widget.onLocationSelected(
      place.formattedAddress,
      place.lat,
      place.lon,
    );
    Navigator.pop(context);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isSearching = true;
    });

    try {
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Get address from coordinates using Nominatim
        final address = await NominatimService.reverseGeocode(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          widget.onLocationSelected(
            address ?? 'Current Location',
            position.latitude,
            position.longitude,
          );
          Navigator.pop(context);
        }
      } else {
        _showError('Location permission denied');
      }
    } catch (e) {
      _showError('Could not get current location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'road':
      case 'street':
        return Icons.directions;
      case 'house':
      case 'building':
        return Icons.home;
      case 'amenity':
        return Icons.place;
      case 'shop':
        return Icons.store;
      case 'tourism':
        return Icons.attractions;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _places = [];
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Powered by OSM badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by OpenStreetMap',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Results List
          Expanded(
            child: _searchController.text.isEmpty || _searchController.text.length < 2
                ? _buildInitialView()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Current Location Option
        if (widget.showCurrentLocation)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location,
                size: 20,
                color: HColors.primary,
              ),
            ),
            title: const Text(
              'Use Current Location',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Detect automatically using GPS'),
            onTap: _getCurrentLocation,
          ),

        const SizedBox(height: 16),

        // Instructions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.map_outlined,
                size: 60,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Search for any location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type an address, landmark, city, or place name\n(Minimum 2 characters)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),

        // Examples
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Examples:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              ...['Karachi', 'Lahore Airport', 'Islamabad F-7', 'Mall Road'].map(
                (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $example',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _places.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_places.isEmpty && !_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or check spelling',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPlaceIcon(place.type),
              size: 20,
              color: Colors.blue,
            ),
          ),
          title: Text(
            place.mainText,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: place.secondaryText.isNotEmpty
              ? Text(
                  place.secondaryText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => _selectPlace(place),
        );
      },
    );
  }
}

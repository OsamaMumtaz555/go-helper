import 'package:flutter/material.dart';
import 'package:go_helper/utils/Constants/image_strings.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapWidget extends StatefulWidget {
  final VoidCallback onMapTap;
  final double height;
  final bool isFullMap;
  final LatLng? fromLocation;
  final LatLng? toLocation;
  final Function(LatLng)? onFromLocationSelected;
  final Function(LatLng)? onToLocationSelected;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Function(int durationSeconds)? onRouteCalculated;

  const MapWidget({
    super.key,
    required this.onMapTap,
    this.height = 550,
    this.isFullMap = false,
    this.fromLocation,
    this.toLocation,
    this.onFromLocationSelected,
    this.onToLocationSelected,
    this.scaffoldKey, // نیا parameter
    this.onRouteCalculated,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController _mapController;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  LatLng _userLocation = const LatLng(24.8607, 67.0011); // Default Karachi
  double _zoomLevel = 15.0;
  bool _isLoading = true;
  Position? _currentPosition;
  bool _isMapReady = false;

  // Selection state
  bool _selectingFrom = false;
  bool _selectingTo = false;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  void _initializeMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromLocation != oldWidget.fromLocation ||
        widget.toLocation != oldWidget.toLocation) {
      if (widget.fromLocation != null || widget.toLocation != null) {
        _addMarkersAndRoute();
      }
    }
  }

  // Safe map move helper method
  void _safeMapMove(LatLng point, double zoom) {
    if (!mounted) return;

    try {
      _mapController.move(point, zoom);
    } catch (e) {
      print("Safe map move error: $e");
      // Retry once after a delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          try {
            _mapController.move(point, zoom);
          } catch (e2) {
            print("Retry map move error: $e2");
          }
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        _addMarkersAndRoute();
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          _addMarkersAndRoute();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        _addMarkersAndRoute();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _currentPosition = position;
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move map after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _safeMapMove(_userLocation, _zoomLevel);
          _isMapReady = true;
        }
      });

      _addMarkersAndRoute();
    } catch (e) {
      print("Location error: $e");
      setState(() {
        _isLoading = false;
      });
      _addMarkersAndRoute();
      _isMapReady = true;
    }
  }

  void _addMarkersAndRoute() {
    _markers = [];
    _polylines = [];

    // Add user location marker (only if not overridden by from location)
    if (widget.fromLocation == null ||
        (widget.fromLocation != null && widget.toLocation == null)) {
      _markers.add(
        Marker(
          width: 70,
          height: 70,
          point: _userLocation,
          builder:
              (ctx) => _buildPersonIcon(
                screenWidth: MediaQuery.of(ctx).size.width,
                iconAsset: HImages.personIcon,
                onTap: () {
                  _showUserInfo();
                },
              ),
        ),
      );
    }

    // Add From location marker
    if (widget.fromLocation != null) {
      _markers.add(
        Marker(
          width: 70,
          height: 70,
          point: widget.fromLocation!,
          builder:
              (ctx) => _buildFromIcon(
                screenWidth: MediaQuery.of(ctx).size.width,
                onTap: () {
                  _showFromInfo();
                },
              ),
        ),
      );
    }

    // Add To location marker
    if (widget.toLocation != null) {
      _markers.add(
        Marker(
          width: 70,
          height: 70,
          point: widget.toLocation!,
          builder:
              (ctx) => _buildToIcon(
                screenWidth: MediaQuery.of(ctx).size.width,
                onTap: () {
                  _showToInfo();
                },
              ),
        ),
      );
    }

    // Draw route between From and To
    if (widget.fromLocation != null && widget.toLocation != null) {
      _fetchRoute();
      // Zoom to fit both locations
      _zoomToFitBothLocations();
    }

    // Add nearby vehicles (only if not in selection mode)
    if (!_selectingFrom && !_selectingTo) {
      _addNearbyVehicles();
    }

    // Add selection marker if selecting
    if (_selectedPoint != null) {
      _markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _selectedPoint!,
          builder:
              (ctx) => _buildSelectionIcon(
                screenWidth: MediaQuery.of(ctx).size.width,
                isFrom: _selectingFrom,
              ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchRoute() async {
    if (widget.fromLocation == null || widget.toLocation == null) return;

    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${widget.fromLocation!.longitude},${widget.fromLocation!.latitude};${widget.toLocation!.longitude},${widget.toLocation!.latitude}?geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          final duration = route['duration'] as num; // Duration in seconds

          // Notify parent of ETA
          if (widget.onRouteCalculated != null) {
            widget.onRouteCalculated!(duration.toInt());
          }

          List<LatLng> routePoints = geometry.map((coord) {
            return LatLng(coord[1], coord[0]); // GeoJSON is [lng, lat]
          }).toList();

          setState(() {
            // Remove any existing polylines
            _polylines.clear();
            
            // Add actual path
            _polylines.add(
              Polyline(
                points: routePoints,
                strokeWidth: 4,
                color: HColors.primary, // Route color
              ),
            );
          });
        }
      } else {
        print("Failed to fetch route: ${response.statusCode}");
        // Fallback to straight line on failure
        _fallbackToStraightLine();
      }
    } catch (e) {
      print("Error fetching route: $e");
      _fallbackToStraightLine();
    }
  }

  void _fallbackToStraightLine() {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          points: [widget.fromLocation!, widget.toLocation!],
          strokeWidth: 4,
          color: HColors.primary,
        ),
      );
    });
  }

  void _addNearbyVehicles() {
    LatLng centerPoint = widget.fromLocation ?? _userLocation;

    // Add some nearby vehicles markers
    List<Marker> vehicleMarkers = [
      Marker(
        width: 70,
        height: 70,
        point: LatLng(
          centerPoint.latitude + 0.005,
          centerPoint.longitude + 0.005,
        ),
        builder:
            (ctx) => _buildVehicleIcon(
              type: 'car',
              screenWidth: MediaQuery.of(ctx).size.width,
              label: 'Car',
              iconAsset: HImages.carIcon,
              onTap: () {
                _showVehicleInfo('Car 1', 'Toyota Corolla', '1.2 km', 'car');
              },
            ),
      ),
      Marker(
        width: 70,
        height: 70,
        point: LatLng(
          centerPoint.latitude - 0.004,
          centerPoint.longitude - 0.003,
        ),
        builder:
            (ctx) => _buildVehicleIcon(
              type: 'bike',
              screenWidth: MediaQuery.of(ctx).size.width,
              label: 'Bike',
              iconAsset: HImages.bikeIcon,
              onTap: () {
                _showVehicleInfo('Bike 1', 'Honda 125', '0.8 km', 'bike');
              },
            ),
      ),
      Marker(
        width: 70,
        height: 70,
        point: LatLng(centerPoint.latitude, centerPoint.longitude + 0.008),
        builder:
            (ctx) => _buildVehicleIcon(
              type: 'car',
              screenWidth: MediaQuery.of(ctx).size.width,
              label: 'Car',
              iconAsset: HImages.carIcon,
              onTap: () {
                _showVehicleInfo('Car 2', 'Suzuki Alto', '1.5 km', 'car');
              },
            ),
      ),
    ];

    _markers.addAll(vehicleMarkers);
  }

  void _zoomToFitBothLocations() {
    if (widget.fromLocation != null && widget.toLocation != null) {
      double minLat =
          widget.fromLocation!.latitude < widget.toLocation!.latitude
              ? widget.fromLocation!.latitude
              : widget.toLocation!.latitude;
      double maxLat =
          widget.fromLocation!.latitude > widget.toLocation!.latitude
              ? widget.fromLocation!.latitude
              : widget.toLocation!.latitude;
      double minLng =
          widget.fromLocation!.longitude < widget.toLocation!.longitude
              ? widget.fromLocation!.longitude
              : widget.toLocation!.longitude;
      double maxLng =
          widget.fromLocation!.longitude > widget.toLocation!.longitude
              ? widget.fromLocation!.longitude
              : widget.toLocation!.longitude;

      LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

      // Adjust zoom based on distance
      double latDiff = maxLat - minLat;
      double lngDiff = maxLng - minLng;
      double newZoom = latDiff > 0.02 || lngDiff > 0.02 ? 13.0 : 15.0;

      // Add delay for safety
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _safeMapMove(center, newZoom);
        }
      });
    }
  }

  void _startSelecting(bool isFrom) {
    setState(() {
      _selectingFrom = isFrom;
      _selectingTo = !isFrom;
      _selectedPoint = null;
    });

    // Show instruction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFrom
              ? 'Tap on map to select pickup location'
              : 'Tap on map to select destination',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: HColors.primary,
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    if (_selectingFrom || _selectingTo) {
      setState(() {
        _selectedPoint = point;
      });

      // Confirm selection
      _showConfirmationDialog(point);
    }
  }

  void _showConfirmationDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _selectingFrom ? 'Set as Pickup?' : 'Set as Destination?',
          ),
          content: Text(
            'Lat: ${point.latitude.toStringAsFixed(6)}\n'
            'Lng: ${point.longitude.toStringAsFixed(6)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelSelection();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmSelection(point);
              },
              style: ElevatedButton.styleFrom(backgroundColor: HColors.primary),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _confirmSelection(LatLng point) {
    if (_selectingFrom && widget.onFromLocationSelected != null) {
      widget.onFromLocationSelected!(point);
    } else if (_selectingTo && widget.onToLocationSelected != null) {
      widget.onToLocationSelected!(point);
    }

    setState(() {
      _selectingFrom = false;
      _selectingTo = false;
      _selectedPoint = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectingFrom ? 'Pickup location set!' : 'Destination set!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelSelection() {
    setState(() {
      _selectingFrom = false;
      _selectingTo = false;
      _selectedPoint = null;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel += 1;
      // Clamp zoom level to reasonable limits
      if (_zoomLevel > 18) _zoomLevel = 18;
    });

    // Add safety check
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          // Get current center from map controller
          _safeMapMove(_mapController.center, _zoomLevel);
        } catch (e) {
          print("Zoom in error: $e");
        }
      }
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel -= 1;
      // Clamp zoom level to reasonable limits
      if (_zoomLevel < 3) _zoomLevel = 3;
    });

    // Add safety check
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          // Get current center from map controller
          _safeMapMove(_mapController.center, _zoomLevel);
        } catch (e) {
          print("Zoom out error: $e");
        }
      }
    });
  }

  void _resetToMyLocation() async {
    try {
      if (_currentPosition != null) {
        setState(() {
          _userLocation = LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          _zoomLevel = 15.0;
        });

        // Add delay for safety
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _safeMapMove(_userLocation, _zoomLevel);
          }
        });
        _addMarkersAndRoute();
      } else {
        await _getCurrentLocation();
      }
    } catch (e) {
      print("Reset location error: $e");
    }
  }

  // نیا function: Drawer کھولنے کے لیے
  void _openDrawer() {
    // پہلے widget.scaffoldKey استعمال کریں
    if (widget.scaffoldKey != null &&
        widget.scaffoldKey!.currentState != null) {
      widget.scaffoldKey!.currentState!.openDrawer();
    }
    // اگر scaffoldKey نہیں ہے تو context کے ذریعے کوشش کریں
    else {
      try {
        Scaffold.of(context).openDrawer();
      } catch (e) {
        print("Could not open drawer: $e");
        // Alternative: Navigator کے ذریعے کھولنے کی کوشش کریں
        _showDrawerOpenError();
      }
    }
  }

  void _showDrawerOpenError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cannot open menu. Please ensure the screen has a drawer.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUserInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  HImages.personIcon,
                  width: 40,
                  height: 40,
                  color: HColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_currentPosition != null)
                Column(
                  children: [
                    Text(
                      'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetToMyLocation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Center to My Location',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFromInfo() {
    if (widget.fromLocation == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  size: 40,
                  color: HColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pickup Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${widget.fromLocation!.latitude.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Lng: ${widget.fromLocation!.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startSelecting(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HColors.primary,
                      ),
                      child: const Text('Change Location'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (_currentPosition != null &&
                            widget.onFromLocationSelected != null) {
                          widget.onFromLocationSelected!(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Use My Location'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToInfo() {
    if (widget.toLocation == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, size: 40, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'Destination',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${widget.toLocation!.latitude.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Lng: ${widget.toLocation!.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startSelecting(false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Change'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVehicleInfo(String id, String name, String distance, String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (type == 'car' ? Colors.blue : Colors.green)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  type == 'car' ? HImages.carIcon : HImages.bikeIcon,
                  width: 40,
                  height: 40,
                  color: type == 'car' ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Distance: $distance',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HColors.primary,
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = screenWidth * 0.05;

    return Container(
      height: widget.height,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Stack(
        children: [
          // OpenStreetMap Container
          Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child:
                  _isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: HColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Getting your location...',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                      : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: widget.fromLocation ?? _userLocation,
                          zoom: _zoomLevel,
                          interactiveFlags:
                              InteractiveFlag.all & ~InteractiveFlag.rotate,
                          onTap: (tapPosition, latLng) {
                            if (_selectingFrom || _selectingTo) {
                              _handleMapTap(latLng);
                            } else {
                              widget.onMapTap();
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.gohelper.app',
                            retinaMode: true,
                          ),
                          PolylineLayer(polylines: _polylines),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
            ),
          ),

          // Top Left Menu Button - UPDATED
          Positioned(
            top: widget.height * 0.05,
            left: screenWidth * 0.07,
            child: GestureDetector(
              onTap: _openDrawer, // یہاں تبدیل کیا گیا
              child: Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    HImages.menuIcon,
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                  ),
                ),
              ),
            ),
          ),

          // My Location Button
          Positioned(
            top: widget.height * 0.05,
            right: screenWidth * 0.07,
            child: GestureDetector(
              onTap: _resetToMyLocation,
              child: Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.my_location,
                    color: HColors.primary,
                    size: screenWidth * 0.06,
                  ),
                ),
              ),
            ),
          ),

          // Selection Mode Indicator
          if (_selectingFrom || _selectingTo)
            Positioned(
              top: widget.height * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_selectingFrom ? HColors.primary : Colors.red)
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _selectingFrom
                            ? 'Tap on map to select pickup'
                            : 'Tap on map to select destination',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _cancelSelection,
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Zoom Controls (only for full map)
          if (widget.isFullMap)
            Positioned(
              right: screenWidth * 0.07,
              top: widget.height * 0.18,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _zoomIn,
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: HColors.primary,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _zoomOut,
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.remove,
                          color: HColors.primary,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Right Toggle
          Positioned(
            bottom: widget.height * 0.05,
            right: screenWidth * 0.07,
            child: GestureDetector(
              onTap: widget.onMapTap,
              child: Container(
                width: screenWidth * 0.14,
                height: screenWidth * 0.14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.07),
                  border: Border.all(color: HColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    widget.isFullMap
                        ? HImages.minimizeIcon
                        : HImages.expandIcon,
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    color: HColors.primary,
                  ),
                ),
              ),
            ),
          ),

          // Live Indicator
          if (!_selectingFrom && !_selectingTo)
            Positioned(
              top: widget.height * 0.05,
              left: screenWidth * 0.25,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // GPS Accuracy Warning
          if (_currentPosition != null &&
              _currentPosition!.accuracy > 50 &&
              !_selectingFrom &&
              !_selectingTo)
            Positioned(
              bottom: widget.height * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_not_fixed, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'GPS Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleIcon({
    required String type,
    required double screenWidth,
    required String label,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    Color color = type == 'car' ? Colors.blue : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              type == 'car' ? Icons.directions_car : Icons.directions_bike,
              size: screenWidth * 0.05,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonIcon({
    required double screenWidth,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: HColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: screenWidth * 0.05,
              color: HColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: const Text(
              'You',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromIcon({
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: HColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.my_location,
              color: HColors.primary,
              size: screenWidth * 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: const Text(
              'Pickup',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToIcon({
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.red,
              size: screenWidth * 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: const Text(
              'Destination',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIcon({
    required double screenWidth,
    required bool isFrom,
  }) {
    Color color = isFrom ? HColors.primary : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            isFrom ? Icons.my_location : Icons.location_on,
            color: color,
            size: screenWidth * 0.06,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            isFrom ? 'SELECT PICKUP' : 'SELECT DESTINATION',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

class TrainTrackingPage extends StatefulWidget {
  const TrainTrackingPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TrainTrackingPageState createState() => _TrainTrackingPageState();
}

class _TrainTrackingPageState extends State<TrainTrackingPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _loadingController;
  late AnimationController _searchBarController;
  late AnimationController _bottomPanelController;
  
  // Animations
  late Animation<double> _loadingAnimation;
  late Animation<double> _searchBarHeightAnimation;
  late Animation<double> _bottomPanelAnimation;
  
  // Map and Markers
  final MapController _mapController = MapController();
  final List<Marker> _allMarkers = [];
  final List<Marker> _visibleMarkers = [];
  List<List<LatLng>> railPolylines = [];
  
  // Database Management
  List<DatabaseInfo> _databases = [];
  int _currentDatabaseIndex = 0;
  bool _isConnected = false;
  bool _isLoading = false;
  LoadingType _loadingType = LoadingType.definite;
  
  // Search and Error Handling
  String _searchHint = "Search vehicles...";
  String? _errorMessage;
  double _searchBarHeight = 50.0;
  
  // Selected Marker
  Map<String, dynamic>? _selectedMarkerData;
  String? _selectedMarkerId;
  bool _isBottomPanelVisible = false;
  
  // Real-time connections
  RealtimeChannel? _generalChannel;
  RealtimeChannel? _specificChannel;
  Timer? _dataRefreshTimer;
  
  // Theme Colors
  static const Color _primaryBlue = Color(0xFF2196F3);
  static const Color _primaryPurple = Color(0xFF9C27B0);
  static const Color _surfaceColor = Color(0xFFF5F5F5);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF212121);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _successColor = Color.fromARGB(255, 76, 163, 175);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDatabases();
    _initializeApp();
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _searchBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bottomPanelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));
    
    _searchBarHeightAnimation = Tween<double>(
      begin: 50.0,
      end: 120.0,
    ).animate(CurvedAnimation(
      parent: _searchBarController,
      curve: Curves.easeInOut,
    ));
    
    _bottomPanelAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _bottomPanelController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _initializeDatabases() {
    // Mock database information - replace with actual API call
    _databases = [
      DatabaseInfo(id: 1, name: "Supabase 1", load: 0.0, isActive: true),
      DatabaseInfo(id: 2, name: "Database 2", load: 0.0, isActive: true),
      DatabaseInfo(id: 3, name: "Database 3", load: 0.0, isActive: true),
    ];
    
    // Select the best database (lowest load)
    _currentDatabaseIndex = 0;
    }

  void _initializeApp() {
    _connectToDatabase(_currentDatabaseIndex);
    _startDataRefreshTimer();
  }

void _startDataRefreshTimer() {
  _dataRefreshTimer?.cancel();
  _dataRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
    if (_isConnected && !_isLoading && mounted) { // Add mounted check
      _fetchAllVehicles();
    }
  });
}

Future<void> _connectToDatabase(int index) async {
  if (index < 0 || index >= _databases.length) return;

  if (!mounted) return; // Add mounted check
  setState(() {
    _isLoading = true;
    _loadingType = LoadingType.definite;
    _currentDatabaseIndex = index;
    _searchHint = "Connecting to ${_databases[index].name}...";
    _errorMessage = null;
  });

  _startLoadingAnimation();

  try {
    // Disconnect from previous channels
    await _disconnectChannels();

    // Connect to new database channel
    _generalChannel = Supabase.instance.client.channel('vehicles_locations');

    // Fetch initial data
    await _fetchAllVehicles();

    if (!mounted) return; // Add mounted check
    setState(() {
      _isConnected = true;
      _isLoading = false;
      _searchHint = "Search vehicles...";
    });

    _stopLoadingAnimation();
  } catch (e) {
    if (!mounted) return; // Add mounted check
    setState(() {
      _isConnected = false;
      _isLoading = false;
      _errorMessage = e.toString();
      _searchHint = "Connection failed";
    });
    _stopLoadingAnimation();
    _showError(e.toString());
  }
}
/*  void _subscribeToGeneralUpdates() {
    _generalChannel?.onBroadcast(
      event: 'location_update',
      callback: (payload) {
        if (_selectedMarkerId != null) return; // Skip if in focused mode
        
        final driverId = payload['driver_id']?.toString() ?? '';
        final vehicleData = _processVehicleData(payload);
        
        if (vehicleData != null) {
          _updateMarker(driverId, vehicleData);
        }
      },
    ).subscribe((status, error) {
      if (status != 'SUBSCRIBED') {
        _showError("Failed to subscribe to real-time updates: ${error?.toString() ?? 'Unknown error'}");
      }
    });
  } */

  void _subscribeToSpecificVehicle(String vehicleId) {
    _specificChannel?.unsubscribe();
    _specificChannel = Supabase.instance.client
      .channel('vehicle_$vehicleId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'vehicles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'driver_id',
          value: vehicleId,
        ),
        callback: (payload) async {
          final vehicleData = _processVehicleData(payload.newRecord);
          _updateSelectedMarker(vehicleData as Map<String, dynamic>);
                },
      ).subscribe((status, [error]) {
        // ignore: unrelated_type_equality_checks
        if (status != 'SUBSCRIBED') {
          _showError("Failed to subscribe to vehicle updates: ${error?.toString() ?? 'Unknown error'}");
        }
      });
  }

  Future<Map<String, dynamic>?> _processVehicleData(Map<String, dynamic> payload) async {
    try {
      final numberPlate = payload['number_plate']?.toString() ?? '';
      final lat = double.tryParse(payload['lat']?.toString() ?? '0') ?? 0.0;
      final lng = double.tryParse(payload['lng']?.toString() ?? '0') ?? 0.0;
      
      // Get additional data from local database based on number plate
      final localData = await _getLocalVehicleData(numberPlate);
      
      return {
        'id': payload['driver_id']?.toString() ?? '',
        'numberPlate': numberPlate,
        'lat': lat,
        'lng': lng,
        'speed': payload['speed']?.toString() ?? '0 km/h',
        'passengers': payload['passengers']?.toString() ?? '0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'route': localData['route'],
        'driver': localData['driver'],
        'capacity': localData['capacity'],
        'type': localData['type'],
        'nextStops': localData['nextStops'],

      };
    } catch (e) {
      _showError("Error processing vehicle data: $e");
      return null;
    }
  }

  Future <Map<String, dynamic>> _getLocalVehicleData(String numberPlate) async{
    // Mock local database lookup - replace with actual local database query
    return {
      'route': 'Route ${numberPlate.substring(0, 2)}',
      'driver': 'Driver ${numberPlate.substring(2)}',
      'capacity': '45',
      'type': 'Bus',
      'nextStops': ['Stop A', 'Stop B', 'Stop C'],
    };
  }

Future<void> _fetchAllVehicles() async {
  try {
    if (!mounted) return; // Add mounted check
    setState(() {
      _isLoading = true;
      _loadingType = LoadingType.definite;
    });

    _startLoadingAnimation();

    // Mock API call - replace with actual API endpoint
    final response = await Supabase.instance.client
        .from('vehicles')
        .select();

    final vehicles = response;
    _updateAllMarkers(vehicles); // Await since _updateAllMarkers is async

    if (!mounted) return; // Add mounted check
    setState(() {
      _isLoading = false;
    });

    _stopLoadingAnimation();
  } catch (e) {
    if (!mounted) return; // Add mounted check
    setState(() {
      _isLoading = false;
    });
    _stopLoadingAnimation();
    _showError("Failed to fetch vehicles: $e");
  }
}

  void _updateAllMarkers(List<dynamic> vehicles) async{
    _allMarkers.clear();
    
    for (final vehicle in vehicles) {
      final vehicleData = await _processVehicleData(vehicle);
      if (vehicleData != null) {
        final marker = _createMarker(vehicleData);
        _allMarkers.add(await marker);
      }
    }
    
    _updateVisibleMarkers();
  }

  void _updateMarker(String vehicleId, Map<String, dynamic> vehicleData) async{
    final processedVehicleData = await _processVehicleData(vehicleData);
    if (processedVehicleData == null) return;
    final existingIndex = _allMarkers.indexWhere((m) => m.key == Key(vehicleId));
    
    if (existingIndex >= 0) {
      _allMarkers[existingIndex] = await _createMarker(vehicleData);
    } else {
      _allMarkers.add(await _createMarker(vehicleData));
    }
    
    _updateVisibleMarkers();
  }

void _updateSelectedMarker(Map<String, dynamic> vehicleData) async {
  if (!mounted) return; // Add mounted check
  setState(() {
    _selectedMarkerData = vehicleData;
  });

  // Update marker position smoothly
  final newPosition = LatLng(vehicleData['lat'], vehicleData['lng']);
  _mapController.move(newPosition, _mapController.camera.zoom);

  _updateMarker(vehicleData['id'], vehicleData);
}

void _updateVisibleMarkers() {
  if (!mounted) return; // Add mounted check
  setState(() {
    if (_selectedMarkerId != null) {
      // Show only selected marker
      _visibleMarkers.clear();
      final selectedMarker = _allMarkers.firstWhere(
        (m) => m.key == Key(_selectedMarkerId!),
        orElse: () => _allMarkers.first,
      );
      _visibleMarkers.add(selectedMarker);
    } else {
      // Show all markers
      _visibleMarkers.clear();
      _visibleMarkers.addAll(_allMarkers);
    }
  });
}

  Future<Marker> _createMarker(Map<String, dynamic> vehicleData) async {
    final vehicleId = vehicleData['id'];
    final position = LatLng(vehicleData['lat'], vehicleData['lng']);
    
    return Marker(
      key: Key(vehicleId),
      point: position,
      height: 60,
      width: 60,
      child: GestureDetector(
        onTap: () async => _onMarkerTapped(vehicleId, vehicleData),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _selectedMarkerId == vehicleId ? const Color.fromARGB(132, 155, 39, 176) : const Color.fromARGB(129, 50, 125, 187),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(52, 0, 0, 0),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  void _onMarkerTapped(String vehicleId, Map<String, dynamic> vehicleData) {
  if (!mounted) return; // Add mounted check
  setState(() {
    _selectedMarkerId = vehicleId;
    _selectedMarkerData = vehicleData;
    _isBottomPanelVisible = true;
  });

  // Focus on selected marker
  _updateVisibleMarkers();

  // Move map to marker
  final position = LatLng(vehicleData['lat'], vehicleData['lng']);
  _mapController.move(position, 15.0);

  // Subscribe to live updates for this vehicle
  _subscribeToSpecificVehicle(vehicleId);

  // Show bottom panel
  _bottomPanelController.forward();
}

void _closeBottomPanel() {
  _bottomPanelController.reverse().then((_) {
    if (!mounted) return; // Add mounted check
    setState(() {
      _selectedMarkerId = null;
      _selectedMarkerData = null;
      _isBottomPanelVisible = false;
    });

    // Show all markers again
    _updateVisibleMarkers();

    // Disconnect from specific vehicle updates
    _specificChannel?.unsubscribe();
    _specificChannel = null;
  });
}

  void _startLoadingAnimation() {
    if (_loadingType == LoadingType.definite) {
      _loadingController.repeat();
    } else {
      _loadingController.repeat(reverse: true);
    }
  }

  void _stopLoadingAnimation() {
    _loadingController.stop();
    _loadingController.reset();
  }

void _showError(String message) {
  if (!mounted) return; // Add mounted check
  setState(() {
    _errorMessage = message;
    _searchBarHeight = _calculateSearchBarHeight(message);
  });

  _searchBarController.forward();

  // Auto-hide error after 5 seconds
  Timer(const Duration(seconds: 5), () {
    if (!mounted) return; // Add mounted check
    _hideError();
  });
}

  /*void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }*/

void _hideError() {
  if (!mounted) return; // Add mounted check
  setState(() {
    _errorMessage = null;
    _searchBarHeight = 50.0;
  });
  _searchBarController.reverse();
}

  double _calculateSearchBarHeight(String message) {
    final lines = (message.length / 40).ceil();
    return math.max(50.0, math.min(120.0, 50.0 + (lines - 1) * 20.0));
  }

  Future<void> _disconnectChannels() async {
    await _generalChannel?.unsubscribe();
    await _specificChannel?.unsubscribe();
    _generalChannel = null;
    _specificChannel = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(6.927079, 79.861244),
                initialZoom: 13.0,

              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  //subdomains: const ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: railPolylines.map((railLine) {
                    return Polyline(
                      points: railLine,
                      color: const Color.fromARGB(148, 33, 149, 243),
                      strokeWidth: 4.0,
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: _visibleMarkers,
                ),
              ],
            ),
          ),
          
          // Search Bar
          _buildSearchBar(),
          
          // Database Selection
          _buildDatabaseSelection(),
          
          // Bottom Panel
          if (_isBottomPanelVisible) _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 40,
      left: 50,
      right: 50,
      child: AnimatedBuilder(
        animation: _searchBarHeightAnimation,
        builder: (context, child) {
          return Container(
            height: _errorMessage != null ? _searchBarHeightAnimation.value : 50,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(24, 0, 0, 0),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 47,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        _errorMessage != null ? Icons.error : Icons.search,
                        color: _errorMessage != null ? _errorColor : _textSecondary,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: _searchHint,
                            hintStyle: TextStyle(
                              color: _errorMessage != null ? _errorColor : _textSecondary,
                            ),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            color: _errorMessage != null ? _errorColor : _textPrimary,
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: _errorColor),
                          onPressed: _hideError,
                        ),
                    ],
                  ),
                ),
                
                // Loading indicator line
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      if (!_isLoading) {
                        return Container(
                          decoration: BoxDecoration(
                            color: _isConnected ? const Color.fromARGB(120, 39, 212, 255) : const Color.fromARGB(127, 255, 38, 38),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }
                      
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: LinearProgressIndicator(
                          value: _loadingType == LoadingType.definite ? _loadingAnimation.value : null,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _loadingType == LoadingType.definite ? _primaryBlue : _primaryPurple,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Error message
                if (_errorMessage != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: _errorColor,
                          fontSize: 12,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatabaseSelection() {
    return Positioned(
      top: _errorMessage != null ? 120 + _searchBarHeight : 120,
      left: 10,
      right: 10,
      child: SizedBox(
        height: 35,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _databases.length,
          itemBuilder: (context, index) {
            final db = _databases[index];
            final isSelected = index == _currentDatabaseIndex;
            final isActive = db.isActive;
            
            return Container(
              margin: const EdgeInsets.only(right: 24),
              child: GestureDetector(
                onTap: isActive ? () => _connectToDatabase(index) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0.1),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryBlue : _cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _primaryBlue : const Color.fromARGB(255, 224, 224, 224),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(26, 0, 0, 0),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        db.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 0.01),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? (db.load < 0.5 ? _successColor : db.load < 0.8 ? Colors.orange : _errorColor)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${(db.load * 100).toInt()}%',
                            style: TextStyle(
                              color: isSelected ? Colors.white : _textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return AnimatedBuilder(
      animation: _bottomPanelAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * _bottomPanelAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(24, 0, 0, 0),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeBottomPanel,
                  ),
                ),
                
                // Content
                Expanded(
                  child: _selectedMarkerData != null
                      ? _buildBottomPanelContent()
                      : const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomPanelContent() {
    final data = _selectedMarkerData!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vehicle Header
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['numberPlate'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    data['route'] ?? 'Unknown Route',
                    style: const TextStyle(
                      fontSize: 16,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard('Speed', data['speed'] ?? '0 km/h', Icons.speed, _primaryBlue),
            _buildStatCard('Passengers', '${data['passengers'] ?? '0'}/${data['capacity'] ?? '0'}', Icons.people, _primaryPurple),
            _buildStatCard('Driver', data['driver'] ?? 'Unknown', Icons.person, Colors.green),
            _buildStatCard('Type', data['type'] ?? 'Bus', Icons.directions_bus, Colors.orange),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Next Stops
        const Text(
          'Next Stops',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...List.generate(
          (data['nextStops'] as List?)?.length ?? 0,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: index == 0 ? _primaryBlue : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                color: index == 0 ? _primaryBlue : Colors.grey.shade300,
              ),]
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: index == 0 ? _primaryBlue : _textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['nextStops'][index],
                    style: TextStyle(
                      fontSize: 16,
                      color: index == 0 ? _primaryBlue : _textPrimary,
                      fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (index == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Last Updated
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.update, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${_formatTimestamp(data['timestamp'])}',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Color.fromARGB(25, color.red, color.green, color.blue), // Replace .withOpacity(0.1)
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Color.fromARGB(76, color.red, color.green, color.blue), // Replace .withOpacity(0.3)
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final now = DateTime.now();
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(time);
    
    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _searchBarController.dispose();
    _bottomPanelController.dispose();
    _dataRefreshTimer?.cancel();
    _disconnectChannels();
    super.dispose();
  }
}

// Supporting Classes and Enums
class DatabaseInfo {
  final int id;
  final String name;
  final double load;
  final bool isActive;

  DatabaseInfo({
    required this.id,
    required this.name,
    required this.load,
    required this.isActive,
  });
}

enum LoadingType {
  definite,
  indefinite,
}
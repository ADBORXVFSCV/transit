// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class AddJourneyPage extends StatefulWidget {
  const AddJourneyPage({super.key});

  @override
  State<AddJourneyPage> createState() => _AddJourneyPageState();
}

class _AddJourneyPageState extends State<AddJourneyPage>
    with TickerProviderStateMixin {
  late AnimationController _dogController;
  late AnimationController _formController;
  late AnimationController _cardController;
  late Animation<double> _dogAnimation;
  late Animation<double> _formAnimation;
  late Animation<Offset> _cardSlideAnimation;

  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Form data
  String _vehicleType = '';
  String _startingPoint = '';
  String _endingPoint = '';
  Map<String, dynamic>? _selectedRoute;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Map<String, dynamic>? _selectedVehicle;
  String _drivingType = '';

  // Interactive dog states
  final List<String> _dogExpressions = ['😊', '🐕', '🐶', '🥰', '😍', '🤩', '✨'];
  String _currentDogExpression = '🐕';
  String _dogMessage = "Let's plan your journey together!";

  // Mock data (these would come from your encrypted local database)
  final List<String> _vehicleTypes = [
    'Bus', 'Train', 'Metro', 'Taxi', 'Uber', 'Pickup', 'Van', 'Car'
  ];

  final List<String> _drivingTypes = [
    'Fast', 'Slow', 'Mixed', 'High Speed', 'Normal', 'Not Sure', 'A Ticket to Hell'
  ];

  final List<Map<String, dynamic>> _mockRoutes = [
    {
      'id': 'route_1',
      'name': 'Galle - Colombo Express',
      'stops': [
        {'name': 'Galle Fort', 'waitTime': 2, 'coordinates': [80.2168, 6.0329]},
        {'name': 'Hikkaduwa', 'waitTime': 3, 'coordinates': [80.0982, 6.1371]},
        {'name': 'Bentota', 'waitTime': 2, 'coordinates': [80.0034, 6.4260]},
        {'name': 'Kalutara', 'waitTime': 5, 'coordinates': [79.9553, 6.5854]},
        {'name': 'Panadura', 'waitTime': 3, 'coordinates': [79.9044, 6.7132]},
        {'name': 'Colombo Fort', 'waitTime': 0, 'coordinates': [79.8441, 6.9319]}
      ],
      'distance': 119.0,
      'estimatedTime': '2h 30min'
    },
    {
      'id': 'route_2', 
      'name': 'Colombo - Kandy Hill Route',
      'stops': [
        {'name': 'Colombo Central', 'waitTime': 0, 'coordinates': [79.8612, 6.9271]},
        {'name': 'Kegalle', 'waitTime': 10, 'coordinates': [80.3464, 7.2513]},
        {'name': 'Mawanella', 'waitTime': 5, 'coordinates': [80.4544, 7.2507]},
        {'name': 'Kandy City', 'waitTime': 0, 'coordinates': [80.6337, 7.2906]}
      ],
      'distance': 115.0,
      'estimatedTime': '3h 15min'
    }
  ];

  final List<Map<String, dynamic>> _mockVehicles = [
    {
      'id': 'bus_001',
      'name': 'Express Bus #245',
      'type': 'Bus',
      'capacity': 45,
      'amenities': ['AC', 'WiFi', 'USB Charging'],
      'rating': 4.2
    },
    {
      'id': 'train_001',
      'name': 'Intercity Express',
      'type': 'Train', 
      'capacity': 200,
      'amenities': ['AC', 'Restaurant', 'WiFi'],
      'rating': 4.5
    }
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startDogAnimation();
  }

  void _initAnimations() {
    _dogController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _dogAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dogController, curve: Curves.elasticOut),
    );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeInOut),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _formController.forward();
    _cardController.forward();
  }

  void _startDogAnimation() {
    _dogController.repeat(reverse: true);
  }

  void _updateDogReaction(String context) {
    setState(() {
      switch (context) {
        case 'vehicle_selected':
          _currentDogExpression = _dogExpressions[3]; // 🥰
          _dogMessage = "Great choice! I love that vehicle!";
          break;
        case 'route_selected':
          _currentDogExpression = _dogExpressions[4]; // 😍
          _dogMessage = "Perfect route! This will be amazing!";
          break;
        case 'time_selected':
          _currentDogExpression = _dogExpressions[5]; // 🤩
          _dogMessage = "Excellent timing! You're a planner!";
          break;
        case 'hell_ticket':
          _currentDogExpression = '😈';
          _dogMessage = "Whoa! Someone's feeling adventurous!";
          break;
        case 'validation_error':
          _currentDogExpression = '😔';
          _dogMessage = "Oops! Let's fix those missing details.";
          break;
        case 'saving':
          _currentDogExpression = _dogExpressions[6]; // ✨
          _dogMessage = "Saving your journey... Almost there!";
          break;
        default:
          _currentDogExpression = _dogExpressions[1]; // 🐕
          _dogMessage = "I'm here to help you plan!";
      }
    });
  }

  @override
  void dispose() {
    _dogController.dispose();
    _formController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildInteractiveDog() {
    return AnimatedBuilder(
      animation: _dogAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              Transform.scale(
                scale: 1.0 + (_dogAnimation.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(26, 52, 152, 219),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(50, 52, 152, 219),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Text(
                    _currentDogExpression,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(29, 0, 0, 0),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Text(
                  _dogMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(_totalPages, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? const Color(0xFF3498DB)
                    : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage1_VehicleType() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Vehicle Type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'What type of vehicle will you be traveling with?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _vehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicleTypes[index];
                  final isSelected = _vehicleType == vehicle;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _vehicleType = vehicle;
                      });
                      _updateDogReaction('vehicle_selected');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color.fromARGB(26, 52, 152, 219)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF3498DB)
                              : const Color(0xFFE8E8E8),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(10, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getVehicleIcon(vehicle),
                            size: 40,
                            color: isSelected 
                                ? const Color(0xFF3498DB)
                                : const Color(0xFF7F8C8D),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            vehicle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? const Color(0xFF3498DB)
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2_RouteSelection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: const Text(
                'Select Route & Points',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Starting Point
            _buildLocationInput(
              'Starting Point',
              _startingPoint,
              (value) => setState(() => _startingPoint = value),
              Icons.location_on,
            ),
            
            const SizedBox(height: 16),
            
            // Ending Point  
            _buildLocationInput(
              'Ending Point',
              _endingPoint,
              (value) => setState(() => _endingPoint = value),
              Icons.flag,
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Available Routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            
            const SizedBox(height: 15),
            
            Expanded(
              child: ListView.builder(
                itemCount: _mockRoutes.length,
                itemBuilder: (context, index) {
                  final route = _mockRoutes[index];
                  final isSelected = _selectedRoute?['id'] == route['id'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRoute = route;
                      });
                      _updateDogReaction('route_selected');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color.fromARGB(28, 52, 152, 219)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF3498DB)
                              : const Color(0xFFE8E8E8),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(14, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? const Color(0xFF3498DB)
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(26, 46, 204, 112),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  route['estimatedTime'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2ECC71),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${route['stops'].length} stops • ${route['distance']} km',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage3_TimeAndVehicle() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time & Vehicle Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),
            
            // Time Selection
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    'Start Time',
                    _startTime,
                    (time) => setState(() => _startTime = time),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    'End Time',
                    _endTime,
                    (time) => setState(() => _endTime = time),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              'Select Your Vehicle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            
            const SizedBox(height: 15),
            
            Expanded(
              child: ListView.builder(
                itemCount: _mockVehicles
                    .where((v) => v['type'] == _vehicleType)
                    .length,
                itemBuilder: (context, index) {
                  final vehicle = _mockVehicles
                      .where((v) => v['type'] == _vehicleType)
                      .toList()[index];
                  final isSelected = _selectedVehicle?['id'] == vehicle['id'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicle = vehicle;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color.fromARGB(28, 52, 152, 219)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF3498DB)
                              : const Color(0xFFE8E8E8),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? const Color(0xFF3498DB)
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  Text(' ${vehicle['rating']}'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capacity: ${vehicle['capacity']} passengers',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: (vehicle['amenities'] as List)
                                .map((amenity) => Chip(
                                      label: Text(amenity),
                                      backgroundColor: const Color(0xFF2ECC71).withOpacity(0.1),
                                      labelStyle: const TextStyle(fontSize: 12),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage4_DrivingType() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driving Style',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'How would you describe your driving style for this journey?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _drivingTypes.length,
                itemBuilder: (context, index) {
                  final type = _drivingTypes[index];
                  final isSelected = _drivingType == type;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _drivingType = type;
                      });
                      if (type == 'A Ticket to Hell') {
                        _updateDogReaction('hell_ticket');
                      } else {
                        _updateDogReaction('time_selected');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? _getDrivingTypeColor(type).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected 
                              ? _getDrivingTypeColor(type)
                              : const Color(0xFFE8E8E8),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(10, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDrivingTypeEmoji(type),
                            style: const TextStyle(fontSize: 30),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? _getDrivingTypeColor(type)
                                  : const Color(0xFF2C3E50),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput(String label, String value, Function(String) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF3498DB)),
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF3498DB), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, Function(TimeOfDay) onTimeSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final selectedTime = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (selectedTime != null) {
              onTimeSelected(selectedTime);
              _updateDogReaction('time_selected');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8E8E8)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF3498DB)),
                const SizedBox(width: 12),
                Text(
                  time?.format(context) ?? 'Select time',
                  style: TextStyle(
                    fontSize: 16,
                    color: time != null ? const Color(0xFF2C3E50) : const Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveJourney,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: const Text(
          'Save Journey',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF95A5A6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          if (_currentPage < _totalPages - 1)
            Expanded(
              child: ElevatedButton(
                onPressed: _canProceedToNext() ? () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canProceedToNext() {
    switch (_currentPage) {
      case 0:
        return _vehicleType.isNotEmpty;
      case 1:
        return _startingPoint.isNotEmpty && 
               _endingPoint.isNotEmpty && 
               _selectedRoute != null;
      case 2:
        return _startTime != null && 
               _endTime != null && 
               _selectedVehicle != null;
      default:
        return true;
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'train':
        return Icons.train;
      case 'metro':
        return Icons.subway;
      case 'taxi':
      case 'uber':
        return Icons.local_taxi;
      case 'pickup':
      case 'van':
        return Icons.local_shipping;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.directions_transit;
    }
  }

  Color _getDrivingTypeColor(String type) {
    switch (type) {
      case 'Fast':
      case 'High Speed':
        return const Color(0xFFE74C3C);
      case 'Slow':
        return const Color(0xFF2ECC71);
      case 'Mixed':
      case 'Normal':
        return const Color(0xFF3498DB);
      case 'Not Sure':
        return const Color(0xFF95A5A6);
      case 'A Ticket to Hell':
        return const Color(0xFF8E44AD);
      default:
        return const Color(0xFF3498DB);
    }
  }

  String _getDrivingTypeEmoji(String type) {
    switch (type) {
      case 'Fast':
        return '🏎️';
      case 'Slow':
        return '🐌';
      case 'Mixed':
        return '🔄';
      case 'High Speed':
        return '⚡';
      case 'Normal':
        return '🚗';
      case 'Not Sure':
        return '🤷';
      case 'A Ticket to Hell':
        return '😈';
      default:
        return '🚗';
    }
  }

  Future<void> _saveJourney() async {
    if (!_validateForm()) {
      _updateDogReaction('validation_error');
      return;
    }

    _updateDogReaction('saving');

    try {
      final journeyData = {
        'vehicle_type': _vehicleType,
        'starting_point': _startingPoint,
        'ending_point': _endingPoint,
        'route_data': jsonEncode(_selectedRoute),
        'start_time': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        'vehicle_data': jsonEncode(_selectedVehicle),
        'driving_type': _drivingType,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'scheduled'
      };

      // Save to Supabase
      await _saveToSupabase(journeyData);
      
      // Save to local encrypted file
      await _saveToLocalStorage(journeyData);

      _showSuccessNotification();
      
      // Navigate back with success
      Navigator.pop(context, true);
      
    } catch (e) {
      _showErrorNotification(e.toString());
    }
  }

  bool _validateForm() {
    if (_vehicleType.isEmpty) return false;
    if (_startingPoint.isEmpty || _endingPoint.isEmpty) return false;
    if (_selectedRoute == null) return false;
    if (_startTime == null || _endTime == null) return false;
    if (_selectedVehicle == null) return false;
    if (_drivingType.isEmpty) return false;
    return true;
  }

  Future<void> _saveToSupabase(Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    
    await supabase.from('schedule').insert(data);
  }

  Future<void> _saveToLocalStorage(Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/schedules.enc');
      
      List<Map<String, dynamic>> schedules = [];
      
      // Read existing data if file exists
      if (await file.exists()) {
        final encryptedContent = await file.readAsString();
        final decryptedContent = _decrypt(encryptedContent);
        schedules = List<Map<String, dynamic>>.from(jsonDecode(decryptedContent));
      }
      
      // Add new schedule
      schedules.add(data);
      
      // Encrypt and save
      final jsonContent = jsonEncode(schedules);
      final encryptedContent = _encrypt(jsonContent);
      
      await file.writeAsString(encryptedContent);
      print('saved to local storage');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  String _encrypt(String data) {
    // Simple encryption (in production, use proper encryption)
    final bytes = utf8.encode(data);
    final _ = sha256.convert(bytes);
    return base64.encode(bytes);
  }

  String _decrypt(String encryptedData) {
    // Simple decryption (in production, use proper decryption)
    final bytes = base64.decode(encryptedData);
    return utf8.decode(bytes);
  }

  void _showSuccessNotification() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _buildNotificationDialog(
          '✅',
          'Journey Added Successfully!',
          'Your journey has been scheduled and saved.',
          const Color(0xFF2ECC71),
        );
      },
    );
  }

  void _showErrorNotification(String error) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _buildNotificationDialog(
          '❌',
          'Error Saving Journey',
          'There was an error saving your journey: $error',
          const Color(0xFFE74C3C),
        );
      },
    );
  }

  Widget _buildNotificationDialog(String emoji, String title, String message, Color color) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Journey',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildInteractiveDog(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage1_VehicleType(),
                  _buildPage2_RouteSelection(),
                  _buildPage3_TimeAndVehicle(),
                  _buildPage4_DrivingType(),
                ],
              ),
            ),
            if (_currentPage < _totalPages - 1)
              _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }
}
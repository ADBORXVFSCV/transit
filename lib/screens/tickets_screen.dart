// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:myapp/screens/add_journey.dart';
import '../widgets/LocalDatabase.dart';

class JourneyPage extends StatefulWidget {
  final String? initialJourneyId;
  const JourneyPage({super.key, this.initialJourneyId});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> 
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _clockController;
  late AnimationController _listController;
  late AnimationController _floatingController;
  late AnimationController _backgroundController;
  
  // Animations
  late Animation<double> _clockAnimation;
  late Animation<double> _listAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<Color?> _colorAnimation;

  // State Variables
  Timer? _timeTimer;
  DateTime _currentTime = DateTime.now();
  bool _isLoading = true;
  List<JourneyRoute> _routes = [];
  bool _hasActiveJourney = false;
  String _nextDestination = '';
  String _nextDepartureTime = '';
  String _finalArrivalTime = '';
  int _selectedQuoteIndex = 0;

  // Enhanced Motivational Quotes with emojis
  final List<Map<String, String>> _motivationalQuotes = [
    {
      "text": "You are keeping 10000 of life at a day",
      "emoji": "⚡",
      "color": "0xFF3498DB"
    },
    {
      "text": "Every journey begins with a single step",
      "emoji": "🚶‍♂️", 
      "color": "0xFF2ECC71"
    },
    {
      "text": "Time is precious, use it wisely",
      "emoji": "⏰",
      "color": "0xFFE67E22"
    },
    {
      "text": "Your destination is worth the journey",
      "emoji": "🎯",
      "color": "0xFF9B59B6"
    },
    {
      "text": "Progress, not perfection",
      "emoji": "📈",
      "color": "0xFFE74C3C"
    },
    {
      "text": "Small steps, big dreams",
      "emoji": "✨",
      "color": "0xFF1ABC9C"
    },
    {
      "text": "Every mile matters",
      "emoji": "🛤️",
      "color": "0xFFF39C12"
    },
    {
      "text": "Journey with purpose",
      "emoji": "🧭",
      "color": "0xFF8E44AD"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _startTimeTimer();
    _fetchJourneys();
    _startBackgroundAnimation();
  }

  void _initializeAnimations() {
    _clockController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _clockAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _clockController,
      curve: Curves.elasticOut,
    ));

    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _colorAnimation = ColorTween(
      begin: const Color(0xFFF8F9FA),
      end: const Color(0xFFE8F4F8),
    ).animate(_backgroundController);
  }

  void _startAnimationSequence() {
    _clockController.forward();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _listController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _floatingController.repeat(reverse: true);
    });
  }

  void _startBackgroundAnimation() {
    _backgroundController.repeat(reverse: true);
  }

  void _startTimeTimer() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _fetchJourneys() async {
    try {
      final localDb = LocalDatabase();
      final schedules = await localDb.getSchedules();
      
      if (mounted) {
        setState(() {
          _routes = schedules.map((s) => JourneyRoute(
            id: s['schedule_id'].toString(),
            startCity: s['start_city'],
            endCity: s['end_city'],
            startTime: s['start_time'],
            endTime: s['end_time'],
            distance: s['distance'],
            status: s['status'],
          )).toList();
          _determineActiveJourney();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _determineActiveJourney() {
    try {
      final activeRoute = _routes.firstWhere(
        (r) => r.status == 'active',
      );

      _hasActiveJourney = true;
      _nextDestination = activeRoute.endCity;
      _nextDepartureTime = activeRoute.startTime;
      _finalArrivalTime = activeRoute.endTime;
    } catch (e) {
      _hasActiveJourney = false;
      _nextDestination = '';
      _nextDepartureTime = '';
      _finalArrivalTime = '';
    }
  }

  @override
  void dispose() {
    _clockController.dispose();
    _listController.dispose();
    _floatingController.dispose();
    _backgroundController.dispose();
    _timeTimer?.cancel();
    super.dispose();
  }

  // Utility Methods
  double _calculateSpeed(JourneyRoute route) {
    final start = _parseTime(route.startTime);
    final end = _parseTime(route.endTime);
    final durationMinutes = end.difference(start).inMinutes;
    if (durationMinutes <= 0) return 0;
    return (route.distance / durationMinutes) * 60;
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year, 
      now.month, 
      now.day, 
      int.parse(parts[0]), 
      int.parse(parts[1])
    );
  }

  Color _getSpeedColor(double speed) {
    if (speed < 10) return Colors.red.withOpacity(0.15);
    if (speed < 30) return Colors.orange.withOpacity(0.15);
    if (speed < 60) return Colors.amber.withOpacity(0.15);
    return Color.lerp(
      Colors.blue.withOpacity(0.15),
      Colors.purple.withOpacity(0.25),
      math.min(1.0, (speed - 60) / 100)
    )!;
  }

  String get _dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[_currentTime.weekday - 1];
  }

  Map<String, String> get _currentQuote => 
    _motivationalQuotes[_selectedQuoteIndex];

  // Dialog Methods
  void _showDeleteConfirmation(JourneyRoute route) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white,
          elevation: 20,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFE74C3C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cancel Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Are you sure you want to cancel the scheduled journey from ${route.startCity} to ${route.endCity} at ${route.startTime}?',
              style: const TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Keep',
                style: TextStyle(
                  color: Color(0xFF95A5A6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await LocalDatabase().deleteSchedule(int.parse(route.id));
                  setState(() {
                    _routes.removeWhere((r) => r.id == route.id);
                    _determineActiveJourney();
                  });
                  if (mounted) Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Journey cancelled successfully'),
                      backgroundColor: const Color(0xFF2ECC71),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  if (mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to cancel journey'),
                      backgroundColor: const Color(0xFFE74C3C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Cancel Journey',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancelCurrentJourney() {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white,
          elevation: 20,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFE74C3C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cancel Current Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Are you sure you want to cancel your current journey to $_nextDestination? This action cannot be undone.',
              style: const TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Keep Going',
                style: TextStyle(
                  color: Color(0xFF95A5A6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (_hasActiveJourney) {
                    final activeRoute = _routes.firstWhere((r) => r.status == 'active');
                    await LocalDatabase().deleteSchedule(int.parse(activeRoute.id));
                    setState(() {
                      _routes.removeWhere((r) => r.id == activeRoute.id);
                      _hasActiveJourney = false;
                      _nextDestination = '';
                      _nextDepartureTime = '';
                      _finalArrivalTime = '';
                    });
                  }
                  if (mounted) Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Current journey cancelled'),
                      backgroundColor: const Color(0xFF2ECC71),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  if (mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to cancel journey'),
                      backgroundColor: const Color(0xFFE74C3C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Cancel Journey',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // UI Building Methods
  Widget _buildTopButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopButton(
            icon: Icons.arrow_back_ios_rounded,
            label: _hasActiveJourney ? 'Back' : 'Start Next',
            onTap: () {
              HapticFeedback.lightImpact();
              if (_hasActiveJourney) {
                Navigator.pop(context);
              } else {
                _showStartNextJourney();
              }
            },
          ),
          _buildTopButton(
            icon: _hasActiveJourney ? Icons.close_rounded : Icons.flash_on_rounded,
            label: _hasActiveJourney ? 'Cancel' : 'Quick Journey',
            onTap: () {
              HapticFeedback.lightImpact();
              if (_hasActiveJourney) {
                _showCancelCurrentJourney();
              } else {
                _showQuickJourney();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_floatingAnimation.value * math.pi * 2) * 2),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3498DB).withOpacity(0.1),
                    const Color(0xFF2980B9).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF3498DB).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF3498DB),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF3498DB),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClockSection() {
    return AnimatedBuilder(
      animation: _clockAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _clockAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildClockIcon(Icons.music_note_rounded, () {
                      HapticFeedback.lightImpact();
                      // Navigate to music page
                    }),
                    _buildMainClock(),
                    _buildClockIcon(Icons.person_rounded, () {
                      HapticFeedback.lightImpact();
                      // Navigate to profile page
                    }),
                  ],
                ),
                const SizedBox(height: 25),
                _buildTimeInfo(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClockIcon(IconData icon, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(_floatingAnimation.value * math.pi * 2) * 3,
            math.cos(_floatingAnimation.value * math.pi * 2) * 2,
          ),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3498DB).withOpacity(0.1),
                    const Color(0xFF2980B9).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3498DB).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3498DB),
                size: 26,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainClock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8F9FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_dayOfWeek • ${_currentTime.year}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeInfoItem(
            _nextDepartureTime.isNotEmpty ? _nextDepartureTime : '--:--',
            'Next Departure',
            Icons.departure_board_rounded,
          ),
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3498DB).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          _buildTimeInfoItem(
            _finalArrivalTime.isNotEmpty ? _finalArrivalTime : '--:--',
            'Arrival',
            Icons.location_on_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoItem(String time, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF3498DB),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: Column(
              children: [
                ..._routes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final route = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 150)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: _buildRouteItem(route),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 25),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteItem(JourneyRoute route) {
    final speed = _calculateSpeed(route);
    final speedColor = _getSpeedColor(speed);
    final isActive = route.status == 'active';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            // Show route details
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  speedColor,
                  speedColor.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive 
                  ? const Color(0xFF3498DB).withOpacity(0.4)
                  : const Color(0xFFE8E8E8),
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive 
                    ? const Color(0xFF3498DB).withOpacity(0.2)
                    : Colors.black.withOpacity(0.08),
                  blurRadius: isActive ? 15 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.train_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              route.startCity,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3498DB).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFF3498DB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              route.endCity,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: const Color(0xFF7F8C8D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${route.startTime} - ${route.endTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.speed_rounded,
                            size: 16,
                            color: const Color(0xFF95A5A6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${speed.toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF95A5A6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: route.status == 'active'
                                ? const Color(0xFF2ECC71)
                                : route.status == 'completed'
                                ? const Color(0xFF95A5A6)
                                : const Color(0xFF3498DB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              route.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(route),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFE74C3C),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Add New',
              Icons.add_rounded,
              const Color(0xFF3498DB),
              () => _showAddNewRoute(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              'Import File',
              Icons.upload_file_rounded,
              const Color(0xFF2ECC71),
              () => _showImportFile(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_floatingAnimation.value * math.pi * 2 + 1) * 1.5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationSection() {
    final quote = _currentQuote;
    final quoteColor = Color(int.parse(quote['color']!));
    
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedQuoteIndex = 
                    (_selectedQuoteIndex + 1) % _motivationalQuotes.length;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorAnimation.value ?? const Color(0xFFF8F9FA),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: quoteColor.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: quoteColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: quoteColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        quote['emoji']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '"${quote['text']}"',
                      style: const TextStyle(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF2C3E50),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMotivationButton(
                          'View Productivity',
                          Icons.trending_up_rounded,
                          quoteColor,
                          () => _navigateToProductivity(),
                        ),
                        const SizedBox(width: 12),
                        _buildMotivationButton(
                          'New Quote',
                          Icons.refresh_rounded,
                          const Color(0xFF95A5A6),
                          () {
                            setState(() {
                              _selectedQuoteIndex = 
                                math.Random().nextInt(_motivationalQuotes.length);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Column(
          children: [
            _buildTopButtons(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, math.sin(_floatingAnimation.value * math.pi * 2) * 10),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF95A5A6).withOpacity(0.1),
                              const Color(0xFF95A5A6).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF95A5A6).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.train_rounded,
                          size: 80,
                          color: Color(0xFF95A5A6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'No journeys planned',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add your first journey to get started\non your travel adventure',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7F8C8D),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    _buildActionButton(
                      'Add New Journey',
                      Icons.add_rounded,
                      const Color(0xFF3498DB),
                      () => _showAddNewRoute(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Navigation Methods
  void _showAddNewRoute() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          const AddJourneyPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (result == true) {
      _fetchJourneys();
    }
  }

  void _showImportFile() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('File import feature coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF3498DB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToProductivity() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.white),
            SizedBox(width: 12),
            Text('Productivity dashboard coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF9B59B6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showStartNextJourney() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 12),
            Text('Start next journey feature coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showQuickJourney() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.white),
            SizedBox(width: 12),
            Text('Quick journey feature coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFFE67E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading your journeys...',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _routes.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildTopButtons(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildClockSection(),
                              _buildRoutesList(),
                              _buildMotivationSection(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class JourneyRoute {
  final String id;
  final String startCity;
  final String endCity;
  final String startTime;
  final String endTime;
  final double distance;
  String status;

  JourneyRoute({
    required this.id,
    required this.startCity,
    required this.endCity,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.status,
  });
}
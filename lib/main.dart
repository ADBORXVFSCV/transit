// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'screens/routes_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/futuristic_bottom_navbar.dart';
import 'screens/loading_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/updating_database.dart';
import 'screens/developer.dart';
import 'widgets/LocalDatabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://naocmqbwdfwfeuudiqol.supabase.co',
    anonKey: 'sb_publishable__c-h2ulhTyU2AYkCG2u_wg_6FXpWJrP',
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const InitializationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InitializationScreenState createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String _initStatus = 'Initializing...';
  double _progress = 0.0;
  bool _isFirstLaunch = true;
  final List<String> _googleDriveContent = [
    'https://raw.githubusercontent.com/ADBORXVFSCV/transit/main/download.jpeg'
  ];
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _startInitialization();
    _handleDeepLink();
  }

  Future<void> _handleDeepLink() async {
    try {

      final initialLink = await _appLinks.getInitialAppLink();
      print('Initial Link: $initialLink');
      if (initialLink != null) {
        setState(() {
          _initStatus = 'Processing deep link: $initialLink';
        });
        // Handle the deep link (e.g., navigate to a specific screen)
        _processDeepLink(initialLink.toString());
      }

      // Listen for incoming deep links
      _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          setState(() {
            _initStatus = 'Received deep link: $uri';
          });
          _processDeepLink(uri.toString());
        }
      }, onError: (e) {
        setState(() {
          _initStatus = 'Deep link error: $e';
        });
      });
    } catch (e) {
      setState(() {
        _initStatus = 'Error initializing deep link: $e';
      });
    }
  }

void _processDeepLink(String link) {
  final uri = Uri.parse(link);
  if (uri.scheme == 'myapp') {
    if (uri.host == 'journey' && uri.pathSegments.isNotEmpty) {
      final journeyId = uri.pathSegments.first;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JourneyPage(initialJourneyId: journeyId),
        ),
      );
    } else if (uri.host == 'schedule') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ScheduleScreen()),
      );
    }
  }
}

  Future<void> _startInitialization() async {
    await Future.delayed(const Duration(seconds: 3));
    await _checkFirstLaunch();
    await _initializeApp();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    if (_isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  Future<void> _initializeApp() async {
    // Step 1: Check Internet Connection
    setState(() {
      _initStatus = 'Checking internet connection...';
      _progress = 0.1;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult != ConnectivityResult.none;
    if (!isConnected && !_isFirstLaunch) {
      setState(() {
        _initStatus = 'No internet, using offline mode';
      });
    } else if (!isConnected && _isFirstLaunch) {
      setState(() {
        _initStatus = 'Internet required for first launch';
      });
      return;
    }

    // Step 2: Check Permissions
    setState(() {
      _initStatus = 'Checking permissions...';
      _progress = 0.2;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    final permissions = [
      Permission.location,
      Permission.storage,
      Permission.notification,
    ];
    for (var permission in permissions) {
      if (await permission.isDenied) {
        await permission.request();
      }
    }

    // Step 3: Supabase Auto-Login
    setState(() {
      _initStatus = 'Initializing Supabase...';
      _progress = 0.3;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    bool supabaseConnected = false;
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session != null) {
        setState(() {
          _initStatus = 'Auto-login successful';
        });
      }
      supabaseConnected = true;
    } catch (e) {
      setState(() {
        _initStatus = 'Supabase connection failed: $e';
      });
      if (isConnected && !supabaseConnected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeveloperScreen()),
        );
        return;
      }
    }

    // Step 4: Check Server Load
    setState(() {
      _initStatus = 'Checking server load...';
      _progress = 0.4;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    if (supabaseConnected) {
      try {
        final response = await Supabase.instance.client
            .from('management')
            .select('load')
            .eq('id', '12345678')
            .maybeSingle();
        if (response == null) {
          setState(() {
            _initStatus = 'No matching data found for transit_1';
          });
          return;
        }
        final serverLoad = response['load'] as int?;
        if (serverLoad == null) {
          setState(() {
            _initStatus = 'Server load data not found';
          });
          return;
        }
        if (serverLoad > 90) {
          supabaseConnected = false;
          setState(() {
            _initStatus = 'Server load too high';
          });
          return;
        }
      } catch (e) {
        setState(() {
          _initStatus = 'Error checking server load: $e';
        });
        return;
      }
    }

    // Step 5: Initialize Local Database
    setState(() {
      _initStatus = 'Initializing local database...';
      _progress = 0.5;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    await LocalDatabase().database;

    // Step 6: Check Database Update
    setState(() {
      _initStatus = 'Checking database update...';
      _progress = 0.6;
    });
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt('lastDatabaseUpdate') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final sevenDaysInMillis = 7 * 24 * 60 * 60 * 1000;

    if (_isFirstLaunch || (now - lastUpdate > sevenDaysInMillis && supabaseConnected)) {
      try {
        final response = await Supabase.instance.client
            .from('management')
            .select('is_changed')
            .eq('id', '12345678')
            .maybeSingle();
        final isChanged = response?['is_changed'] as bool? ?? false;

        if (_isFirstLaunch || isChanged) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpdatingDatabaseScreen()),
          );
          return;
        }
      } catch (e) {
        setState(() {
          _initStatus = 'Error checking database update: $e';
        });
      }
    }

    // Step 7: Check Unstopped Journeys
    setState(() {
      _initStatus = 'Checking unstopped journeys...';
      _progress = 0.7;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    // Add logic to check local database for unstopped journeys if needed

    // Step 8: Complete Initialization
    setState(() {
      _initStatus = 'Initialization complete';
      _progress = 1.0;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (_isFirstLaunch) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TransportApp()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LoadingScreen(contentUrls: _googleDriveContent),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(151, 0, 0, 0),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(82, 68, 137, 255),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _initStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: const Color.fromARGB(78, 255, 255, 255),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TransportApp extends StatefulWidget {
  const TransportApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TransportAppState createState() => _TransportAppState();
}

class _TransportAppState extends State<TransportApp> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _navAnimationController;

  final List<Widget> _screens = [
    RoutesScreen(),
    ScheduleScreen(),
    TrainTrackingPage(),
    JourneyPage(initialJourneyId: '',),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _navAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _navAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _screens,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(64, 68, 137, 255),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: FuturisticBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
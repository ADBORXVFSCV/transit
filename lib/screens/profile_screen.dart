// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _achievementsController;
  late AnimationController _settingsController;
  late AnimationController _starsController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _achievementsAnimation;
  late Animation<double> _settingsAnimation;
  late Animation<double> _starsAnimation;

  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  
  // User achievement data
  final Map<String, dynamic> _userStats = {
    'totalJourneys': 156,
    'totalDistance': 2847.5,
    'totalTime': '15 years',
    'averageSpeed': 45.2,
    'carbonSaved': 1.2,
    'punctualityRate': 89.5,
  };

  final List<String> _achievements = [
    'best', 'nice', 'nice', 'good', 'well done', 'wow', 'nice'
  ];

  final List<String> _languages = [
    'English', 'Sinhala', 'Tamil', 'Hindi', 'Spanish', 'French', 'German'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _achievementsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _starsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.01,
      end: 0.99,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    ));

    _achievementsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _achievementsController,
      curve: Curves.easeInOut,
    ));

    _settingsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _settingsController,
      curve: Curves.easeInOut,
    ));

    _starsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starsController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _headerController.forward();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _starsController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      _achievementsController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 900), () {
      _settingsController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _achievementsController.dispose();
    _settingsController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedStars() {
    return AnimatedBuilder(
      animation: _starsAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.elasticOut,
                transform: Matrix4.identity()
                  ..scale(_starsAnimation.value)
                  ..rotateZ(_starsAnimation.value * 2 * math.pi),
                child: Icon(
                  Icons.star,
                  color: const Color(0xFF3498DB),
                  size: 32,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    return AnimatedBuilder(
      animation: _achievementsAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // Achievement words around profile
              // ignore: sized_box_for_whitespace
              Container(
                height: 200,
                width: 800,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Profile avatar in center
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      transform: Matrix4.identity()
                        ..scale(_achievementsAnimation.value),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3498DB),
                              Color(0xFF2980B9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(75, 52, 152, 219),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    // Achievement words positioned around the avatar
                    ..._buildAchievementWords(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stats section
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..translate(0.0, 30 * (1 - _achievementsAnimation.value)),
                child: Opacity(
                  opacity: _achievementsAnimation.value,
                  child: Text(
                    '${_userStats['totalTime']} ${_userStats['totalDistance'].toInt()} km',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAchievementWords() {
    final positions = [
      {'text': 'best', 'top': 20.0, 'left': 80.0},
      {'text': 'nice', 'top': 30.0, 'right': 60.0},
      {'text': 'nice', 'top': 40.0, 'right': 20.0},
      {'text': 'good', 'top': 80.0, 'left': 20.0},
      {'text': 'well done', 'top': 120.0, 'right': 40.0},
      {'text': 'wow', 'bottom': 60.0, 'left': 60.0},
      {'text': 'nice', 'bottom': 40.0, 'right': 70.0},
    ];

    return positions.map((pos) {
      return AnimatedPositioned(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        top: pos['top'] as double?,
        bottom: pos['bottom'] as double?,
        left: pos['left'] as double?,
        right: pos['right'] as double?,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          transform: Matrix4.identity()
            ..scale(_achievementsAnimation.value)
            ..translate(
              20 * (1 - _achievementsAnimation.value),
              10 * (1 - _achievementsAnimation.value),
            ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(26, 52, 152, 219),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color.fromARGB(78, 52, 152, 219),
                width: 1,
              ),
            ),
            child: Text(
              pos['text'] as String,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF3498DB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDashboardTitle() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..translate(0.0, 30 * (1 - _headerAnimation.value)),

            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
        );
      },
    );
  }

  Widget _buildSettingsSection() {
    return AnimatedBuilder(
      animation: _settingsAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..translate(0.0, 50 * (1 - _settingsAnimation.value)),
          child: Opacity(
            opacity: _settingsAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Subscribers',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF95A5A6),
                      size: 16,
                    ),
                    onTap: () => _showSubscribersPage(),
                  ),
                  _buildSettingItem(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    trailing: _buildThemeSwitch(),
                    onTap: null,
                  ),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Languages',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF95A5A6),
                      size: 16,
                    ),
                    onTap: () => _showLanguageSelection(),
                  ),
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'Credits',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF95A5A6),
                      size: 16,
                    ),
                    onTap: () => _showCreditsPage(),
                  ),
                  _buildSettingItem(
                    icon: Icons.remove_red_eye_outlined,
                    title: 'Vision',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF95A5A6),
                      size: 16,
                    ),
                    onTap: () => _showVisionPage(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(5, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(26, 52, 152, 219),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3498DB),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitch() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDarkMode = !_isDarkMode;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: _isDarkMode ? const Color(0xFF3498DB) : const Color(0xFFE8E8E8),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isDarkMode ? 32 : 2,
              top: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Journey Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatsCard(
                title: 'Total Journeys',
                value: '${_userStats['totalJourneys']}',
                icon: Icons.train,
                color: const Color(0xFF3498DB),
              ),
              _buildStatsCard(
                title: 'Distance',
                value: '${_userStats['totalDistance']} km',
                icon: Icons.straighten,
                color: const Color(0xFF2ECC71),
              ),
              _buildStatsCard(
                title: 'Avg Speed',
                value: '${_userStats['averageSpeed']} km/h',
                icon: Icons.speed,
                color: const Color(0xFFE74C3C),
              ),
              _buildStatsCard(
                title: 'Punctuality',
                value: '${_userStats['punctualityRate']}%',
                icon: Icons.schedule,
                color: const Color(0xFF9B59B6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSubscribersPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSubscribersSheet(),
    );
  }

  Widget _buildSubscribersSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Color(0xFF3498DB),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Subscribers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Share your journey progress with friends and family.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 30),
          _buildSubscriberItem('John Doe', 'john@example.com', true),
          _buildSubscriberItem('Jane Smith', 'jane@example.com', false),
          _buildSubscriberItem('Mike Johnson', 'mike@example.com', true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddSubscriberDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Subscriber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriberItem(String name, String email, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromARGB(26, 52, 152, 219),
            child: Text(
              name[0],
              style: const TextStyle(
                color: Color(0xFF3498DB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive 
                ? const Color.fromARGB(26, 46, 204, 112)
                : const Color.fromARGB(26, 149, 165, 166),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFF2ECC71) : const Color(0xFF95A5A6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Add Subscriber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscriber added successfully!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.language_outlined,
                  color: Color(0xFF3498DB),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._languages.map((lang) => _buildLanguageItem(lang)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String language) {
    final isSelected = _selectedLanguage == language;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color.fromARGB(26, 52, 152, 219)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF3498DB)
              : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              language,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                  ? const Color(0xFF3498DB)
                  : const Color(0xFF2C3E50),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF3498DB),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showCreditsPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3498DB),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Credits',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreditSection(
                      'Development Team',
                      [
                        'Lead Developer: Your Name',
                        'UI/UX Designer: Design Team',
                        'Backend Developer: Backend Team',
                      ],
                    ),
                    _buildCreditSection(
                      'Special Thanks',
                      [
                        'Flutter Team for the amazing framework',
                        'Material Design for design guidelines',
                        'Open Source Community',
                      ],
                    ),
                    _buildCreditSection(
                      'Third Party Libraries',
                      [
                        'flutter/material.dart',
                        'flutter/services.dart',
                        'dart:math',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.circle,
                  size: 6,
                  color: Color(0xFF3498DB),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showVisionPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
     ),
     builder: (context) => Container(
       height: MediaQuery.of(context).size.height * 0.8,
       padding: const EdgeInsets.all(20),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               const Icon(
                 Icons.remove_red_eye_outlined,
                 color: Color(0xFF3498DB),
                 size: 24,
               ),
               const SizedBox(width: 12),
               const Text(
                 'Vision',
                 style: TextStyle(
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                   color: Color(0xFF2C3E50),
                 ),
               ),
               const Spacer(),
               IconButton(
                 onPressed: () => Navigator.pop(context),
                 icon: const Icon(Icons.close),
               ),
             ],
           ),
           const SizedBox(height: 20),
           Expanded(
             child: SingleChildScrollView(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                         colors: [
                           Color(0xFF3498DB),
                           Color(0xFF2980B9),
                         ],
                       ),
                       borderRadius: BorderRadius.circular(16),
                     ),
                     child: const Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Our Vision',
                           style: TextStyle(
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                             color: Colors.white,
                           ),
                         ),
                         SizedBox(height: 12),
                         Text(
                           'To revolutionize transportation by creating seamless, sustainable, and intelligent mobility solutions that connect communities and enhance lives.',
                           style: TextStyle(
                             fontSize: 16,
                             color: Colors.white,
                             height: 1.5,
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   _buildVisionPoint(
                     'Sustainability',
                     'Reducing carbon footprint through smart transportation choices',
                     Icons.eco_outlined,
                     Color(0xFF2ECC71),
                   ),
                   _buildVisionPoint(
                     'Innovation',
                     'Leveraging cutting-edge technology to improve user experience',
                     Icons.lightbulb_outline,
                     Color(0xFFF39C12),
                   ),
                   _buildVisionPoint(
                     'Accessibility',
                     'Making transportation accessible to everyone, everywhere',
                     Icons.accessibility_outlined,
                     Color(0xFF9B59B6),
                   ),
                   _buildVisionPoint(
                     'Community',
                     'Building stronger connections between people and places',
                     Icons.people_outline,
                     Color(0xFFE74C3C),
                   ),
                 ],
               ),
             ),
           ),
         ],
       ),
     ),
   );
 }

 Widget _buildVisionPoint(String title, String description, IconData icon, Color color) {
   return Container(
     margin: const EdgeInsets.only(bottom: 16),
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: Colors.white,
       borderRadius: BorderRadius.circular(12),
       border: Border.all(
         color: const Color(0xFFE8E8E8),
         width: 1,
       ),
     ),
     child: Row(
       children: [
         Container(
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             // ignore: deprecated_member_use
             color: color.withOpacity(0.1),
             shape: BoxShape.circle,
           ),
           child: Icon(
             icon,
             color: color,
             size: 24,
           ),
         ),
         const SizedBox(width: 16),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 title,
                 style: const TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: Color(0xFF2C3E50),
                 ),
               ),
               const SizedBox(height: 4),
               Text(
                 description,
                 style: const TextStyle(
                   fontSize: 14,
                   color: Color(0xFF7F8C8D),
                   height: 1.3,
                 ),
               ),
             ],
           ),
         ),
       ],
     ),
   );
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: const Color(0xFFF8F9FA),
     body: SafeArea(
       child: SingleChildScrollView(
         child: Column(
           children: [
             _buildDashboardTitle(),
             _buildAnimatedStars(),
             _buildAchievementsSection(),
             _buildDetailedStatsSection(),
             _buildSettingsSection(),
             const SizedBox(height: 40),
           ],
         ),
       ),
     ),
   );
 }
}
import 'package:flutter/material.dart';

class FuturisticBottomNavBar extends StatefulWidget {
  final Function(int) onTap;
  final int currentIndex;

  const FuturisticBottomNavBar({
    super.key,
    required this.onTap,
    this.currentIndex = 0,
  });

  @override
  State<FuturisticBottomNavBar> createState() => _FuturisticBottomNavBarState();
}

class _FuturisticBottomNavBarState extends State<FuturisticBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  final List<NavItem> _navItems = [
    NavItem(Icons.newspaper_outlined, Icons.newspaper, 'News'),
    NavItem(Icons.leaderboard_outlined, Icons.leaderboard, 'Board'),
    NavItem(Icons.radio_button_unchecked, Icons.radio_button_checked, 'Live'), // Center main tab
    NavItem(Icons.route_outlined, Icons.route, 'Journey'),
    NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    widget.onTap(index);
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Very thin height
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray background
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(117, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _navItems.asMap().entries.map((entry) {
          int index = entry.key;
          NavItem item = entry.value;
          bool isSelected = widget.currentIndex == index;
          bool isCenterTab = index == 2; // Center tab (Live)

          return Expanded(
            child: GestureDetector(
              onTap: () => _onItemTapped(index),
              child: SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Special curved background for center tab
                    if (isCenterTab)
                      Positioned(
                        top: 8,
                        child: Container(
                          width: 50,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA), // Always light blue
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(129, 96, 165, 250),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Icon and label
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            double scale = isSelected && widget.currentIndex == index
                                ? 1.0 + _scaleAnimation.value * 0.1
                                : 1.0;
                            
                            return Transform.scale(
                              scale: scale,
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: _getIconColor(isSelected, isCenterTab),
                                size: isCenterTab ? 24 : 22,
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 2),
                        
                        Text(
                          item.label,
                          style: TextStyle(
                            color: _getTextColor(isSelected, isCenterTab),
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getIconColor(bool isSelected, bool isCenterTab) {
    if (isCenterTab) {
      return Colors.white; // Center tab icons are always white
    }
    
    if (isSelected) {
      return const Color(0xFF60A5FA); // Light blue for selected
    }
    
    return const Color(0xFF9CA3AF); // Gray for unselected
  }

  Color _getTextColor(bool isSelected, bool isCenterTab) {
    if (isCenterTab) {
      return Colors.white; // Center tab text is always white
    }
    
    if (isSelected) {
      return const Color(0xFF60A5FA); // Light blue for selected
    }
    
    return const Color(0xFF9CA3AF); // Gray for unselected
  }
}

class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavItem(this.icon, this.selectedIcon, this.label);
}
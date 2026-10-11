import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import '../../outfits/screens/outfit_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../wardrobe/screens/wardrobe_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WardrobeProvider>(context, listen: false).loadItems();
        Provider.of<OutfitProvider>(context, listen: false).loadOutfits();
      }
    });
  }

  void _switchTab(int index) {
    if (index >= 0 && index < 4 && mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  List<Widget> get _screens => [
        DashboardScreen(onSwitchTab: _switchTab),
        const WardrobeScreen(),
        const OutfitScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider and LanguageProvider so navigation shell reacts immediately
    Provider.of<ThemeProvider>(context);
    Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _buildNavItem(
                  index: 0,
                  icon: _currentIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                ),
                // 2. Wardrobe (Tủ đồ)
                _buildNavItem(
                  index: 1,
                  icon: _currentIndex == 1
                      ? Icons.checkroom_rounded
                      : Icons.checkroom_outlined,
                ),
                // 3. Center White Plus Button (+)
                GestureDetector(
                  onTap: () {
                    WardrobeScreen.showAddOptionsModal(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
                // 4. Outfits AI (Grid icon)
                _buildNavItem(
                  index: 2,
                  icon: Icons.grid_view_rounded,
                ),
                // 5. Profile (Cá nhân)
                _buildNavItem(
                  index: 3,
                  icon: _currentIndex == 3
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? AppTheme.primaryLight : Colors.white60,
        ),
      ),
    );
  }
}

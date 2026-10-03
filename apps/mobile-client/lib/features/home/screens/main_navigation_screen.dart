import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Listen to ThemeProvider so whole navigation shell & tabs react immediately
    Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Trang chủ
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Trang chủ',
                ),
                // 2. Tủ Đồ
                _buildNavItem(
                  index: 1,
                  icon: Icons.checkroom_rounded,
                  label: 'Tủ Đồ',
                ),
                // 3. Center Add (+) Button
                GestureDetector(
                  onTap: () {
                    WardrobeScreen.showAddOptionsModal(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                // 4. Phối đồ AI
                _buildNavItem(
                  index: 2,
                  icon: Icons.auto_awesome_rounded,
                  label: 'Phối đồ AI',
                ),
                // 5. Hồ Sơ
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: 'Hồ Sơ',
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
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.darkTextSecondary.withOpacity(0.7),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.darkTextSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

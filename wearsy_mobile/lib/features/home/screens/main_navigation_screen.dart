import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
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

  late final List<Widget> _screens = [
    DashboardScreen(onSwitchTab: _switchTab),
    const WardrobeScreen(),
    const OutfitScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppTheme.darkCard,
          selectedItemColor: AppTheme.primaryLight,
          unselectedItemColor: AppTheme.darkTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded, size: 26),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom_rounded),
              activeIcon: Icon(Icons.checkroom_rounded, size: 26),
              label: 'Tủ đồ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              activeIcon: Icon(Icons.auto_awesome_rounded, size: 26),
              label: 'AI Outfit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

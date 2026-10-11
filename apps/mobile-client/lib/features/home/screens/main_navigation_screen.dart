import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/wearsy_bottom_nav_bar.dart';
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
    Provider.of<ThemeProvider>(context);
    Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: WearsyBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _switchTab,
      ),
    );
  }
}

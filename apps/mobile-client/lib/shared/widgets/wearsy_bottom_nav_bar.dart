import 'package:flutter/material.dart';
import '../../features/wardrobe/screens/wardrobe_screen.dart';

class WearsyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const WearsyBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2563EB); // Vibrant Royal Blue
    const inactiveColor = Color(0xFF6B7280); // Subtle Dark Gray

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F12),
          borderRadius: BorderRadius.circular(38),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
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
                icon: currentIndex == 0
                    ? Icons.home_rounded
                    : Icons.home_outlined,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // 2. Wardrobe (Tủ đồ)
              _buildNavItem(
                index: 1,
                icon: currentIndex == 1
                    ? Icons.checkroom_rounded
                    : Icons.checkroom_outlined,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
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
                icon: currentIndex == 2
                    ? Icons.grid_view_rounded
                    : Icons.grid_view_outlined,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // 5. Profile (Cá nhân)
              _buildNavItem(
                index: 3,
                icon: currentIndex == 3
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTabSelected?.call(index),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? activeColor : inactiveColor,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/weather_service.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../outfits/models/outfit_model.dart';
import '../../outfits/screens/outfit_detail_screen.dart';
import '../../fitting_room/screens/virtual_fitting_room_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_provider.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherData? _weatherData;
  CityLocation _selectedCity = WeatherService.defaultCity;
  final Set<String> _favoriteOutfits = {'smart_casual_1', 'chic_minimal_2'};

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather([CityLocation? city]) async {
    CityLocation targetCity;
    if (city != null) {
      targetCity = city;
    } else {
      targetCity = await WeatherService.detectCurrentLocation();
    }
    final data = await WeatherService.fetchRealtimeWeather(
      lat: targetCity.lat,
      lon: targetCity.lon,
      locationName: targetCity.name,
    );
    if (mounted) {
      setState(() {
        _selectedCity = targetCity;
        _weatherData = data;
      });
    }
  }

  void _showCityPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chọn Vị Trí Thời Tiết 📍',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: const Text('📍', style: TextStyle(fontSize: 24)),
                title: Text(
                  'Vị trí hiện tại (Định vị tự động)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                subtitle: Text(
                  'Tự động lấy vị trí Realtime qua IP/GPS',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _fetchWeather(null);
                },
              ),
              const Divider(color: Colors.black12, height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: WeatherService.popularCities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.black12, height: 1),
                  itemBuilder: (context, index) {
                    final city = WeatherService.popularCities[index];
                    final isSelected = city.name == _selectedCity.name;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading:
                          Text(city.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        city.name,
                        style: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryLight
                              : const Color(0xFF111827),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: AppTheme.primaryLight)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _fetchWeather(city);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFittingRoomWithLook({
    required String title,
    required String subtitle,
    required String imageAsset,
  }) {
    final outfit = OutfitModel(
      id: 'look_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      aiReason: subtitle,
      occasion: OutfitOccasion.casual,
      weatherSuitable: ['Xuân Hè'],
      aiScore: 9.8,
      coverImageUrl: imageAsset,
      itemIds: [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutfitDetailScreen(outfit: outfit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final displayName =
        (user?.fullName != null && user!.fullName.trim().isNotEmpty)
            ? user.fullName.split(' ').last
            : 'Vân Anh';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Wearsy Logo + Notification & Profile Icons
              _buildTopBar(context),

              const SizedBox(height: 16),

              // 2. Greeting: "Xin chào, Vân Anh 👋"
              _buildGreeting(displayName),

              const SizedBox(height: 16),

              // 3. Hero Section: "Hôm nay mặc gì?" + 3D Mannequin
              _buildHeroSection(context),

              const SizedBox(height: 28),

              // 4. Section: "Gợi ý cho bạn"
              _buildSuggestedOutfitsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand Title
        Text(
          'Wearsy',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: const Color(0xFF111827),
          ),
        ),
        // Action Icons
        Row(
          children: [
            // Notification Bell
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    size: 22, color: Color(0xFF111827)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ Không có thông báo mới'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Profile Avatar
            UserAvatar(
              radius: 20,
              showBorder: true,
              borderColor: const Color(0xFFE5E7EB),
              borderWidth: 1.2,
              onTap: () => widget.onSwitchTab?.call(3), // Switch to profile tab
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(String name) {
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
    return RichText(
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: const Color(0xFF6B7280),
        ),
        children: [
          TextSpan(text: isEn ? 'Hello, ' : 'Xin chào, '),
          TextSpan(
            text: '$name 👋',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
    final tempStr = _weatherData != null
        ? '${_weatherData!.temperature.round()}°C'
        : '29°C';
    final cityStr = _selectedCity.name;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Content
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'What to\nwear today?' : 'Hôm nay\nmặc gì?',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEn
                          ? 'AI Fashion Assistant &\nSmart Wardrobe'
                          : 'Trợ lý thời trang &\ntủ đồ thông minh AI',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.35,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Action button: "Phối đồ AI"
                    GestureDetector(
                      onTap: () => widget.onSwitchTab?.call(2), // Switch to AI tab
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              isEn ? 'AI Stylist' : 'Phối đồ AI',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Clothing item pills
                    _buildClothingPill('👕', isEn ? 'White T-Shirt' : 'Áo thun trắng'),
                    const SizedBox(height: 6),
                    _buildClothingPill('👖', isEn ? 'Denim Shorts' : 'Short denim'),
                    const SizedBox(height: 6),
                    _buildClothingPill('👟', isEn ? 'White Sneakers' : 'Sneaker trắng'),
                  ],
                ),
              ),

              // Right Content: Weather Badge & 3D Mannequin Pedestal
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Weather Floating Badge
                    GestureDetector(
                      onTap: _showCityPickerBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⛅',
                                    style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  tempStr,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 11, color: Color(0xFF6B7280)),
                                const SizedBox(width: 2),
                                Text(
                                  cityStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 3D Mannequin Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/mannequin_hero.jpg',
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Arrow Action Bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VirtualFittingRoomScreen(),
                ),
              );
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingPill(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedOutfitsSection(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
    final outfitItems = [
      {
        'id': 'smart_casual_1',
        'title': isEn ? 'Smart Casual' : 'Smart casual',
        'subtitle': isEn
            ? 'Black Blazer • Trousers • Tote bag'
            : 'Blazer đen • Quần tây • Tote bag',
        'image': 'assets/images/outfit_smart_casual.jpg',
      },
      {
        'id': 'chic_minimal_2',
        'title': isEn ? 'Minimalist Chic' : 'Chic tối giản',
        'subtitle': isEn
            ? 'White Shirt • Black Skirt • Shoulder Bag'
            : 'Sơ mi trắng • Váy đen • Túi đeo',
        'image': 'assets/images/outfit_chic_minimal.jpg',
      },
      {
        'id': 'smart_casual_detail',
        'title': 'Overshirt & Chinos',
        'subtitle': isEn
            ? 'Overshirt • Navy Chinos • Sneakers'
            : 'Áo overshirt • Chino navy • Sneaker',
        'image': 'assets/images/outfit_detail_mannequin.jpg',
      },
      {
        'id': 'summer_casual',
        'title': isEn ? 'Summer Casual' : 'Năng động phố hè',
        'subtitle': isEn
            ? 'White Tee • Denim Shorts • Tote bag'
            : 'Áo thun trắng • Short denim • Tote bag',
        'image': 'assets/images/mannequin_hero.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEn ? 'Recommended for you' : 'Gợi ý cho bạn',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onSwitchTab?.call(2),
              child: Text(
                isEn ? 'See all' : 'Xem tất cả',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2-Column Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: outfitItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.64,
          ),
          itemBuilder: (context, index) {
            final item = outfitItems[index];
            final isFav = _favoriteOutfits.contains(item['id']);

            return GestureDetector(
              onTap: () {
                _openFittingRoomWithLook(
                  title: item['title']!,
                  subtitle: item['subtitle']!,
                  imageAsset: item['image']!,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card with Image & Favorite Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                item['image']!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Heart Button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isFav) {
                                    _favoriteOutfits.remove(item['id']);
                                  } else {
                                    _favoriteOutfits.add(item['id']!);
                                  }
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isFav
                                      ? Colors.redAccent
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    item['title']!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  Text(
                    item['subtitle']!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

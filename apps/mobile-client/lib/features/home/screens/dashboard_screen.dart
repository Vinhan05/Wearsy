import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/weather_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import '../../outfits/screens/ai_stylist_chat_screen.dart';
import '../../color_score/screens/color_score_screen.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherData? _weatherData;
  CityLocation _selectedCity = WeatherService.defaultCity;
  String _selectedTrendingCategory = 'Tất Cả';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather([CityLocation? city]) async {
    final targetCity = city ?? _selectedCity;
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
      backgroundColor: AppTheme.lightBackground,
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
                    color: AppTheme.primaryColor.withOpacity(0.3),
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
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: WeatherService.popularCities.length,
                  separatorBuilder: (_, __) => Divider(
                      color: AppTheme.primaryColor.withOpacity(0.1), height: 1),
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
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.darkTextPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: AppTheme.primaryColor, size: 20)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _fetchWeather(city);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showTrendingDetailModal(
      BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
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
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item['image']!,
                        width: 90,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item['category'] ?? 'Trending',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['title']!,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Điểm phối màu AI: 🌟 ${item['score'] ?? '9.5'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider.value(
                                  value: Provider.of<OutfitProvider>(context,
                                      listen: false)),
                              ChangeNotifierProvider.value(
                                  value: Provider.of<WardrobeProvider>(context,
                                      listen: false)),
                              ChangeNotifierProvider.value(
                                  value: Provider.of<AuthProvider>(context,
                                      listen: false)),
                            ],
                            child: const AiStylistChatScreen(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      'Tạo Outfit Với AI Stylist',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context); // Listen to Theme changes
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: logo + title left | Avatar circle right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/images/logo_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'wearsy',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkTextPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Trợ lý Thời trang & Tủ đồ Thông minh AI',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => widget.onSwitchTab?.call(3),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hero AI Outfit Card matching home.png exactly
              _buildAIBanner(context, user?.fullName ?? 'Văn A'),

              const SizedBox(height: 20),

              // Stats Row: 3 white cards (Tủ Đồ / 123, AI Outfit / 324, Điểm Màu / 9.8)
              _buildStatsRow(context),

              const SizedBox(height: 24),

              // Trending Section matching home.png exactly
              _buildTrendingSection(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context, String userName) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lavenderCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(
                      value:
                          Provider.of<OutfitProvider>(context, listen: false),
                    ),
                    ChangeNotifierProvider.value(
                      value:
                          Provider.of<WardrobeProvider>(context, listen: false),
                    ),
                    ChangeNotifierProvider.value(
                      value: Provider.of<AuthProvider>(context, listen: false),
                    ),
                  ],
                  child: const AiStylistChatScreen(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Xin chào $userName',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _showCityPickerBottomSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '⛅ ${_weatherData != null ? '${_weatherData!.temperature.toStringAsFixed(0)}°C' : '27°C'} ${_selectedCity.name.contains('Hồ Chí Minh') ? 'TP.HCM' : _selectedCity.name} ▾',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Text(
                      'Outfit gợi ý hôm nay',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.primaryLight, size: 20),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Thời tiết ${_selectedCity.name} hôm nay rất đẹp (${_weatherData?.temperature ?? 28.9}°C), hoàn hảo cho mọi phong cách dạo phố, công sở hoặc cà phê cuối tuần.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.darkTextSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Inner recipe box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lavenderSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Công thức phối đồ:',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkTextPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Hỏi AI ngay',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded,
                                  color: AppTheme.primaryColor, size: 14),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getDynamicFormulaText(
                            _weatherData?.temperature ?? 28.0),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.darkTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDynamicFormulaText(double temp) {
    if (temp > 30.0) {
      return 'Áo thun cotton thoáng mát + Quần short linen/jeans + Sneaker nhẹ nhàng + Kính mát phong cách';
    } else if (temp < 24.0) {
      return 'Áo khoác Cardigan/Blazer + Áo thun cổ tròn + Quần jeans slim-fit + Giày boots/sneaker cao cổ';
    } else {
      return 'Áo thun cotton cao cấp + Áo sơ mi khoác ngoài + Quần jeans slim-fit + Giày retro sneaker';
    }
  }

  Widget _buildStatsRow(BuildContext context) {
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final outfitProvider = Provider.of<OutfitProvider>(context);

    final allItems = wardrobeProvider.allItemsAcrossAllWardrobes;
    final wardrobeCount = allItems.length.toString();

    final aiOutfitCount = outfitProvider.outfits.length.toString();

    final double avgScore = allItems.isEmpty
        ? 0.0
        : (allItems.fold(0.0, (sum, item) => sum + item.aiMatchScore) /
            allItems.length);
    final colorScoreStr = avgScore == 0.0 ? '0' : avgScore.toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Tủ Đồ',
            count: wardrobeCount,
            onTap: () => widget.onSwitchTab?.call(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'AI Outfit',
            count: aiOutfitCount,
            onTap: () => widget.onSwitchTab?.call(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Điểm Màu',
            count: colorScoreStr,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(
                        value: Provider.of<WardrobeProvider>(context,
                            listen: false),
                      ),
                      ChangeNotifierProvider.value(
                        value:
                            Provider.of<OutfitProvider>(context, listen: false),
                      ),
                    ],
                    child: const ColorScoreScreen(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(BuildContext context) {
    final filterOptions = ['Tất Cả', 'Smart Casual', 'Street Wear'];

    final allTrendingItems = [
      {
        'title': 'Suit Nam Lịch Lãm',
        'category': 'Smart Casual',
        'score': '9.8',
        'image':
            'https://images.unsplash.com/photo-1617137968427-85924c800a22?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Áo Thun & Mũ Fedora',
        'category': 'Street Wear',
        'score': '9.5',
        'image':
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Áo Len Cổ Lọ Nữ',
        'category': 'Smart Casual',
        'score': '9.6',
        'image':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
      },
      {
        'title': 'Denim Jacket Năng Động',
        'category': 'Street Wear',
        'score': '9.4',
        'image':
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=600&auto=format&fit=crop',
      },
    ];

    final displayedItems = _selectedTrendingCategory == 'Tất Cả'
        ? allTrendingItems
        : allTrendingItems
            .where((item) => item['category'] == _selectedTrendingCategory)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkTextPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Filter Pills
        Row(
          children: filterOptions.map((opt) {
            final isSelected = opt == _selectedTrendingCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTrendingCategory = opt;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryLight.withOpacity(0.35)
                        : AppTheme.lavenderCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.darkTextPrimary
                          : AppTheme.darkTextSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 18),

        // Grid of Photos
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final item = displayedItems[index];
            return GestureDetector(
              onTap: () => _showTrendingDetailModal(context, item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.lavenderCard,
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

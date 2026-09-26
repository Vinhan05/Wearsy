import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/mock/mock_data_service.dart';
import '../../outfits/models/outfit_model.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import '../../outfits/screens/outfit_detail_screen.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../wardrobe/screens/add_item_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherData? _weatherData;
  CityLocation _selectedCity = WeatherService.defaultCity;
  bool _isDetectingLocation = false;

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

  Future<void> _autoDetectAndFetchWeather() async {
    setState(() => _isDetectingLocation = true);
    final detected = await WeatherService.detectCurrentLocation();
    await _fetchWeather(detected);
    if (mounted) {
      setState(() => _isDetectingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Đã định vị: ${detected.name} (${detected.region})'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showCityPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn Vị Trí Thời Tiết 📍',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                    ),
                    icon: _isDetectingLocation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('Định vị tự động', style: TextStyle(fontSize: 12)),
                    onPressed: _isDetectingLocation
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _autoDetectAndFetchWeather();
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: WeatherService.popularCities.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final city = WeatherService.popularCities[index];
                    final isSelected = city.name == _selectedCity.name;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Text(city.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        city.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryLight : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        city.region,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.darkTextSecondary),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryLight, size: 20)
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final weather = _weatherData?.toMap() ?? MockDataService.getMockWeather();

    return Scaffold(
      body: Container(
        color: AppTheme.darkBackground,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primaryLight,
            backgroundColor: AppTheme.darkCard,
            onRefresh: () async {
              await _fetchWeather();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Greeting + AI Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${user?.fullName.split(' ').last ?? 'Bạn'} 👋',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Hôm nay bạn muốn mặc phong cách gì?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.4)),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primaryLight,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // AI Stylist Banner
                  _buildAIBanner(context, weather),

                  const SizedBox(height: 24),

                  // Stats Row
                  _buildStatsRow(context),

                  const SizedBox(height: 28),

                  // Quick Actions
                  Text(
                    'Thao Tác Nhanh',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildQuickActions(context),

                  const SizedBox(height: 28),

                  // Wardrobe preview
                  _buildWardrobePreview(context),

                  const SizedBox(height: 28),

                  // Recent Outfits
                  _buildRecentOutfits(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIBanner(
      BuildContext context, Map<String, dynamic> weather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'AI OUTFIT',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: InkWell(
                  onTap: _showCityPickerBottomSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${weather['icon']} ${weather['temperature']}°C',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${weather['location'] ?? _selectedCity.name}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Outfit gợi ý hôm nay 🎯',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weather['suggestion'] ??
                'Business Casual hoàn hảo: Sơ mi trắng + Quần tây + Blazer Beige — tự tin, thanh lịch cho ngày làm việc.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
          if (weather['outfitFormula'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Công thức phối đồ AI:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weather['outfitFormula'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4,
                    ),
                  ),
                  if (weather['suggestedItems'] != null && (weather['suggestedItems'] as List).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (weather['suggestedItems'] as List).map<Widget>((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.toString(),
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: Text(
              'Tạo Outfit Mới Bằng AI',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              // Navigate to AI Outfit tab (index 2)
              // We use a SnackBar here since we can't access the navigator to switch tabs easily
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✨ Chuyển sang tab AI Outfit để tạo outfit mới!',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final outfitProvider = Provider.of<OutfitProvider>(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.checkroom_rounded,
            count: wardrobeProvider.allItems.length.toString(),
            label: 'Tủ Đồ',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.auto_awesome_rounded,
            count: outfitProvider.outfits.length.toString(),
            label: 'AI Outfit',
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _StatCard(
            icon: Icons.palette_rounded,
            count: '9.5',
            label: 'Điểm Màu',
            color: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            icon: Icons.add_a_photo_rounded,
            title: 'Thêm Đồ Vào Tủ',
            subtitle: 'AI Tự Động Phân Loại',
            color: AppTheme.secondaryColor,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📸 Chuyển sang tab Tủ đồ để thêm đồ!',
                      style: GoogleFonts.inter()),
                  backgroundColor: AppTheme.secondaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionTile(
            icon: Icons.shopping_bag_rounded,
            title: 'Smart Shopping',
            subtitle: 'Check Độ Tương Thích',
            color: AppTheme.primaryLight,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🛍️ Tính năng Smart Shopping đang phát triển!',
                      style: GoogleFonts.inter()),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWardrobePreview(BuildContext context) {
    final provider = Provider.of<WardrobeProvider>(context);
    final items = provider.allItems.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tủ Đồ Của Bạn',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Xem tất cả (${provider.allItems.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (provider.isLoading)
          const SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight),
            ),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.primaryLight, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tủ đồ chưa có trang phục',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Thêm món đồ đầu tiên để AI phối đồ!',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddItemScreen()),
                    );
                  },
                  child: Text('Thêm đồ',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _WardrobePreviewCard(item: items[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentOutfits(BuildContext context) {
    final provider = Provider.of<OutfitProvider>(context);
    final outfits = provider.outfits.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Outfit AI Gần Đây',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Xem tất cả',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (provider.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight))
        else if (outfits.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Center(
              child: Text(
                'Chưa có gợi ý outfit nào. Khi có trang phục trong tủ đồ, AI sẽ tự động tạo outfit!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...outfits.map((outfit) => _RecentOutfitCard(outfit: outfit)),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WardrobePreviewCard extends StatelessWidget {
  final WardrobeItemModel item;
  const _WardrobePreviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.darkSurface,
                  child: const Icon(Icons.checkroom,
                      color: AppTheme.primaryLight),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item.category.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  const _RecentOutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: Provider.of<OutfitProvider>(context, listen: false),
            child: OutfitDetailScreen(outfit: outfit),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                outfit.coverImageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: AppTheme.darkSurface,
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primaryLight),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(outfit.occasion.icon,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        outfit.occasion.displayName,
                        style: GoogleFonts.inter(
                          color: AppTheme.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.amber, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'AI Score: ${outfit.aiScore.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.darkTextSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

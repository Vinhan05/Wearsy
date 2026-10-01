import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import '../models/color_score_model.dart';
import '../services/color_score_service.dart';

class ColorScoreScreen extends StatefulWidget {
  final List<String>? initialColors;
  final String? initialTitle;

  const ColorScoreScreen({
    super.key,
    this.initialColors,
    this.initialTitle,
  });

  @override
  State<ColorScoreScreen> createState() => _ColorScoreScreenState();
}

class _ColorScoreScreenState extends State<ColorScoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PersonalSeason _selectedSeason = PersonalSeason.autumnDeep;

  // Interactive Color Lab State
  final List<ColorItem> _availableLabColors = [
    const ColorItem(name: 'Trắng Trơn', color: Color(0xFFFFFFFF), hex: '#FFFFFF', usageTip: 'Màu nền trung tính'),
    const ColorItem(name: 'Đen Huyền', color: Color(0xFF1E293B), hex: '#1E293B', usageTip: 'Màu nền tạo phom'),
    const ColorItem(name: 'Bege / Khaki', color: Color(0xFFC3B091), hex: '#C3B091', usageTip: 'Thanh lịch, ấm áp'),
    const ColorItem(name: 'Xanh Navy', color: Color(0xFF1E3A8A), hex: '#1E3A8A', usageTip: 'Công sở lịch lãm'),
    const ColorItem(name: 'Xanh Rêu Olive', color: Color(0xFF556B2F), hex: '#556B2F', usageTip: 'Tone đất trendy'),
    const ColorItem(name: 'Nâu Da Bò', color: Color(0xFFC06C46), hex: '#C06C46', usageTip: 'Vintage sang trọng'),
    const ColorItem(name: 'Xanh Baby Pastel', color: Color(0xFF89CFF0), hex: '#89CFF0', usageTip: 'Dịu mát, tươi trẻ'),
    const ColorItem(name: 'Vàng Mù Tạt', color: Color(0xFFE1AD01), hex: '#E1AD01', usageTip: 'Điểm nhấn rực rỡ'),
    const ColorItem(name: 'Hồng Khói', color: Color(0xFFDCAE96), hex: '#DCAE96', usageTip: 'Nữ tính tinh tế'),
    const ColorItem(name: 'Đỏ Rượu Burgundy', color: Color(0xFF800020), hex: '#800020', usageTip: 'Quyến rũ, quý phái'),
  ];

  final List<ColorItem> _selectedLabColors = [];
  ColorHarmonyResult? _labResult;
  bool _isAnalyzingLab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (widget.initialColors != null && widget.initialColors!.isNotEmpty) {
      for (final colorHex in widget.initialColors!) {
        final match = _availableLabColors.firstWhere(
          (c) => c.hex.toLowerCase() == colorHex.toLowerCase(),
          orElse: () => ColorItem(
            name: 'Màu chọn',
            color: const Color(0xFF6366F1),
            hex: colorHex,
            usageTip: 'Màu từ trang phục',
          ),
        );
        _selectedLabColors.add(match);
      }
      _runLabAnalysis();
    } else {
      // Mặc định chọn 2 màu mẫu
      _selectedLabColors.add(_availableLabColors[0]); // Trắng
      _selectedLabColors.add(_availableLabColors[2]); // Be
      _selectedLabColors.add(_availableLabColors[4]); // Xanh rêu
      _runLabAnalysis();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runLabAnalysis() async {
    if (_selectedLabColors.isEmpty) return;
    setState(() => _isAnalyzingLab = true);

    final colorsHex = _selectedLabColors.map((e) => e.hex).toList();
    final result = await ColorScoreService.analyzeColorCombination(colors: colorsHex);

    if (mounted) {
      setState(() {
        _labResult = result;
        _isAnalyzingLab = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final outfitProvider = Provider.of<OutfitProvider>(context);
    final wardrobeScore = ColorScoreService.calculateWardrobeColorScore(wardrobeProvider.allItems);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          widget.initialTitle ?? 'Phân Tích Màu Sắc AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.darkCard,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới phân tích',
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryLight),
            onPressed: () {
              _runLabAnalysis();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✨ Đã làm mới phân tích bánh xe màu sắc!'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildHeroScoreHeader(wardrobeScore, wardrobeProvider.allItems.length),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.primaryLight,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: AppTheme.darkTextSecondary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: '📊 Tủ Đồ 60-30-10'),
                  Tab(text: '🌸 Tone Da & 4 Mùa'),
                  Tab(text: '🧪 Thử Nghiệm Màu'),
                  Tab(text: '🏆 Thử Thách & Badge'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWardrobeHarmonyTab(wardrobeProvider),
            _buildPersonalSeasonTab(),
            _buildInteractiveColorLabTab(),
            _buildChallengesTab(outfitProvider),
          ],
        ),
      ),
    );
  }

  /// 1. Hero Score Header Card
  Widget _buildHeroScoreHeader(double score, int wardrobeCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C1E4A),
            const Color(0xFF1E293B),
            AppTheme.darkCard,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Radial / Circle Score Display
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '/ 10',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.amber, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'TIÊU CHUẨN VÀNG',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bậc Thầy Phối Màu ✨',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tủ đồ $wardrobeCount món đạt độ cân bằng 60-30-10 xuất sắc.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          // Mini Wardrobe Palette Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phổ màu tủ đồ chính:',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.darkTextSecondary),
              ),
              Row(
                children: [
                  _buildPaletteDot(const Color(0xFFFFFFFF), '35%'),
                  const SizedBox(width: 6),
                  _buildPaletteDot(const Color(0xFF1E293B), '25%'),
                  const SizedBox(width: 6),
                  _buildPaletteDot(const Color(0xFFC3B091), '20%'),
                  const SizedBox(width: 6),
                  _buildPaletteDot(const Color(0xFF1E3A8A), '12%'),
                  const SizedBox(width: 6),
                  _buildPaletteDot(const Color(0xFFC06C46), '8%'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteDot(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: Colors.white70)),
        ],
      ),
    );
  }

  /// TAB 1: Wardrobe Harmony & 60-30-10 Rule
  Widget _buildWardrobeHarmonyTab(WardrobeProvider wardrobe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 60-30-10 Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tỷ Lệ Vàng Thời Trang: 60 - 30 - 10',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Visual multi-bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        Expanded(flex: 60, child: Container(color: const Color(0xFF6366F1))),
                        Expanded(flex: 30, child: Container(color: const Color(0xFFEC4899))),
                        Expanded(flex: 10, child: Container(color: const Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildRatioItem(
                  color: const Color(0xFF6366F1),
                  percent: '60%',
                  title: 'Màu Chủ Đạo (Dominant Base)',
                  desc: 'Trắng, Đen, Xám, Be — Dành cho quần tây, chân váy, blazer hoặc áo sơ mi chính.',
                ),
                const SizedBox(height: 12),
                _buildRatioItem(
                  color: const Color(0xFFEC4899),
                  percent: '30%',
                  title: 'Màu Thứ Cấp (Secondary Complement)',
                  desc: 'Xanh navy, Xanh rêu, Nâu da bò — Dành cho áo khoác ngoài, áo len hoặc layer 2.',
                ),
                const SizedBox(height: 12),
                _buildRatioItem(
                  color: const Color(0xFFF59E0B),
                  percent: '10%',
                  title: 'Màu Nhấn (Accent Pop)',
                  desc: 'Vàng mù tạt, Đỏ rượu, Ánh kim — Dành cho thắt lưng, túi xách, giày hoặc trang sức.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Styling Recommendation AI Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.darkCard,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Lời Khuyên Từ Chuyên Gia AI Stylist',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAdviceBullet(
                  'Tủ đồ của bạn có tỷ lệ màu trung tính (Neutral) lý tưởng (~75%), rất dễ xoay vòng và tạo ra hơn 30 outfit khác nhau.',
                ),
                _buildAdviceBullet(
                  'Gợi ý bổ sung 1 chiếc khăn lụa hoặc túi xách màu nhấn (Terracotta / Vàng mù tạt) để kích hoạt điểm 10% cho các set đồ công sở.',
                ),
                _buildAdviceBullet(
                  'Khi phối trang phục có màu đậm (như đen, navy), hãy mở cúc cổ áo hoặc chọn giày sáng màu để tạo khoảng thở thị giác.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioItem({
    required Color color,
    required String percent,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            percent,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.darkTextSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppTheme.primaryLight, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// TAB 2: Personal Color Season & Undertone
  Widget _buildPersonalSeasonTab() {
    final profile = ColorScoreService.seasonalProfiles[_selectedSeason]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn Mùa Màu Sắc Cá Nhân Của Bạn:',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Season Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PersonalSeason.values.map((s) {
                final isSelected = s == _selectedSeason;
                final p = ColorScoreService.seasonalProfiles[s]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p.seasonName.split('(')[0].trim()),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.darkCard,
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedSeason = s);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Season Profile Detail Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.seasonName,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.description,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Best Colors Section
          Text(
            'Bảng Màu Tôn Da Nhất (Best Palette) ✨',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Column(
            children: profile.bestColors.map((colorItem) => _buildColorCard(colorItem, isBest: true)).toList(),
          ),
          const SizedBox(height: 16),

          // Avoid Colors Section
          Text(
            'Bảng Màu Nên Tiết Chế (Colors to Avoid) ⚠️',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Column(
            children: profile.avoidColors.map((colorItem) => _buildColorCard(colorItem, isBest: false)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCard(ColorItem item, {required bool isBest}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isBest ? Colors.white10 : Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      item.hex,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.darkTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.usageTip,
                  style: GoogleFonts.inter(fontSize: 12, color: isBest ? Colors.white70 : Colors.redAccent.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// TAB 3: Interactive Color Lab (Phòng Thử Màu AI)
  Widget _buildInteractiveColorLabTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn 2 - 4 Màu Để Kiểm Tra Độ Ăn Ý:',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Lab color selector chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLabColors.map((colorItem) {
              final isSelected = _selectedLabColors.any((c) => c.hex == colorItem.hex);
              return FilterChip(
                selected: isSelected,
                avatar: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorItem.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                ),
                label: Text(colorItem.name),
                selectedColor: AppTheme.primaryColor.withOpacity(0.4),
                backgroundColor: AppTheme.darkCard,
                side: BorderSide(color: isSelected ? AppTheme.primaryLight : Colors.white12),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedLabColors.length < 4) {
                        _selectedLabColors.add(colorItem);
                      }
                    } else {
                      _selectedLabColors.removeWhere((c) => c.hex == colorItem.hex);
                    }
                  });
                  _runLabAnalysis();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Analysis Output
          if (_isAnalyzingLab) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              ),
            ),
          ] else if (_labResult != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette_rounded, color: AppTheme.warningColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Điểm Phối Màu AI',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_labResult!.score.toStringAsFixed(1)} / 10',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _labResult!.ruleApplied,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _labResult!.feedback,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _labResult!.colorRatioEvaluation,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Styling Tips:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._labResult!.stylingTips.map((tip) => _buildAdviceBullet(tip)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// TAB 4: Gamification Challenges & Badges
  Widget _buildChallengesTab(OutfitProvider outfitProvider) {
    final challenges = ColorScoreService.getWeeklyChallenges();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges showcase
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF312E81),
                  AppTheme.darkCard,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.black87, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Huy Hiệu Thời Trang Đã Đạt',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã mở khóa 3 / 8 danh hiệu • 750 Fashion Points',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Thử Thách Phối Đồ Tuần Này 🎯',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: challenges.map((challenge) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: challenge.status == 'COMPLETED'
                        ? Colors.green.withOpacity(0.3)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: challenge.status == 'COMPLETED'
                                ? Colors.green.withOpacity(0.2)
                                : challenge.status == 'IN_PROGRESS'
                                    ? Colors.amber.withOpacity(0.2)
                                    : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            challenge.status == 'COMPLETED'
                                ? 'Hoàn thành'
                                : challenge.status == 'IN_PROGRESS'
                                    ? 'Đang thực hiện'
                                    : 'Có sẵn',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: challenge.status == 'COMPLETED'
                                  ? Colors.greenAccent
                                  : challenge.status == 'IN_PROGRESS'
                                      ? Colors.amber
                                      : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.darkTextSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+${challenge.rewardPoints} Pts • ${challenge.rewardBadge}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: challenge.palettePreview.map((c) {
                            return Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: challenge.progressPercent,
                        backgroundColor: Colors.white10,
                        color: challenge.status == 'COMPLETED' ? Colors.green : AppTheme.primaryLight,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.darkBackground,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

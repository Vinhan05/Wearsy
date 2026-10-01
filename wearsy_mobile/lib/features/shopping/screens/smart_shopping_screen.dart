import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_shopping_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

class SmartShoppingScreen extends StatefulWidget {
  final String? initialUrl;
  const SmartShoppingScreen({super.key, this.initialUrl});

  @override
  State<SmartShoppingScreen> createState() => _SmartShoppingScreenState();
}

class _SmartShoppingScreenState extends State<SmartShoppingScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isAnalyzing = false;
  ShoppingCompatibilityResult? _analysisResult;
  ProspectiveProduct? _selectedProduct;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAnalysis(widget.initialUrl!);
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
      _runAnalysis(_urlController.text);
    }
  }

  void _runAnalysis(String url) {
    if (url.trim().isEmpty) return;
    final parsed = SmartShoppingAiService.parseProductFromUrl(url.trim());
    _analyzeProduct(parsed);
  }

  Future<void> _analyzeProduct(ProspectiveProduct product) async {
    setState(() {
      _selectedProduct = product;
      _isAnalyzing = true;
      _analysisResult = null;
    });

    ProspectiveProduct finalProduct = product;
    // Cào ảnh thật từ sàn thương mại điện tử nếu là liên kết web
    if (product.productUrl.startsWith('http') &&
        !product.imageUrl.contains('susercontent.com') &&
        !product.imageUrl.contains('tiktokcdn.com')) {
      try {
        final enriched =
            await SmartShoppingAiService.enrichProductFromUrl(product);
        finalProduct = enriched;
        if (mounted) {
          setState(() {
            _selectedProduct = finalProduct;
          });
        }
      } catch (e) {
        debugPrint('[SmartShoppingScreen] Error enriching product: $e');
      }
    }

    if (!mounted) return;
    final wardrobe = Provider.of<WardrobeProvider>(context, listen: false);
    final result = await SmartShoppingAiService.checkCompatibility(
      product: finalProduct,
      wardrobeItems: wardrobe.allItems,
    );

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _selectedProduct = finalProduct;
        _analysisResult = result;
      });
    }
  }

  Future<void> _saveToWardrobe() async {
    if (_selectedProduct == null) return;
    final provider = Provider.of<WardrobeProvider>(context, listen: false);

    final newItem = WardrobeItemModel(
      id: 'w_shop_${DateTime.now().millisecondsSinceEpoch}',
      name: _selectedProduct!.title,
      category: _selectedProduct!.category,
      color: _selectedProduct!.color,
      brand: _selectedProduct!.brand,
      imageUrl: _selectedProduct!.imageUrl,
      tags: _selectedProduct!.tags,
      aiMatchScore: _analysisResult?.compatibilityScore ?? 9.0,
    );

    await provider.addItem(newItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🎉 Đã thêm "${newItem.name}" vào Tủ Đồ của bạn!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Smart Shopping 🛍️',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Feature Card
            _buildHeroBanner(),
            const SizedBox(height: 18),

            // URL input & Paste button
            _buildUrlInputSection(),
            const SizedBox(height: 20),

            // Loading state or Analysis Results or Empty Prompt
            if (_isAnalyzing)
              _buildLoadingState()
            else if (_analysisResult != null)
              _buildAnalysisResultView(currencyFormatter)
            else
              _buildEmptyPromptState(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.25),
            AppTheme.primaryColor.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFFF6B6B), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check Tương Thích Tủ Đồ',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dán link Shopee, TikTok Shop, Lazada, Zara... để AI đánh giá xem món đồ mới có phối được với tủ đồ của bạn không.',
                  style: GoogleFonts.inter(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link sản phẩm muốn mua 🔗',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Dán link Shopee, TikTok, Lazada, Zara...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    prefixIcon: const Icon(Icons.link_rounded,
                        color: AppTheme.primaryLight, size: 20),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white38, size: 18),
                            onPressed: () {
                              _urlController.clear();
                              setState(() {
                                _analysisResult = null;
                                _selectedProduct = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _runAnalysis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _pasteFromClipboard,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.content_paste_rounded,
                          color: AppTheme.primaryLight, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Dán',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: Text(
                'Kiểm Tra Tương Thích Với AI',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: _urlController.text.trim().isNotEmpty
                  ? () => _runAnalysis(_urlController.text)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromptState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 38,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sẵn Sàng Phân Tích Món Đồ',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dán đường link sản phẩm từ Shopee, TikTok Shop, Lazada hoặc Zara vào ô bên trên rồi bấm "Kiểm Tra Tương Thích Với AI".',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.darkTextSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hoặc thử nhanh sản phẩm mẫu:',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSampleChip(
                label: 'Quạt cầm tay M2',
                icon: Icons.mode_fan_off_outlined,
                url:
                    'https://shopee.vn/Qu%E1%BA%A1t-c%E1%BA%A7m-tay-M2-N68-5000mAh-di-%C4%91%E1%BB%99ng-c%C3%B3-th%E1%BB%83-s%E1%BA%A1c-gi%C3%B3-m%E1%BA%A1nh-100-t%E1%BB%91c-%C4%91%E1%BB%99-turbo-ph%E1%BA%A3n-l%E1%BB%B1c-m%C3%A0n-h%C3%ACnh-hi%E1%BB%83n-th%E1%BB%8B-pin-T%E1%BA%B7ng-d%C3%A2y-%C4%91eo-i.1025928968.24143959658?extraParams=%7B%22display_model_id%22%3A258164864058%2C%22model_selection_logic%22%3A3%7D',
              ),
              _buildSampleChip(
                label: 'Sweater Shark',
                icon: Icons.checkroom,
                url:
                    'https://shopee.vn/%C3%81o-Sweater-Frozen-Shark-N%E1%BB%89-N%E1%BB%89-B%C3%B4ng-Cotton-100-Unisex-Local-Brand-i.564687320.26261149077?extraParams=%7B%22display_modACel_id%22%3A217850061955%2C%22model_selection_logic%22%3A3%7D',
              ),
              _buildSampleChip(
                label: 'Áo 3 lỗ Cotton',
                icon: Icons.dry_cleaning,
                url:
                    'https://shopee.vn/%C3%81o-3-l%E1%BB%97-nam-Cotton-tr%E1%BA%AFng-tr%C6%A1n-m%E1%BA%B7c-l%C3%B3t-trong-s%C6%A1-mi-trung-ni%C3%AAn-LEDATEX-%C4%91%C3%B4ng-xu%C3%A2n-cao-c%E1%BA%A5p-LOTNAM-i.317269974.7756281788?extraParams=%7B%22display_model_id%22%3A73305385054%2C%22model_selection_logic%22%3A3%7D',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleChip({
    required String label,
    required IconData icon,
    required String url,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: AppTheme.primaryLight),
      label: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: Colors.white.withOpacity(0.06),
      side: BorderSide(color: Colors.white.withOpacity(0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _urlController.text = url;
        _runAnalysis(url);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 45,
            height: 45,
            child: CircularProgressIndicator(
              color: AppTheme.primaryLight,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'WEARSY AI đang so sánh sản phẩm với tủ đồ của bạn...',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phân tích bánh xe màu sắc, phom dáng và khả năng tạo outfit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultView(NumberFormat currencyFormatter) {
    final result = _analysisResult!;
    final prod = result.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Summary Header Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 90,
                  height: 100,
                  child: CachedNetworkImage(
                    imageUrl: prod.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.darkSurface,
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.35),
                            const Color(0xFFFF6B6B).withOpacity(0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(prod.category, prod.title),
                          color: AppTheme.primaryLight,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        prod.platform,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prod.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(prod.price),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10AC84),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Màu: ${prod.color} • ${prod.category.displayName}',
                      style: GoogleFonts.inter(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Score Card
        _buildCompatibilityScoreCard(result),
        const SizedBox(height: 16),

        // Color & Silhouette breakdown
        _buildStylistAnalysisCards(result),
        const SizedBox(height: 20),

        // Suggested Outfits with Wardrobe Items
        _buildSuggestedOutfitsSection(result),
        const SizedBox(height: 24),

        // Save to wardrobe button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10AC84),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded,
                color: Colors.white),
            label: Text(
              'LƯU MÓN NÀY VÀO TỦ ĐỒ',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            onPressed: _saveToWardrobe,
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityScoreCard(ShoppingCompatibilityResult result) {
    Color statusColor;
    if (result.scoreLevel == 'HIGH') {
      statusColor = const Color(0xFF10AC84);
    } else if (result.scoreLevel == 'MEDIUM') {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star_rounded, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Độ Tương Thích Tủ Đồ',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  '${result.compatibilityScore}/10',
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  result.recommendationStatus,
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.recommendationReason,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (result.isDuplicate) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Cảnh báo: Tủ đồ của bạn đã có trang phục cùng loại & tông màu tương tự!',
                      style: GoogleFonts.inter(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStylistAnalysisCards(ShoppingCompatibilityResult result) {
    return Column(
      children: [
        // Color harmony
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bánh Xe Màu Sắc (Color Wheel)',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.colorHarmonyAnalysis,
                      style: GoogleFonts.inter(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Silhouette & Layering
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📐', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phom Dáng & Phối Lớp (Layering)',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.silhouetteAnalysis,
                      style: GoogleFonts.inter(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedOutfitsSection(ShoppingCompatibilityResult result) {
    if (result.suggestedOutfits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.style_rounded, color: AppTheme.primaryLight, size: 20),
            const SizedBox(width: 8),
            Text(
              'Gợi Ý Phối Đồ Ngay Với Tủ Của Bạn',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...result.suggestedOutfits.map((outfit) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outfit.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        outfit.style,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Combined items visual preview
                Row(
                  children: [
                    // Prospective Item
                    _buildOutfitItemThumb(
                      imageUrl: result.product.imageUrl,
                      title: result.product.title,
                      badge: 'Món mới',
                      badgeColor: const Color(0xFFFF6B6B),
                      category: result.product.category,
                    ),
                    // Matched items from wardrobe
                    ...outfit.wardrobeItems.take(2).expand((item) => [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.add,
                                color: Colors.white38, size: 16),
                          ),
                          _buildOutfitItemThumb(
                            imageUrl: item.imageUrl,
                            title: item.name,
                            badge: 'Trong tủ',
                            badgeColor: const Color(0xFF10AC84),
                            category: item.category,
                          ),
                        ]),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '💡 Mẹo: ${outfit.stylingTip}',
                  style: GoogleFonts.inter(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOutfitItemThumb({
    required String imageUrl,
    required String title,
    required String badge,
    required Color badgeColor,
    WardrobeCategory? category,
  }) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 70,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.darkSurface,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.4),
                        badgeColor.withOpacity(0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      category != null
                          ? _getCategoryIcon(category, title)
                          : Icons.checkroom_rounded,
                      size: 24,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: badgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primaryLight),
            const SizedBox(width: 10),
            Text(
              'Smart Shopping là gì?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Smart Shopping giúp bạn tránh mua phải những món đồ không thể phối cùng quần áo sẵn có.\n\nAI sẽ quét dữ liệu toàn bộ tủ đồ của bạn, áp dụng nguyên lý phối màu và phom dáng để chấm điểm tương thích trước khi bạn bấm mua trên Shopee, TikTok Shop, Lazada hay Zara!',
          style: GoogleFonts.inter(
            color: AppTheme.darkTextSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã Hiểu',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(WardrobeCategory cat, [String? title]) {
    switch (cat) {
      case WardrobeCategory.tops:
        return Icons.checkroom_rounded;
      case WardrobeCategory.bottoms:
        return Icons.straighten_rounded;
      case WardrobeCategory.outerwear:
        return Icons.dry_cleaning_rounded;
      case WardrobeCategory.dresses:
        return Icons.woman_rounded;
      case WardrobeCategory.shoes:
        return Icons.skateboarding_rounded;
      case WardrobeCategory.accessories:
        if (title != null && title.isNotEmpty) {
          final t = title.toLowerCase();
          if (t.contains('quạt') || t.contains('quat') || t.contains('fan')) {
            return Icons.air_rounded;
          }
          if (t.contains('đồng hồ') || t.contains('watch')) {
            return Icons.watch_rounded;
          }
          if (t.contains('kính') || t.contains('kinh')) {
            return Icons.visibility_rounded;
          }
          if (t.contains('nón') || t.contains('mũ') || t.contains('cap')) {
            return Icons.sports_baseball_rounded;
          }
        }
        return Icons.shopping_bag_outlined;
    }
  }
}

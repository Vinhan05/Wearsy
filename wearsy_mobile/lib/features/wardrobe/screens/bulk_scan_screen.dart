import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/services/wardrobe_scanner_service.dart';
import '../models/bulk_scan_result_model.dart';
import '../models/wardrobe_item_model.dart';
import '../providers/wardrobe_provider.dart';

class BulkScanScreen extends StatefulWidget {
  const BulkScanScreen({super.key});

  @override
  State<BulkScanScreen> createState() => _BulkScanScreenState();
}

class _BulkScanScreenState extends State<BulkScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final WardrobeScannerService _scannerService = WardrobeScannerService();

  File? _selectedImage;
  bool _isAnalyzing = false;
  String _scanningStatus = 'Đang khởi động AI Vision...';
  BulkScanResponse? _scanResult;
  int? _highlightedIndex;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _scanResult = null;
        _highlightedIndex = null;
      });

      _startBulkScanning();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi mở ảnh: $e')),
      );
    }
  }

  /// Khởi động quét tủ đồ qua Gemini Vision
  Future<void> _startBulkScanning() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _scanningStatus = 'Tải ảnh và kích hoạt Gemini Multimodal...';
    });

    // Cycle text status during scanning
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _isAnalyzing) {
        setState(() => _scanningStatus =
            'Gemini Vision đang quét & định vị các móc treo...');
      }
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _isAnalyzing) {
        setState(() => _scanningStatus =
            'Phân loại: Áo thun, Sơ mi, Quần jeans, Áo khoác...');
      }
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted && _isAnalyzing) {
        setState(() => _scanningStatus =
            'Nhận diện màu sắc & kiểm kê số lượng chi tiết...');
      }
    });

    try {
      final email = await TokenStorage.getUserEmail();
      final result = await _scannerService.scanWardrobePhoto(
        _selectedImage!,
        userId: email,
        saveToCloset: false,
      );

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _scanResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi quét ảnh tủ đồ: $e')),
      );
    }
  }

  Future<void> _saveAllToCloset() async {
    if (_scanResult == null || _selectedImage == null) return;

    final selectedItems =
        _scanResult!.items.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 món đồ để lưu.')),
      );
      return;
    }

    final wardrobeProvider =
        Provider.of<WardrobeProvider>(context, listen: false);

    // Chuyển đổi thành WardrobeItemModel
    final now = DateTime.now().millisecondsSinceEpoch;
    final newModels = selectedItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      return item.toWardrobeItemModel(
        itemId: 'bulk_${now}_$idx',
        fallbackImageUrl: _selectedImage!.path,
      );
    }).toList();

    // Lưu vào Local Storage & Provider
    await wardrobeProvider.addMultipleItems(newModels);

    // Gửi sync API backend ngầm
    final email = await TokenStorage.getUserEmail();
    _scannerService.commitBulkItems(
      userId: email ?? 'local_user',
      items: selectedItems,
      sourceImageUrl: _selectedImage!.path,
    );

    if (!mounted) return;

    // Show celebration dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10AC84), size: 28),
            const SizedBox(width: 10),
            Text(
              'Thành Công!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Đã thêm ${newModels.length} món đồ vào Tủ Đồ Kỹ Thuật Số của bạn!\n\nAI đã tự động phân loại danh mục, màu sắc và độ phù hợp cho trang phục.',
          style: GoogleFonts.inter(
            color: AppTheme.darkTextSecondary,
            fontSize: 14,
            height: 1.4,
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
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close bulk scan screen
            },
            child: Text(
              'Xem Tủ Đồ Ngay',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Quét Cả Tủ Đồ',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_scanResult != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primaryLight),
              onPressed: () => _pickImage(ImageSource.camera),
              tooltip: 'Chụp lại',
            ),
        ],
      ),
      body: SafeArea(
        child: _selectedImage == null
            ? _buildInitialGuideView()
            : _isAnalyzing
                ? _buildScanningAnimationView()
                : _buildScanResultView(),
      ),
      bottomNavigationBar:
          _scanResult != null && !_isAnalyzing ? _buildBottomCTA() : null,
    );
  }

  /// 1. Màn hình hướng dẫn và chụp/chọn ảnh ban đầu
  Widget _buildInitialGuideView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Banner Minh Họa
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  const Color(0xFF00D2FC).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryLight.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shelves,
                    color: AppTheme.primaryLight,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kiểm Kê Tủ Đồ Cấp Tốc',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Không cần chụp riêng từng chiếc! Chỉ cần 1 bức ảnh chụp toàn cảnh tủ hoặc sào đồ, Gemini Vision sẽ tự động đếm và nhận diện hàng loạt.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3 Mẹo chụp ảnh tối ưu
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '💡 Mẹo chụp ảnh chính xác nhất',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildTipRow(
            icon: Icons.light_mode_rounded,
            title: 'Ánh sáng rõ ràng',
            subtitle:
                'Mở cửa tủ hoặc bật đèn để AI nhận diện đúng màu sắc thật.',
          ),
          _buildTipRow(
            icon: Icons.space_bar_rounded,
            title: 'Kéo nhẹ các móc áo',
            subtitle:
                'Giúp AI phân biệt rõ từng chiếc áo thun, sơ mi hay áo khoác.',
          ),
          _buildTipRow(
            icon: Icons.crop_free_rounded,
            title: 'Chụp toàn cảnh',
            subtitle:
                'Lấy cả phần áo treo bên trên và quần/chân váy treo bên dưới.',
          ),
          const SizedBox(height: 36),

          // Nút bấm chụp hoặc chọn ảnh
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(
                    'Chụp Tủ Đồ',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: AppTheme.primaryLight.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(
                    'Chọn Từ Thư Viện',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
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

  /// 2. Hiệu ứng quét Laser AI chuyển động
  Widget _buildScanningAnimationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 280,
            height: 360,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_selectedImage != null)
                  Positioned.fill(
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                Container(
                  color: Colors.black.withOpacity(0.4),
                ),
                // Laser Beam
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Align(
                      alignment: Alignment(0, (_laserAnimation.value * 2) - 1),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D2FC),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D2FC).withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(
            color: Color(0xFF00D2FC),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _scanningStatus,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mô hình Gemini Vision Multimodal đang nhận diện',
            style: GoogleFonts.inter(
              color: AppTheme.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Hiển thị kết quả nhận diện, Bounding Box và bảng thống kê
  Widget _buildScanResultView() {
    final result = _scanResult!;
    return CustomScrollView(
      slivers: [
        // Ảnh có Bounding Box
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildInteractiveBoundingBoxViewer(result),
          ),
        ),

        // Thống kê số lượng tổng quan
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                _buildSummaryMetricsCard(result.summary, result.totalDetected),
          ),
        ),

        // Tiêu đề danh sách
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
            child: Row(
              children: [
                Text(
                  'Danh Sách Chi Tiết (${result.items.where((i) => i.isSelected).length}/${result.items.length})',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final allSelected = result.items.every((i) => i.isSelected);
                    setState(() {
                      for (final i in result.items) {
                        i.isSelected = !allSelected;
                      }
                    });
                  },
                  child: Text(
                    result.items.every((i) => i.isSelected)
                        ? 'Bỏ chọn tất cả'
                        : 'Chọn tất cả',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Danh sách từng món đồ
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = result.items[index];
                final isHighlighted = _highlightedIndex == index;
                return _buildDetectedItemTile(item, index, isHighlighted);
              },
              childCount: result.items.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Khung ảnh có vẽ Bounding Box bao quanh từng món đồ
  Widget _buildInteractiveBoundingBoxViewer(BulkScanResponse result) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // Ảnh gốc
                Positioned.fill(
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
                // Lớp phủ mờ nhẹ
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.15)),
                ),

                // Các Bounding Box
                ...result.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isHighlighted = _highlightedIndex == idx;

                  // Tọa độ chuẩn hóa [ymin, xmin, ymax, xmax] thang 0-1000
                  final ymin = (item.box2d[0] / 1000.0) * h;
                  final xmin = (item.box2d[1] / 1000.0) * w;
                  final ymax = (item.box2d[2] / 1000.0) * h;
                  final xmax = (item.box2d[3] / 1000.0) * w;

                  final boxW = (xmax - xmin).clamp(30.0, w);
                  final boxH = (ymax - ymin).clamp(30.0, h);

                  return Positioned(
                    top: ymin,
                    left: xmin,
                    width: boxW,
                    height: boxH,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _highlightedIndex = idx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isHighlighted
                                ? Colors.yellowAccent
                                : item.tagColor,
                            width: isHighlighted ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: (isHighlighted
                                  ? Colors.yellowAccent
                                  : item.tagColor)
                              .withOpacity(0.18),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? Colors.yellowAccent
                                  : item.tagColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              '${item.subCategory} • ${item.primaryColor}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isHighlighted ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Thẻ tổng quan số lượng các loại áo, quần, áo khoác, phụ kiện
  Widget _buildSummaryMetricsCard(BulkScanSummary summary, int total) {
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
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppTheme.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tổng kết phát hiện: $total món trang phục',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildCategoryMetricTile('👕 Áo', summary.topsCount),
              _buildCategoryMetricTile('👖 Quần/Váy', summary.bottomsCount),
              _buildCategoryMetricTile('🧥 Áo khoác', summary.outerwearCount),
              _buildCategoryMetricTile(
                  '👜 Khác', summary.footwearCount + summary.accessoriesCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMetricTile(String label, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.darkTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Từng dòng trong danh sách đồ phát hiện
  Widget _buildDetectedItemTile(
      DetectedClothingItem item, int index, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.yellowAccent.withOpacity(0.08)
            : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? Colors.yellowAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isSelected,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) {
              setState(() => item.isSelected = val ?? false);
            },
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.tagColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.wardrobeCategory.icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.primaryColor,
                        style: GoogleFonts.inter(
                          color: AppTheme.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•  Độ tin cậy: ${(item.confidence * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10AC84),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.darkTextSecondary, size: 18),
            onPressed: () => _editItemDialog(item),
            tooltip: 'Sửa tên',
          ),
        ],
      ),
    );
  }

  void _editItemDialog(DetectedClothingItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Chỉnh sửa tên trang phục',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên trang phục',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => item.name = controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  /// Nút Import vào Tủ Đồ ở cuối màn hình
  Widget _buildBottomCTA() {
    final selectedCount = _scanResult!.items.where((i) => i.isSelected).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        onPressed: selectedCount > 0 ? _saveAllToCloset : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Thêm Vào Tủ Đồ ($selectedCount món)',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

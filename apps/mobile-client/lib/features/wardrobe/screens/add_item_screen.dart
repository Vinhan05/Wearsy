import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/clothing_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/wardrobe_item_model.dart';
import '../providers/wardrobe_provider.dart';

class _FashionSample {
  final String title;
  final WardrobeCategory category;
  final String color;
  final String brand;
  final String imageUrl;
  final List<String> tags;
  final double aiMatchScore;

  const _FashionSample({
    required this.title,
    required this.category,
    required this.color,
    required this.brand,
    required this.imageUrl,
    required this.tags,
    required this.aiMatchScore,
  });
}

const List<_FashionSample> _defaultFashionPresets = [
  _FashionSample(
    title: 'Áo Polo Dệt Kim Be',
    category: WardrobeCategory.tops,
    color: 'Be',
    brand: 'Zara',
    imageUrl:
        'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?q=80&w=800&auto=format&fit=crop',
    tags: ['Smart Casual', 'Thanh lịch', 'Xu hướng 2026'],
    aiMatchScore: 9.6,
  ),
  _FashionSample(
    title: 'Đầm Lụa Midi Dự Tiệc',
    category: WardrobeCategory.dresses,
    color: 'Đỏ Ruby',
    brand: 'Zara',
    imageUrl:
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=800&auto=format&fit=crop',
    tags: ['Dự tiệc', 'Quyến rũ', 'Sang trọng'],
    aiMatchScore: 9.6,
  ),
  _FashionSample(
    title: 'Áo Khoác Dạ Dáng Dài',
    category: WardrobeCategory.outerwear,
    color: 'Nâu',
    brand: 'Mango',
    imageUrl:
        'https://images.unsplash.com/photo-1544441893-675973e31985?q=80&w=800&auto=format&fit=crop',
    tags: ['Mùa đông', 'Thanh lịch', 'Sang trọng'],
    aiMatchScore: 9.3,
  ),
  _FashionSample(
    title: 'Quần Jean Ống Suông Retro',
    category: WardrobeCategory.bottoms,
    color: 'Xanh Navy',
    brand: 'Levi\'s',
    imageUrl:
        'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=800&auto=format&fit=crop',
    tags: ['Streetwear', 'Casual', 'Năng động'],
    aiMatchScore: 9.1,
  ),
  _FashionSample(
    title: 'Sneakers Trắng Thể Thao',
    category: WardrobeCategory.shoes,
    color: 'Trắng',
    brand: 'Nike',
    imageUrl:
        'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800&auto=format&fit=crop',
    tags: ['Thể thao', 'Dễ phối', 'Basic'],
    aiMatchScore: 9.7,
  ),
  _FashionSample(
    title: 'Túi Xách Da Kẹp Nách',
    category: WardrobeCategory.accessories,
    color: 'Đen',
    brand: 'Charles & Keith',
    imageUrl:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=800&auto=format&fit=crop',
    tags: ['Phụ kiện', 'Túi xách', 'Trendy'],
    aiMatchScore: 9.5,
  ),
];

class AddItemScreen extends StatefulWidget {
  final String? initialMode; // 'camera' or 'gallery'
  final WardrobeItemModel? existingItem;
  const AddItemScreen({super.key, this.initialMode, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _colorController;
  late TextEditingController _customUrlController;
  TextEditingController _customTagController = TextEditingController();

  WardrobeCategory _selectedCategory = WardrobeCategory.tops;
  String? _selectedWardrobeId;
  String _currentImageUrl = _defaultFashionPresets.first.imageUrl;
  String? _localImagePath;
  List<String> _galleryImages = [];
  List<String> _selectedTags = ['Casual', 'Thanh lịch'];
  double _aiMatchScore = 9.4;
  String? _aiAnalysisReason;

  bool _isAnalyzing = false;
  bool _isCameraSimulatorOpen = false;
  late AnimationController _scanAnimController;

  final List<String> _availableColors = [
    'Trắng',
    'Đen',
    'Xanh Navy',
    'Be',
    'Xám',
    'Nâu',
    'Đỏ',
    'Vàng',
    'Pastel'
  ];

  final List<String> _popularTags = [
    'Smart Casual',
    'Công sở',
    'Streetwear',
    'Tối giản',
    'Năng động',
    'Dự tiệc',
    'Vintage'
  ];

  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
    '.bmp',
    '.gif'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController = TextEditingController(text: item.name);
      _brandController = TextEditingController(text: item.brand);
      _colorController = TextEditingController(text: item.color);
      _customUrlController = TextEditingController();
      _customTagController = TextEditingController();
      _selectedCategory = item.category;
      _selectedWardrobeId = item.wardrobeId;
      _selectedTags = List.from(item.tags);
      _aiMatchScore = item.aiMatchScore;
      if (item.imageUrl.startsWith('http')) {
        _currentImageUrl = item.imageUrl;
      } else {
        _localImagePath = item.imageUrl;
      }
      _aiAnalysisReason = 'Thông tin món đồ đã được tải để chỉnh sửa.';
    } else {
      final first = _defaultFashionPresets.first;
      _nameController = TextEditingController(text: first.title);
      _brandController = TextEditingController(text: first.brand);
      _colorController = TextEditingController(text: first.color);
      _customUrlController = TextEditingController();
      _customTagController = TextEditingController();
      _selectedCategory = first.category;
      _selectedTags = List.from(first.tags);
      _aiMatchScore = first.aiMatchScore;
      _aiAnalysisReason =
          'Chất liệu dệt kim tông be thanh lịch, tối ưu phối cùng quần âu hoặc jean.';
    }

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _loadGalleryImages();

    if (widget.initialMode == 'camera') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImageFromCamera();
      });
    } else if (widget.initialMode == 'gallery') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImageFromGallery();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _customUrlController.dispose();
    _customTagController.dispose();
    _scanAnimController.dispose();
    super.dispose();
  }

  void _addCustomTag([String? value]) {
    final tagText = (value ?? _customTagController.text).trim();
    if (tagText.isEmpty) return;

    // Tránh trùng lặp không phân biệt hoa thường
    final existingIndex = _selectedTags.indexWhere(
      (t) => t.toLowerCase() == tagText.toLowerCase(),
    );

    if (existingIndex == -1) {
      // Nếu trùng với thẻ gợi ý thì chuẩn hóa viết hoa đúng theo danh sách
      final popularMatch = _popularTags.firstWhere(
        (p) => p.toLowerCase() == tagText.toLowerCase(),
        orElse: () => '',
      );
      final tagToAdd = popularMatch.isNotEmpty ? popularMatch : tagText;
      setState(() {
        _selectedTags.add(tagToAdd);
      });
    }
    _customTagController.clear();
  }

  Future<void> _loadGalleryImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('user_wardrobe_gallery') ?? [];
      setState(() {
        _galleryImages = savedList;
      });
    } catch (_) {}
  }

  Future<void> _saveGalleryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_wardrobe_gallery', _galleryImages);
    } catch (_) {}
  }

  bool _isAllowedImageFile(String path, [String? name]) {
    final lowerPath = path.toLowerCase();
    final lowerName = (name ?? '').toLowerCase();
    final hasValidExt = _allowedExtensions.any(
      (ext) => lowerPath.endsWith(ext) || lowerName.endsWith(ext),
    );
    final hasFormatParam = _allowedExtensions.any(
      (ext) =>
          lowerPath.contains('fm=${ext.replaceAll('.', '')}') ||
          lowerPath.contains('format=${ext.replaceAll('.', '')}'),
    );
    return hasValidExt || hasFormatParam;
  }

  void _showFormatWarning([String? filename]) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Định Dạng Không Hỗ Trợ',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tệp bạn vừa chọn không phải định dạng ảnh hợp lệ${filename != null ? ' ("$filename")' : ''}.',
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hệ thống hỗ trợ các định dạng ảnh: .jpg, .jpeg, .png, .webp, .heic, .heif, .bmp, .gif',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 78,
      );
      if (image == null) return;

      if (!_isAllowedImageFile(image.path, image.name)) {
        if (mounted) _showFormatWarning(image.name);
        return;
      }

      setState(() {
        _localImagePath = image.path;
        if (!_galleryImages.contains(image.path)) {
          _galleryImages.insert(0, image.path);
        }
      });
      _saveGalleryToPrefs();
      _triggerAIScan(isCustomUpload: true, targetPath: image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở thư viện ảnh: $e'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 78,
      );
      if (image != null) {
        if (!_isAllowedImageFile(image.path, image.name)) {
          if (mounted) _showFormatWarning(image.name);
          return;
        }

        setState(() {
          _localImagePath = image.path;
          if (!_galleryImages.contains(image.path)) {
            _galleryImages.insert(0, image.path);
          }
        });
        _saveGalleryToPrefs();
        _triggerAIScan(isCustomUpload: true, targetPath: image.path);
        return;
      }
    } catch (_) {
      setState(() => _isCameraSimulatorOpen = true);
    }
  }

  void _selectGalleryItem(String path) {
    setState(() {
      if (path.startsWith('http')) {
        _localImagePath = null;
        _currentImageUrl = path;
      } else {
        _localImagePath = path;
      }
    });
    _triggerAIScan(isCustomUpload: !path.startsWith('http'), targetPath: path);
  }

  void _removeGalleryItem(String path) {
    setState(() {
      _galleryImages.remove(path);
      if (_localImagePath == path) {
        _localImagePath =
            _galleryImages.isNotEmpty ? _galleryImages.first : null;
      }
    });
    _saveGalleryToPrefs();
  }

  void _triggerAIScan({bool isCustomUpload = false, String? targetPath}) async {
    final pathToAnalyze = targetPath ?? (_localImagePath ?? _currentImageUrl);

    setState(() => _isAnalyzing = true);

    try {
      final result = await ClothingAiService.analyzeImage(pathToAnalyze);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _nameController.text = result.name;
          _selectedCategory = result.category;
          _colorController.text = result.color;
          _brandController.text = result.brand;
          _selectedTags = List.from(result.tags);
          _aiMatchScore = result.aiMatchScore;
          _aiAnalysisReason = result.aiReason;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: Color(0xFFFDCB6E), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ Gemini AI đã nhận diện trang phục!',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.category.icon} ${result.category.displayName} • Màu ${result.color} • ${result.name}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFFCFC3F5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2C2849),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.primaryColor, width: 1.2),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showUrlInputDialog() {
    _customUrlController.text = _localImagePath == null ? _currentImageUrl : '';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Dán URL ảnh',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _customUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://example.com/item.jpg',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    Icon(Icons.link_rounded, color: AppTheme.primaryLight),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '* Hỗ trợ .jpg, .jpeg, .png, .webp, .heic',
              style: GoogleFonts.inter(
                  color: AppTheme.darkTextSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final url = _customUrlController.text.trim();
              if (url.isNotEmpty) {
                if (!_isAllowedImageFile(url)) {
                  _showFormatWarning(url);
                  return;
                }
                setState(() {
                  _localImagePath = null;
                  _currentImageUrl = url;
                  if (!_galleryImages.contains(url)) {
                    _galleryImages.insert(0, url);
                  }
                });
                _saveGalleryToPrefs();
                Navigator.pop(dialogCtx);
                _triggerAIScan(targetPath: url);
              }
            },
            child: const Text('Áp dụng',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final finalImageUrl = _localImagePath ?? _currentImageUrl;
    final provider = Provider.of<WardrobeProvider>(context, listen: false);
    final targetWardrobeId = _selectedWardrobeId ?? provider.activeWardrobeId;
    final targetWardrobe = provider.collections.firstWhere(
      (c) => c.id == targetWardrobeId,
      orElse: () => provider.activeWardrobe,
    );

    final newItem = WardrobeItemModel(
      id: widget.existingItem?.id ??
          'w_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      color: _colorController.text.trim().isEmpty
          ? 'Tự do'
          : _colorController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? 'Local Brand'
          : _brandController.text.trim(),
      imageUrl: finalImageUrl,
      tags: _selectedTags.isEmpty ? ['Casual'] : _selectedTags,
      aiMatchScore: double.parse(_aiMatchScore.toStringAsFixed(1)),
      wardrobeId: targetWardrobeId,
    );

    if (widget.existingItem != null) {
      await provider.updateItem(newItem);
    } else {
      await provider.addItem(newItem);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.existingItem != null
                      ? '✨ Đã cập nhật "${newItem.name}"!'
                      : '✨ Đã thêm "${newItem.name}" vào ${targetWardrobe.icon} ${targetWardrobe.name}!',
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
    if (_isCameraSimulatorOpen) {
      return _buildCameraViewfinder();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        iconTheme: IconThemeData(color: AppTheme.darkTextPrimary),
        title: Row(
          children: [
            Icon(Icons.checkroom_rounded,
                color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text
                    : (widget.existingItem != null
                        ? 'Chỉnh Sửa Món Đồ'
                        : 'Thêm Đồ Vào Tủ'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.darkTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Quét lại bằng AI',
            icon: Icon(Icons.auto_awesome, color: AppTheme.primaryLight),
            onPressed: _isAnalyzing ? null : () => _triggerAIScan(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Image Preview & AI Scanner Frame
              _buildImageScannerHero(),
              const SizedBox(height: 16),

              // Image Source Switchers
              _buildSourceActionButtons(),
              const SizedBox(height: 24),

              // Gallery Carousel (All formats: JPG, PNG, WEBP, HEIC)
              _buildGalleryCarousel(),
              const SizedBox(height: 24),

              // Form fields
              _buildSectionTitle('Thông Tin Trang Phục 🏷️'),
              const SizedBox(height: 14),

              if (_aiAnalysisReason != null &&
                  _aiAnalysisReason!.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome,
                            color: AppTheme.primaryLight, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Gemini AI đã phân tích:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_selectedCategory.icon} ${_selectedCategory.displayName}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _aiAnalysisReason!,
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
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tên trang phục
              _buildTextField(
                controller: _nameController,
                label: 'Tên món đồ',
                icon: Icons.checkroom_rounded,
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Vui lòng nhập tên món đồ'
                    : null,
              ),
              const SizedBox(height: 16),

              // Chọn Tủ đồ mục tiêu
              _buildWardrobeSelector(),
              const SizedBox(height: 16),

              // Danh mục (Category)
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // Màu sắc chính (Đã bỏ ô Thương hiệu)
              _buildTextField(
                controller: _colorController,
                label: 'Màu sắc chính',
                icon: Icons.palette_rounded,
              ),
              const SizedBox(height: 12),

              // Quick color pills
              _buildColorPills(),
              const SizedBox(height: 18),

              // Tags phong cách
              _buildTagSelector(),
              const SizedBox(height: 24),

              // AI Match Score card
              _buildAiMatchBanner(),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon:
                        const Icon(Icons.add_task_rounded, color: Colors.white),
                    label: Text(
                      'LƯU VÀO TỦ ĐỒ',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _isAnalyzing ? null : _saveItem,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkTextPrimary,
      ),
    );
  }

  Widget _buildImageScannerHero() {
    final bool isLocal = _localImagePath != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          border: Border.all(
            color: _isAnalyzing
                ? AppTheme.primaryLight
                : Colors.white.withOpacity(0.12),
            width: _isAnalyzing ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isLocal
                ? Image.file(
                    File(_localImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          size: 50, color: Colors.white30),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: _currentImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryLight),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          size: 50, color: Colors.white30),
                    ),
                  ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppTheme.primaryLight, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isLocal ? 'Ảnh từ thiết bị' : 'Ảnh mẫu WEARSY',
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
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'AI Match: ${_aiMatchScore.toStringAsFixed(1)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isAnalyzing)
              AnimatedBuilder(
                animation: _scanAnimController,
                builder: (context, child) {
                  return Positioned(
                    top: _scanAnimController.value * 240,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryLight.withOpacity(0.8),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryLight,
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (_isAnalyzing)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryLight, strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI đang bóc tách màu sắc & nhận diện dáng đồ...',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Thư Viện Ảnh',
                color: AppTheme.secondaryColor,
                onTap: _pickImageFromGallery,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Chụp / Camera',
                color: AppTheme.primaryColor,
                onTap: _pickImageFromCamera,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.auto_fix_high_rounded,
                label: 'Quét lại bằng AI',
                color: AppTheme.primaryLight,
                onTap: _isAnalyzing ? null : () => _triggerAIScan(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.link_rounded,
                label: 'Nhập URL ảnh',
                color: AppTheme.warningColor,
                onTap: _showUrlInputDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCarousel() {
    final allDisplayList = <String>[
      ..._galleryImages,
      ..._defaultFashionPresets.map((e) => e.imageUrl),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Thư Viện Ảnh',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.4)),
                  ),
                  child: Text(
                    'JPG • PNG • WEBP • HEIC',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${allDisplayList.length} ảnh',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.darkTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allDisplayList.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.secondaryColor.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_photo_alternate_rounded,
                              color: AppTheme.secondaryColor, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+ Thêm ảnh\ntừ máy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final itemPath = allDisplayList[index - 1];
              final isLocal = !itemPath.startsWith('http');
              final isSelected = isLocal
                  ? _localImagePath == itemPath
                  : (_localImagePath == null && _currentImageUrl == itemPath);

              return GestureDetector(
                onTap: () => _selectGalleryItem(itemPath),
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryLight
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isLocal
                            ? Image.file(
                                File(itemPath),
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: itemPath,
                                fit: BoxFit.cover,
                              ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Text(
                            isLocal ? 'Ảnh của bạn' : _getPresetName(itemPath),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: AppTheme.primaryColor,
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        if (isLocal)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: GestureDetector(
                              onTap: () => _removeGalleryItem(itemPath),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white70),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getPresetName(String url) {
    for (final preset in _defaultFashionPresets) {
      if (preset.imageUrl == url) return preset.title;
    }
    return 'Ảnh mẫu';
  }

  Widget _buildWardrobeSelector() {
    final provider = Provider.of<WardrobeProvider>(context);
    final collections = provider.collections;
    final currentWardrobeId = _selectedWardrobeId ?? provider.activeWardrobeId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lưu vào Tủ Đồ 🚪',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              Text(
                '${collections.length} tủ đồ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: collections.map((col) {
              final isSelected = col.id == currentWardrobeId;
              return ChoiceChip(
                label: Text('${col.icon} ${col.name}'),
                selected: isSelected,
                showCheckmark: isSelected,
                checkmarkColor: Colors.white,
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedWardrobeId = col.id);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh mục phân loại',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WardrobeCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text('${cat.icon} ${cat.displayName}'),
                selected: isSelected,
                showCheckmark: isSelected,
                checkmarkColor: Colors.white,
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _availableColors.map((colorName) {
          final isSelected = _colorController.text.trim().toLowerCase() ==
              colorName.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor:
                  isSelected ? AppTheme.primaryColor : Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.withOpacity(0.2),
              ),
              label: Text(
                colorName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.darkTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              onPressed: () {
                setState(() => _colorController.text = colorName);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagSelector() {
    final customTags =
        _selectedTags.where((t) => !_popularTags.contains(t)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phong cách / Thẻ gợi ý',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              if (_selectedTags.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_selectedTags.length} đã chọn',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Danh sách các Chip chọn nhanh mặc định
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                showCheckmark: isSelected,
                checkmarkColor: Colors.white,
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.12),
                  ),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkTextPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      if (!_selectedTags.contains(tag)) {
                        _selectedTags.add(tag);
                      }
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),

          // 2. Các thẻ phong cách mở rộng (do AI nhận diện mới hoặc người dùng tự thêm)
          if (customTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: AppTheme.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'Phong cách mở rộng (AI nhận diện mới / Tự thêm):',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customTags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryLight.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),

          // 3. Ô TextField nhập phong cách khác
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _customTagController,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.darkTextPrimary),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (val) => _addCustomTag(val),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText:
                          'Thêm phong cách khác (ví dụ: Đi học, Y2K, Gym...)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.darkTextSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 16, color: Colors.white),
                  ),
                  tooltip: 'Thêm phong cách',
                  onPressed: () => _addCustomTag(_customTagController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMatchBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_rounded,
                color: AppTheme.primaryLight, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tương Thích Phong Cách: ${_aiMatchScore.toStringAsFixed(1)} / 10',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Món đồ này phối hợp mượt mà với hơn 8 outfits sẵn có trong tủ đồ số của bạn.',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(color: AppTheme.darkTextPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppTheme.darkTextSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 22),
        filled: true,
        fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _localImagePath != null
                ? Image.file(
                    File(_localImagePath!),
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: _currentImageUrl,
                    fit: BoxFit.cover,
                  ),
            Container(
              color: Colors.black.withOpacity(0.35),
            ),
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    onPressed: () =>
                        setState(() => _isCameraSimulatorOpen = false),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lens_blur_rounded,
                            color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'AI Auto-Detecting',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.flash_on_rounded,
                          color: Colors.amber),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 290,
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryLight, width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned(top: 8, left: 8, child: _viewfinderCorner(0)),
                    Positioned(top: 8, right: 8, child: _viewfinderCorner(1)),
                    Positioned(bottom: 8, left: 8, child: _viewfinderCorner(2)),
                    Positioned(
                        bottom: 8, right: 8, child: _viewfinderCorner(3)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Đặt trang phục nằm trọn trong khung ngắm',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Chạm nút chụp để AI phân tích trang phục',
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          final nextIndex =
                              Random().nextInt(_defaultFashionPresets.length);
                          setState(() {
                            _localImagePath = null;
                            _currentImageUrl =
                                _defaultFashionPresets[nextIndex].imageUrl;
                          });
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isCameraSimulatorOpen = false);
                          _triggerAIScan();
                        },
                        child: Container(
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 34),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() => _isCameraSimulatorOpen = false);
                          _pickImageFromGallery();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewfinderCorner(int index) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/style_profile_model.dart';

class EditStyleProfileScreen extends StatefulWidget {
  const EditStyleProfileScreen({super.key});

  @override
  State<EditStyleProfileScreen> createState() => _EditStyleProfileScreenState();
}

class _EditStyleProfileScreenState extends State<EditStyleProfileScreen> {
  final List<String> _availableStyles = [
    'Thanh lịch',
    'Minimalism',
    'Năng động',
    'Công sở',
    'Streetwear',
    'Vintage',
    'Cổ điển',
    'Hàn Quốc',
    'Bohemian',
  ];

  final List<String> _availableColors = [
    'Trắng',
    'Đen',
    'Xanh Navy',
    'Beige',
    'Xám',
    'Nâu',
    'Đỏ',
    'Xanh lá',
    'Vàng',
    'Pastel',
  ];

  late List<String> _selectedStyles;
  late List<String> _selectedColors;
  double _minBudget = 200000;
  double _maxBudget = 1500000;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedBodyShape = 'Chữ nhật (Rectangle)';

  final List<String> _bodyShapes = [
    'Chữ nhật (Rectangle)',
    'Tam giác ngược (Inverted Triangle)',
    'Đồng hồ cát (Hourglass)',
    'Hình quả lê (Pear)',
    'Hình quả táo (Apple)',
  ];

  String _getStyleLabel(String style, bool isEn) {
    if (!isEn) return style;
    switch (style) {
      case 'Thanh lịch':
        return 'Elegant';
      case 'Năng động':
        return 'Active';
      case 'Công sở':
        return 'Workwear';
      case 'Cổ điển':
        return 'Classic';
      case 'Hàn Quốc':
        return 'Korean';
      default:
        return style;
    }
  }

  String _getColorLabel(String color, bool isEn) {
    if (!isEn) return color;
    switch (color) {
      case 'Trắng':
        return 'White';
      case 'Đen':
        return 'Black';
      case 'Xanh Navy':
        return 'Navy Blue';
      case 'Xám':
        return 'Grey';
      case 'Nâu':
        return 'Brown';
      case 'Đỏ':
        return 'Red';
      case 'Xanh lá':
        return 'Green';
      case 'Vàng':
        return 'Yellow';
      default:
        return color;
    }
  }

  String _getBodyShapeLabel(String shape, bool isEn) {
    if (!isEn) return shape;
    if (shape.contains('Rectangle')) return 'Rectangle';
    if (shape.contains('Inverted Triangle')) return 'Inverted Triangle';
    if (shape.contains('Hourglass')) return 'Hourglass';
    if (shape.contains('Pear')) return 'Pear Shape';
    if (shape.contains('Apple')) return 'Apple Shape';
    return shape;
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final styleModel = user != null
        ? StyleProfileModel.fromJson(user.toJson())
        : StyleProfileModel();

    _selectedStyles = List.from(styleModel.preferredStyles);
    _selectedColors = List.from(styleModel.favoriteColors);
    _minBudget = styleModel.minBudget;
    _maxBudget = styleModel.maxBudget;

    if (styleModel.height != null) {
      _heightController.text = styleModel.height.toString();
    }
    if (styleModel.weight != null) {
      _weightController.text = styleModel.weight.toString();
    }
    if (styleModel.bodyShape != null && styleModel.bodyShape!.isNotEmpty) {
      _selectedBodyShape = styleModel.bodyShape!;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveStyleProfile() async {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final updatedModel = StyleProfileModel(
      preferredStyles: _selectedStyles,
      favoriteColors: _selectedColors,
      minBudget: _minBudget,
      maxBudget: _maxBudget,
      height: int.tryParse(_heightController.text),
      weight: int.tryParse(_weightController.text),
      bodyShape: _selectedBodyShape,
    );

    final success =
        await authProvider.updateStyleProfile(updatedModel.toJson());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? '✨ Fashion style profile updated successfully!'
              : '✨ Cập nhật Hồ sơ phong cách thời trang thành công!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pop(context);
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context); // Listen to Theme changes
    final authProvider = Provider.of<AuthProvider>(context);
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
    final currencyFormatter =
        NumberFormat.compactSimpleCurrency(locale: isEn ? 'en_US' : 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Fashion Style Profile' : 'Hồ sơ Phong cách Thời trang',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: AppTheme.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Preferred Styles
                Text(
                  isEn ? '1. Your Preferred Styles' : '1. Phong cách ưa thích của bạn',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'Select styles to help WEARSY AI suggest the best outfits for you'
                      : 'Chọn các phong cách giúp AI WEARSY gợi ý outfit chuẩn nhất với bạn',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableStyles.map((style) {
                    final isSelected = _selectedStyles.contains(style);
                    return ChoiceChip(
                      label: Text(_getStyleLabel(style, isEn)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.darkSurface,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.darkTextSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryLight
                              : Colors.transparent,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStyles.add(style);
                          } else {
                            _selectedStyles.remove(style);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // Section 2: Favorite Colors
                Text(
                  isEn ? '2. Favorite Colors' : '2. Tông màu yêu thích',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableColors.map((color) {
                    final isSelected = _selectedColors.contains(color);
                    return FilterChip(
                      label: Text(_getColorLabel(color, isEn)),
                      selected: isSelected,
                      selectedColor: AppTheme.secondaryColor.withOpacity(0.8),
                      backgroundColor: AppTheme.darkSurface,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.black
                            : AppTheme.darkTextSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedColors.add(color);
                          } else {
                            _selectedColors.remove(color);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // Section 3: Budget Range Slider
                Text(
                  isEn ? '3. Estimated Shopping Budget' : '3. Ngân sách mua sắm ước tính',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? '${currencyFormatter.format(_minBudget)} - ${currencyFormatter.format(_maxBudget)} / item'
                      : '${currencyFormatter.format(_minBudget)} - ${currencyFormatter.format(_maxBudget)} / sản phẩm',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                RangeSlider(
                  values: RangeValues(_minBudget, _maxBudget),
                  min: 100000,
                  max: 5000000,
                  divisions: 49,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.darkSurface,
                  labels: RangeLabels(
                    currencyFormatter.format(_minBudget),
                    currencyFormatter.format(_maxBudget),
                  ),
                  onChanged: (values) {
                    setState(() {
                      _minBudget = values.start;
                      _maxBudget = values.end;
                    });
                  },
                ),

                const SizedBox(height: 28),

                // Section 4: Body Measurements
                Text(
                  isEn
                      ? '4. Body Metrics & Measurements (Optional)'
                      : '4. Chỉ số cơ thể & Vóc dáng (Tùy chọn)',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Height (cm)' : 'Chiều cao (cm)',
                            style: GoogleFonts.inter(
                                color: AppTheme.darkTextPrimary, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.darkTextPrimary),
                            decoration: const InputDecoration(
                              hintText: '170',
                              suffixText: 'cm',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Weight (kg)' : 'Cân nặng (kg)',
                            style: GoogleFonts.inter(
                                color: AppTheme.darkTextPrimary, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.darkTextPrimary),
                            decoration: const InputDecoration(
                              hintText: '62',
                              suffixText: 'kg',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isEn ? 'Body Shape Type' : 'Kiểu vóc dáng cơ thể',
                  style: GoogleFonts.inter(
                      color: AppTheme.darkTextPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBodyShape,
                  dropdownColor: AppTheme.darkCard,
                  style: TextStyle(color: AppTheme.darkTextPrimary),
                  decoration: const InputDecoration(),
                  items: _bodyShapes.map((shape) {
                    return DropdownMenuItem(
                      value: shape,
                      child: Text(_getBodyShapeLabel(shape, isEn)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedBodyShape = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 36),

                // Save Button
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          authProvider.isLoading ? null : _saveStyleProfile,
                      child: authProvider.isLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.white, size: 24)
                          : Text(
                              isEn
                                  ? 'SAVE STYLE PROFILE'
                                  : 'LƯU HỒ SƠ PHONG CÁCH',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

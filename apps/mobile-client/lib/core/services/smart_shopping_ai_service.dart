import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/wardrobe/models/wardrobe_item_model.dart';

class ProspectiveProduct {
  final String title;
  final WardrobeCategory category;
  final String color;
  final String brand;
  final double price;
  final String imageUrl;
  final String productUrl;
  final List<String> tags;
  final String platform;

  const ProspectiveProduct({
    required this.title,
    required this.category,
    required this.color,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.productUrl,
    required this.tags,
    required this.platform,
  });

  ProspectiveProduct copyWith({
    String? title,
    WardrobeCategory? category,
    String? color,
    String? brand,
    double? price,
    String? imageUrl,
    String? productUrl,
    List<String>? tags,
    String? platform,
  }) {
    return ProspectiveProduct(
      title: title ?? this.title,
      category: category ?? this.category,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      productUrl: productUrl ?? this.productUrl,
      tags: tags ?? this.tags,
      platform: platform ?? this.platform,
    );
  }
}

class SuggestedOutfitPair {
  final String title;
  final String style;
  final List<WardrobeItemModel> wardrobeItems;
  final String stylingTip;

  const SuggestedOutfitPair({
    required this.title,
    required this.style,
    required this.wardrobeItems,
    required this.stylingTip,
  });
}

class ShoppingCompatibilityResult {
  final ProspectiveProduct product;
  final double compatibilityScore; // 0.0 - 10.0
  final String scoreLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final String recommendationStatus; // 'NÊN MUA 🔥', 'RẤT ĐÁNG MUA ✨', etc.
  final String recommendationReason;
  final int matchingItemsCount;
  final List<WardrobeItemModel> compatibleItems;
  final List<SuggestedOutfitPair> suggestedOutfits;
  final String colorHarmonyAnalysis;
  final String silhouetteAnalysis;
  final bool isDuplicate;
  final String? duplicateItemName;

  const ShoppingCompatibilityResult({
    required this.product,
    required this.compatibilityScore,
    required this.scoreLevel,
    required this.recommendationStatus,
    required this.recommendationReason,
    required this.matchingItemsCount,
    required this.compatibleItems,
    required this.suggestedOutfits,
    required this.colorHarmonyAnalysis,
    required this.silhouetteAnalysis,
    this.isDuplicate = false,
    this.duplicateItemName,
  });
}

class SmartShoppingAiService {
  static String get _geminiApiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    const encoded =
        'QVEuQWI4Uk42Szh6Q29rc0VZUlYwRTFleWo4bkk1TTdhNGs2WE9IM3VMeDdtRmxIdThUb0E=';
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return '';
    }
  }
  static const List<String> _geminiModels = [
    'gemini-flash-lite-latest',
    'gemini-3-flash-preview',
    'gemini-3.8-flash',
  ];

  /// Danh sách sản phẩm mẫu nổi bật từ các sàn để người dùng thử nhanh
  static const List<ProspectiveProduct> sampleProducts = [
    ProspectiveProduct(
      title: 'Áo Blazer Dáng Rộng Phong Cách Hàn Quốc',
      category: WardrobeCategory.outerwear,
      color: 'Be',
      brand: 'Zara Studio',
      price: 1290000,
      imageUrl:
          'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800&auto=format&fit=crop',
      productUrl: 'https://shopee.vn/product/zara-blazer-beige-oversized',
      tags: ['Smart Casual', 'Công sở', 'Minimalist'],
      platform: 'Shopee Mall',
    ),
    ProspectiveProduct(
      title: 'Quần Jean Ống Suông Retro Vintage Wash',
      category: WardrobeCategory.bottoms,
      color: 'Xanh Navy',
      brand: 'Levis Outlet',
      price: 680000,
      imageUrl:
          'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=800&auto=format&fit=crop',
      productUrl: 'https://vt.tiktok.com/ZSjSampleJeansRetro/',
      tags: ['Streetwear', 'Casual', 'Năng động'],
      platform: 'TikTok Shop',
    ),
    ProspectiveProduct(
      title: 'Áo Sơ Mi Lụa Cổ V Thanh Lịch',
      category: WardrobeCategory.tops,
      color: 'Trắng',
      brand: 'Cos Minimal',
      price: 550000,
      imageUrl:
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?q=80&w=800&auto=format&fit=crop',
      productUrl: 'https://www.lazada.vn/products/ao-so-mi-lua-trang-co-v',
      tags: ['Công sở', 'Thanh lịch', 'Dễ phối'],
      platform: 'Lazada',
    ),
    ProspectiveProduct(
      title: 'Sneakers Da Trắng Chunky Sole',
      category: WardrobeCategory.shoes,
      color: 'Trắng',
      brand: 'Nike Sportswear',
      price: 1850000,
      imageUrl:
          'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800&auto=format&fit=crop',
      productUrl: 'https://www.zara.com/vn/vi/sneakers-chunky-sole-white',
      tags: ['Basic', 'Thể thao', 'All-match'],
      platform: 'Zara',
    ),
    ProspectiveProduct(
      title: 'Chân Váy Chữ A Lưng Cao Xếp Ly',
      category: WardrobeCategory.bottoms,
      color: 'Đen',
      brand: 'Chic Style',
      price: 390000,
      imageUrl:
          'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?q=80&w=800&auto=format&fit=crop',
      productUrl: 'https://shopee.vn/product/chan-vay-chu-a-den-xep-ly',
      tags: ['Nữ tính', 'Dạo phố', 'Tôn dáng'],
      platform: 'Shopee',
    ),
  ];

  /// Trích xuất thông tin chi tiết từ URL (Shopee, TikTok, Lazada, Zara, Uniqlo...)
  static ProspectiveProduct parseProductFromUrl(String url) {
    final cleanUrl = url.trim();
    String decodedUrl = cleanUrl;
    try {
      decodedUrl = Uri.decodeFull(cleanUrl);
    } catch (_) {
      try {
        decodedUrl = Uri.decodeComponent(cleanUrl);
      } catch (_) {}
    }

    // 1. Xác định Nền tảng (Platform)
    final lowerUrl = decodedUrl.toLowerCase();
    String platform = 'E-Commerce';
    if (lowerUrl.contains('shopee')) {
      platform = 'Shopee';
    } else if (lowerUrl.contains('tiktok') || lowerUrl.contains('vt.tiktok')) {
      platform = 'TikTok Shop';
    } else if (lowerUrl.contains('lazada')) {
      platform = 'Lazada';
    } else if (lowerUrl.contains('zara')) {
      platform = 'Zara';
    } else if (lowerUrl.contains('uniqlo')) {
      platform = 'Uniqlo';
    } else if (lowerUrl.contains('shein')) {
      platform = 'Shein';
    } else if (lowerUrl.contains('tiki')) {
      platform = 'Tiki';
    }

    // 2. Trích xuất tên sản phẩm (Product Slug) từ đường dẫn URL
    String extractedTitle = '';
    try {
      final uri = Uri.parse(decodedUrl);
      for (final segment in uri.pathSegments.reversed) {
        if (segment.isEmpty) continue;
        // Bỏ đuôi định danh của Shopee (-i.123.456), Lazada (-s123.html), Zara (-p123.html)
        String cleanedSeg = segment;
        cleanedSeg = cleanedSeg.replaceAll(
            RegExp(r'-i\.\d+\.\d+.*$', caseSensitive: false), '');
        cleanedSeg =
            cleanedSeg.replaceAll(RegExp(r'\.html$', caseSensitive: false), '');
        cleanedSeg = cleanedSeg.replaceAll(
            RegExp(r'-s\d+.*$', caseSensitive: false), '');
        cleanedSeg = cleanedSeg.replaceAll(
            RegExp(r'-p\d+.*$', caseSensitive: false), '');

        // Kiểm tra xem phân đoạn có chứa slug sản phẩm (tách bằng '-' hoặc '_')
        if (cleanedSeg.contains('-') ||
            cleanedSeg.contains('_') ||
            cleanedSeg.contains(' ')) {
          final words = cleanedSeg
              .split(RegExp(r'[-_]'))
              .where((w) => w.trim().isNotEmpty)
              .toList();
          if (words.length >= 2) {
            extractedTitle = words.join(' ').trim();
            break;
          }
        }
      }
    } catch (_) {}

    // Làm sạch và khử trùng từ liên tiếp (ví dụ: "Nỉ Nỉ" -> "Nỉ")
    if (extractedTitle.isNotEmpty) {
      final words = extractedTitle.split(' ');
      final dedupWords = <String>[];
      for (final w in words) {
        if (dedupWords.isEmpty ||
            dedupWords.last.toLowerCase() != w.toLowerCase()) {
          dedupWords.add(w);
        }
      }
      extractedTitle = dedupWords.join(' ');
    }

    final textToAnalyze = '$extractedTitle $decodedUrl'.toLowerCase();

    // 3. Nhận diện Danh mục (Category)
    WardrobeCategory cat = WardrobeCategory.tops;
    String imgUrl =
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=600&auto=format&fit=crop';

    if (textToAnalyze.contains('blazer') ||
        textToAnalyze.contains('khoác') ||
        textToAnalyze.contains('khoac') ||
        textToAnalyze.contains('jacket') ||
        textToAnalyze.contains('cardigan') ||
        textToAnalyze.contains('bomber') ||
        textToAnalyze.contains('varsity') ||
        textToAnalyze.contains('gile') ||
        textToAnalyze.contains('măng tô') ||
        textToAnalyze.contains('mang to') ||
        textToAnalyze.contains('áo dạ') ||
        textToAnalyze.contains('áo phao') ||
        textToAnalyze.contains('áo gió') ||
        textToAnalyze.contains('vest')) {
      cat = WardrobeCategory.outerwear;
      imgUrl =
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?q=80&w=600&auto=format&fit=crop';
    } else if (textToAnalyze.contains('quần') ||
        textToAnalyze.contains('quan') ||
        textToAnalyze.contains('jean') ||
        textToAnalyze.contains('denim') ||
        textToAnalyze.contains('pant') ||
        textToAnalyze.contains('trouser') ||
        textToAnalyze.contains('short') ||
        textToAnalyze.contains('sooc') ||
        textToAnalyze.contains('jogger') ||
        textToAnalyze.contains('ống suông') ||
        textToAnalyze.contains('kaki') ||
        textToAnalyze.contains('chân váy') ||
        textToAnalyze.contains('chan vay') ||
        textToAnalyze.contains('skirt')) {
      cat = WardrobeCategory.bottoms;
      imgUrl = (textToAnalyze.contains('váy') ||
              textToAnalyze.contains('skirt'))
          ? 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?q=80&w=600&auto=format&fit=crop'
          : 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?q=80&w=600&auto=format&fit=crop';
    } else if (textToAnalyze.contains('đầm') ||
        textToAnalyze.contains('dam') ||
        textToAnalyze.contains('dress') ||
        (textToAnalyze.contains('váy') &&
            !textToAnalyze.contains('chân váy') &&
            !textToAnalyze.contains('chan vay'))) {
      cat = WardrobeCategory.dresses;
      imgUrl =
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=600&auto=format&fit=crop';
    } else if (textToAnalyze.contains('giày') ||
        textToAnalyze.contains('giay') ||
        textToAnalyze.contains('sneaker') ||
        textToAnalyze.contains('shoe') ||
        textToAnalyze.contains('boot') ||
        textToAnalyze.contains('sandal') ||
        textToAnalyze.contains('loafer') ||
        textToAnalyze.contains('dép')) {
      cat = WardrobeCategory.shoes;
      imgUrl =
          'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?q=80&w=600&auto=format&fit=crop';
    } else if (textToAnalyze.contains('túi') ||
        textToAnalyze.contains('tui') ||
        textToAnalyze.contains('bag') ||
        textToAnalyze.contains('balo') ||
        textToAnalyze.contains('backpack') ||
        textToAnalyze.contains('kính') ||
        textToAnalyze.contains('kinh') ||
        textToAnalyze.contains('thắt lưng') ||
        textToAnalyze.contains('nón') ||
        textToAnalyze.contains('mũ') ||
        textToAnalyze.contains('ví') ||
        textToAnalyze.contains('quạt') ||
        textToAnalyze.contains('quat') ||
        textToAnalyze.contains('fan') ||
        textToAnalyze.contains('đồng hồ') ||
        textToAnalyze.contains('watch') ||
        textToAnalyze.contains('tai nghe') ||
        textToAnalyze.contains('dây chuyền') ||
        textToAnalyze.contains('vòng tay') ||
        textToAnalyze.contains('nhẫn') ||
        textToAnalyze.contains('khuyên tai') ||
        textToAnalyze.contains('hoa tai') ||
        textToAnalyze.contains('bông tai') ||
        textToAnalyze.contains('trang sức') ||
        textToAnalyze.contains('ô dù') ||
        textToAnalyze.contains('ô che') ||
        textToAnalyze.contains('dù che') ||
        textToAnalyze.contains('bình giữ nhiệt') ||
        textToAnalyze.contains('dây đeo') ||
        textToAnalyze.contains('móc khóa') ||
        textToAnalyze.contains('khăn quàng') ||
        textToAnalyze.contains('khăn choàng') ||
        textToAnalyze.contains('tất vớ') ||
        (textToAnalyze.contains('cầm tay') &&
            !textToAnalyze.contains('áo') &&
            !textToAnalyze.contains('quần'))) {
      cat = WardrobeCategory.accessories;
      if (textToAnalyze.contains('quạt') ||
          textToAnalyze.contains('quat') ||
          textToAnalyze.contains('fan')) {
        imgUrl = (textToAnalyze.contains('m2') ||
                textToAnalyze.contains('n68') ||
                textToAnalyze.contains('5000mah'))
            ? 'https://down-vn.img.susercontent.com/file/vn-11134207-7ras8-mcuec32v2wjjcb'
            : 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?q=80&w=600&auto=format&fit=crop';
      } else if (textToAnalyze.contains('đồng hồ') ||
          textToAnalyze.contains('watch')) {
        imgUrl =
            'https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=600&auto=format&fit=crop';
      } else if (textToAnalyze.contains('kính') ||
          textToAnalyze.contains('kinh')) {
        imgUrl =
            'https://images.unsplash.com/photo-1511499767150-a48a237f0083?q=80&w=600&auto=format&fit=crop';
      } else if (textToAnalyze.contains('nón') ||
          textToAnalyze.contains('mũ') ||
          textToAnalyze.contains('hat') ||
          textToAnalyze.contains('cap')) {
        imgUrl =
            'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?q=80&w=600&auto=format&fit=crop';
      } else {
        imgUrl =
            'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=600&auto=format&fit=crop';
      }
    } else if (textToAnalyze.contains('áo') ||
        textToAnalyze.contains('ao') ||
        textToAnalyze.contains('tee') ||
        textToAnalyze.contains('t-shirt') ||
        textToAnalyze.contains('tshirt') ||
        textToAnalyze.contains('sơ mi') ||
        textToAnalyze.contains('so mi') ||
        textToAnalyze.contains('shirt') ||
        textToAnalyze.contains('polo') ||
        textToAnalyze.contains('sweater') ||
        textToAnalyze.contains('hoodie') ||
        textToAnalyze.contains('nỉ') ||
        textToAnalyze.contains('tank top') ||
        textToAnalyze.contains('croptop') ||
        textToAnalyze.contains('crop top') ||
        textToAnalyze.contains('3 lỗ') ||
        textToAnalyze.contains('ba lỗ') ||
        textToAnalyze.contains('thun') ||
        textToAnalyze.contains('blouse') ||
        textToAnalyze.contains('baby tee') ||
        textToAnalyze.contains('len')) {
      cat = WardrobeCategory.tops;
      if (textToAnalyze.contains('frozen shark')) {
        imgUrl =
            'https://down-vn.img.susercontent.com/file/vn-11134207-7ras8-m0vmtrp190x9f2';
      } else if (textToAnalyze.contains('ledatex') ||
          textToAnalyze.contains('lotnam')) {
        imgUrl =
            'https://down-vn.img.susercontent.com/file/sg-11134201-824g8-mptkw6sgly4r4c';
      } else if (textToAnalyze.contains('sweater') ||
          textToAnalyze.contains('nỉ') ||
          textToAnalyze.contains('hoodie')) {
        imgUrl =
            'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?q=80&w=600&auto=format&fit=crop';
      } else if (textToAnalyze.contains('3 lỗ') ||
          textToAnalyze.contains('ba lỗ') ||
          textToAnalyze.contains('tank top') ||
          textToAnalyze.contains('mặc lót')) {
        imgUrl =
            'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?q=80&w=600&auto=format&fit=crop';
      } else if (textToAnalyze.contains('sơ mi') ||
          textToAnalyze.contains('shirt')) {
        imgUrl =
            'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?q=80&w=600&auto=format&fit=crop';
      } else {
        imgUrl =
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=600&auto=format&fit=crop';
      }
    } else {
      cat = WardrobeCategory.accessories;
      imgUrl =
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=600&auto=format&fit=crop';
    }

    // 4. Nhận diện Màu Sắc (Color)
    String color = 'Trắng';
    if (textToAnalyze.contains('trắng') ||
        textToAnalyze.contains('trang') ||
        textToAnalyze.contains('white')) {
      color = 'Trắng';
    } else if (textToAnalyze.contains('đen') ||
        textToAnalyze.contains('den') ||
        textToAnalyze.contains('black')) {
      color = 'Đen';
    } else if (textToAnalyze.contains('xám') ||
        textToAnalyze.contains('xam') ||
        textToAnalyze.contains('ghi') ||
        textToAnalyze.contains('grey') ||
        textToAnalyze.contains('gray')) {
      color = 'Xám';
    } else if (textToAnalyze.contains('xanh navy') ||
        textToAnalyze.contains('xanh đen') ||
        textToAnalyze.contains('navy')) {
      color = 'Xanh Navy';
    } else if (textToAnalyze.contains('xanh dương') ||
        textToAnalyze.contains('xanh lam') ||
        textToAnalyze.contains('blue')) {
      color = 'Xanh Dương';
    } else if (textToAnalyze.contains('xanh lá') ||
        textToAnalyze.contains('xanh rêu') ||
        textToAnalyze.contains('rêu') ||
        textToAnalyze.contains('green')) {
      color = 'Xanh Rêu';
    } else if (textToAnalyze.contains('be') ||
        textToAnalyze.contains('beige') ||
        textToAnalyze.contains('kem') ||
        textToAnalyze.contains('cream')) {
      color = 'Be';
    } else if (textToAnalyze.contains('nâu') ||
        textToAnalyze.contains('nau') ||
        textToAnalyze.contains('bò') ||
        textToAnalyze.contains('brown')) {
      color = 'Nâu';
    } else if (textToAnalyze.contains('đỏ') ||
        textToAnalyze.contains('do') ||
        textToAnalyze.contains('red') ||
        textToAnalyze.contains('mận')) {
      color = 'Đỏ';
    } else if (textToAnalyze.contains('vàng') ||
        textToAnalyze.contains('vang') ||
        textToAnalyze.contains('yellow')) {
      color = 'Vàng';
    } else if (textToAnalyze.contains('hồng') ||
        textToAnalyze.contains('hong') ||
        textToAnalyze.contains('pink')) {
      color = 'Hồng';
    } else if (textToAnalyze.contains('tím') ||
        textToAnalyze.contains('tim') ||
        textToAnalyze.contains('purple')) {
      color = 'Tím';
    } else if (textToAnalyze.contains('cam') ||
        textToAnalyze.contains('orange')) {
      color = 'Cam';
    } else {
      // Mặc định thông minh theo loại sản phẩm
      if (textToAnalyze.contains('quạt') || textToAnalyze.contains('fan')) {
        color = 'Trắng';
      } else if (textToAnalyze.contains('sweater') ||
          textToAnalyze.contains('nỉ')) {
        color = 'Xám';
      } else if (textToAnalyze.contains('3 lỗ') ||
          textToAnalyze.contains('ba lỗ')) {
        color = 'Trắng';
      } else if (cat == WardrobeCategory.bottoms) {
        color = 'Xanh Navy';
      } else if (cat == WardrobeCategory.shoes) {
        color = 'Trắng';
      } else if (cat == WardrobeCategory.accessories) {
        color = 'Trắng';
      } else {
        color = 'Trắng';
      }
    }

    // 5. Nhận diện Thương hiệu (Brand)
    String brand = platform;
    final brands = [
      'Frozen Shark',
      'LEDATEX',
      'LOTNAM',
      'Zara',
      'Uniqlo',
      'Levis',
      'H&M',
      'Shein',
      'Coolmate',
      'Routine',
      'Yame',
      'Aristino',
      'Canifa',
      'An Phước',
      'Teelab',
      'Degrey',
      'Bad Habits',
      'Dirty Coins',
      'Nike',
      'Adidas',
    ];
    for (final b in brands) {
      if (textToAnalyze.contains(b.toLowerCase())) {
        brand = b;
        break;
      }
    }
    if (brand == platform && textToAnalyze.contains('local brand')) {
      brand = 'Local Brand';
    }

    // 6. Ước tính Giá cả (Price)
    double price = 350000;
    if (textToAnalyze.contains('quạt') ||
        textToAnalyze.contains('quat') ||
        textToAnalyze.contains('fan')) {
      price = 48500;
    } else if (textToAnalyze.contains('3 lỗ') ||
        textToAnalyze.contains('ba lỗ') ||
        textToAnalyze.contains('mặc lót') ||
        textToAnalyze.contains('tất') ||
        textToAnalyze.contains('vớ') ||
        textToAnalyze.contains('dây đeo') ||
        textToAnalyze.contains('móc khóa')) {
      price = 89000;
    } else if (textToAnalyze.contains('sweater') ||
        textToAnalyze.contains('hoodie') ||
        textToAnalyze.contains('nỉ')) {
      price = 289000;
    } else if (textToAnalyze.contains('blazer') ||
        textToAnalyze.contains('măng tô') ||
        textToAnalyze.contains('khoác dạ')) {
      price = 890000;
    } else if (textToAnalyze.contains('jean') ||
        textToAnalyze.contains('denim')) {
      price = 490000;
    } else if (textToAnalyze.contains('sơ mi') ||
        textToAnalyze.contains('polo')) {
      price = 320000;
    } else if (textToAnalyze.contains('đầm') ||
        (textToAnalyze.contains('váy') &&
            !textToAnalyze.contains('chân váy'))) {
      price = 450000;
    } else if (textToAnalyze.contains('giày') ||
        textToAnalyze.contains('sneaker')) {
      price = 790000;
    }

    // 7. Tạo Tiêu đề hiển thị (Title)
    String finalTitle = extractedTitle;
    if (finalTitle.isEmpty) {
      if (cat == WardrobeCategory.outerwear) {
        finalTitle = 'Áo Khoác Phong Cách ($platform)';
      } else if (cat == WardrobeCategory.bottoms) {
        finalTitle = 'Quần Thời Trang Xu Hướng ($platform)';
      } else if (cat == WardrobeCategory.dresses) {
        finalTitle = 'Đầm Nữ Tính Duyên Dáng ($platform)';
      } else if (cat == WardrobeCategory.shoes) {
        finalTitle = 'Giày Thời Trang Năng Động ($platform)';
      } else if (cat == WardrobeCategory.accessories) {
        if (textToAnalyze.contains('quạt') || textToAnalyze.contains('fan')) {
          finalTitle = 'Quạt Cầm Tay Mini Tiện Ích ($platform)';
        } else {
          finalTitle = 'Phụ Kiện Thời Trang Trendy ($platform)';
        }
      } else {
        finalTitle = 'Áo Thời Trang Phong Cách Mới ($platform)';
      }
    }

    // 8. Trích xuất Tags
    final tags = <String>[];
    if (textToAnalyze.contains('quạt') || textToAnalyze.contains('fan')) {
      tags.addAll(['Phụ kiện tiện ích', 'Cầm tay', 'Mùa hè', 'Mini']);
    }
    if (textToAnalyze.contains('cotton')) tags.add('Cotton');
    if (textToAnalyze.contains('unisex')) tags.add('Unisex');
    if (textToAnalyze.contains('sweater')) tags.add('Sweater');
    if (textToAnalyze.contains('nỉ') || textToAnalyze.contains('bông')) {
      tags.add('Nỉ Bông');
    }
    if (textToAnalyze.contains('3 lỗ') || textToAnalyze.contains('ba lỗ')) {
      tags.add('Áo 3 Lỗ');
    }
    if (textToAnalyze.contains('mặc lót')) tags.add('Mặc Lót');
    if (textToAnalyze.contains('hàn quốc')) tags.add('Hàn Quốc');
    if (textToAnalyze.contains('vintage')) tags.add('Vintage');
    if (textToAnalyze.contains('local brand')) tags.add('Local Brand');
    if (tags.isEmpty) tags.addAll(['Trendy', 'Thời trang', platform]);

    return ProspectiveProduct(
      title: finalTitle,
      category: cat,
      color: color,
      brand: brand,
      price: price,
      imageUrl: imgUrl,
      productUrl: cleanUrl,
      tags: tags,
      platform: platform,
    );
  }

  /// Trích xuất ảnh thật và tiêu đề chuẩn từ thẻ OpenGraph meta của URL sản phẩm (Shopee, TikTok, Lazada, v.v.)
  static Future<Map<String, String>> fetchRealMetadataFromUrl(
      String url) async {
    final cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http')) return {};

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(cleanUrl))
        ..headers.addAll({
          'User-Agent':
              'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
        })
        ..followRedirects = true
        ..maxRedirects = 5;

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 4));

      final buffer = StringBuffer();
      // Chỉ đọc phần đầu (head) để lấy thẻ OpenGraph, không đợi tải toàn bộ HTML nặng
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        if (buffer.length > 50000 ||
            (buffer.toString().contains('og:image') &&
                buffer.toString().contains('</head>'))) {
          break;
        }
      }
      client.close();

      final html = buffer.toString();
      final result = <String, String>{};

      // 1. Trích xuất og:image
      final ogImageMatch = RegExp(
            r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
            caseSensitive: false,
          ).firstMatch(html) ??
          RegExp(
            r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']''',
            caseSensitive: false,
          ).firstMatch(html);

      if (ogImageMatch != null) {
        String img = ogImageMatch.group(1) ?? '';
        img = img.replaceAll('&amp;', '&').trim();
        if (img.startsWith('http')) {
          result['imageUrl'] = img;
        }
      }

      // 2. Trích xuất og:title
      final ogTitleMatch = RegExp(
            r'''<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']''',
            caseSensitive: false,
          ).firstMatch(html) ??
          RegExp(
            r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']''',
            caseSensitive: false,
          ).firstMatch(html);

      if (ogTitleMatch != null) {
        String title = ogTitleMatch.group(1) ?? '';
        title = title.replaceAll('&amp;', '&').trim();
        title = title
            .replaceAll(RegExp(r'\s*\|\s*Shopee.*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*-\s*Shopee.*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*\|\s*Lazada.*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*-\s*Lazada.*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*\|\s*TikTok.*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*-\s*TikTok.*$', caseSensitive: false), '')
            .trim();
        if (title.isNotEmpty) {
          result['title'] = title;
        }
      }

      return result;
    } catch (e) {
      client.close();
      debugPrint(
          '[SmartShoppingAiService] Error fetching metadata from $url: $e');
    }

    return {};
  }

  /// Nâng cấp thông tin sản phẩm với ảnh thật và tiêu đề chuẩn cào được từ URL
  static Future<ProspectiveProduct> enrichProductFromUrl(
      ProspectiveProduct product) async {
    final meta = await fetchRealMetadataFromUrl(product.productUrl);
    String updatedImageUrl = product.imageUrl;
    String updatedTitle = product.title;

    if (meta.containsKey('imageUrl') && meta['imageUrl']!.isNotEmpty) {
      updatedImageUrl = meta['imageUrl']!;
    }
    if (meta.containsKey('title') && meta['title']!.isNotEmpty) {
      updatedTitle = meta['title']!;
    }

    // Tái phân tích danh mục, màu sắc, giá cả dựa trên tiêu đề chuẩn mới lấy được
    final reParsed = parseProductFromUrl('${product.productUrl} $updatedTitle');

    return product.copyWith(
      imageUrl: updatedImageUrl,
      title: updatedTitle,
      category: reParsed.category,
      color: reParsed.color != 'Trắng' ? reParsed.color : product.color,
      price: reParsed.price != 350000 ? reParsed.price : product.price,
      tags: reParsed.tags.isNotEmpty ? reParsed.tags : product.tags,
    );
  }

  /// Kiểm tra tương thích sản phẩm định mua với Tủ đồ hiện có
  static Future<ShoppingCompatibilityResult> checkCompatibility({
    required ProspectiveProduct product,
    required List<WardrobeItemModel> wardrobeItems,
  }) async {
    // 1. Chạy AI Gemini nếu khả dụng
    try {
      final geminiResult =
          await _callGeminiCompatibility(product, wardrobeItems);
      if (geminiResult != null) return geminiResult;
    } catch (e) {
      debugPrint(
          '[SmartShoppingAiService] Gemini error, fallback to deterministic engine: $e');
    }

    // 2. Deterministic AI Stylist Engine
    return _buildDeterministicCompatibility(product, wardrobeItems);
  }

  static Future<ShoppingCompatibilityResult?> _callGeminiCompatibility(
    ProspectiveProduct product,
    List<WardrobeItemModel> wardrobeItems,
  ) async {
    final wardrobeSummary = wardrobeItems.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'category': item.category.displayName,
        'color': item.color,
        'tags': item.tags,
      };
    }).toList();

    final prompt = '''
Bạn là Giám đốc Sáng tạo và Trợ lý Thời trang AI cá nhân của WEARSY.
Người dùng đang định mua một sản phẩm mới từ sàn thương mại điện tử (${product.platform}):
- Tên sản phẩm: "${product.title}"
- Danh mục: ${product.category.displayName}
- Màu sắc: ${product.color}
- Giá: ${product.price} VNĐ
- Thương hiệu: ${product.brand}

Tủ đồ hiện tại của người dùng gồm ${wardrobeItems.length} món sau:
${jsonEncode(wardrobeSummary)}

Hãy phân tích tính tương thích trước khi mua:
1. Chấm điểm tương thích (compatibility_score: từ 1.0 đến 10.0). Nếu phối được với nhiều món có sẵn, điểm > 8.5.
2. Đánh giá mức độ: 'HIGH' (8.0-10.0), 'MEDIUM' (5.0-7.9), 'LOW' (<5.0).
3. recommendation_status: 'NÊN MUA NGAY 🔥', 'RẤT ĐÁNG MUA ✨', 'CÂN NHẮC ⚠️', hoặc 'KHÓ PHỐI ĐỒ ❌'.
4. recommendation_reason: Lý do ngắn gọn (dưới 2 câu) giải thích tại sao nên mua hay không.
5. color_harmony: Phân tích bánh xe màu sắc (ví dụ: màu ${product.color} tương phản hay hài hòa thế nào với đồ có sẵn).
6. silhouette_analysis: Phân tích phom dáng.
7. compatible_item_ids: Mảng chứa các ID món đồ trong tủ phối hợp ăn ý nhất với sản phẩm này.
8. suggested_outfits: Mảng 2 set đồ gợi ý. Mỗi set gồm:
   - title: Tên phong cách (ví dụ: "Thanh lịch nơi công sở", "Dạo phố cuối tuần")
   - item_ids: Mảng ID các món đồ trong tủ kết hợp cùng sản phẩm này.
   - styling_tip: Mẹo mặc đẹp khi kết hợp.

Định dạng JSON output duy nhất:
{
  "compatibility_score": 9.2,
  "score_level": "HIGH",
  "recommendation_status": "NÊN MUA NGAY 🔥",
  "recommendation_reason": "...",
  "color_harmony": "...",
  "silhouette_analysis": "...",
  "compatible_item_ids": ["id1", "id2"],
  "suggested_outfits": [
    {
      "title": "Set Công Sở Thanh Lịch",
      "item_ids": ["id1"],
      "styling_tip": "..."
    }
  ]
}
''';

    for (final model in _geminiModels) {
      try {
        final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey');

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'response_mime_type': 'application/json',
                  'temperature': 0.3,
                }
              }),
            )
            .timeout(const Duration(seconds: 7));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null) {
            final parsed = jsonDecode(text);
            final score =
                (parsed['compatibility_score'] as num?)?.toDouble() ?? 8.8;
            final scoreLevel = parsed['score_level'] ?? 'HIGH';
            final status = parsed['recommendation_status'] ?? 'NÊN MUA NGAY 🔥';
            final reason = parsed['recommendation_reason'] ??
                'Món đồ này phối hợp cực kỳ hài hòa với các trang phục sẵn có trong tủ.';
            final colorHarmony = parsed['color_harmony'] ??
                'Gam màu tương thích tốt với tông trung tính trong tủ đồ.';
            final silhouette = parsed['silhouette_analysis'] ??
                'Phom dáng cân đối, dễ dàng phối nhiều lớp (layering).';

            final compIds = (parsed['compatible_item_ids'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final compItems =
                wardrobeItems.where((w) => compIds.contains(w.id)).toList();

            final rawOutfits = (parsed['suggested_outfits'] as List?) ?? [];
            final suggestedOutfits = <SuggestedOutfitPair>[];

            for (final o in rawOutfits) {
              final oItemIds =
                  (o['item_ids'] as List?)?.map((e) => e.toString()).toList() ??
                      [];
              final outfitWardrobeItems =
                  wardrobeItems.where((w) => oItemIds.contains(w.id)).toList();

              if (outfitWardrobeItems.isNotEmpty) {
                suggestedOutfits.add(SuggestedOutfitPair(
                  title: o['title'] ?? 'Set đồ phong cách',
                  style:
                      product.tags.isNotEmpty ? product.tags.first : 'Casual',
                  wardrobeItems: outfitWardrobeItems,
                  stylingTip:
                      o['styling_tip'] ?? 'Phối layer tôn dáng hoàn hảo.',
                ));
              }
            }

            // Kiểm tra xem có trùng món đồ trong tủ
            final duplicate = wardrobeItems.any((item) =>
                item.category == product.category &&
                item.color.toLowerCase() == product.color.toLowerCase());

            return ShoppingCompatibilityResult(
              product: product,
              compatibilityScore: score,
              scoreLevel: scoreLevel,
              recommendationStatus: status,
              recommendationReason: reason,
              matchingItemsCount: compItems.isNotEmpty ? compItems.length : 5,
              compatibleItems: compItems.isNotEmpty
                  ? compItems
                  : wardrobeItems.take(4).toList(),
              suggestedOutfits: suggestedOutfits.isNotEmpty
                  ? suggestedOutfits
                  : _buildFallbackSuggestedOutfits(product, wardrobeItems),
              colorHarmonyAnalysis: colorHarmony,
              silhouetteAnalysis: silhouette,
              isDuplicate: duplicate,
            );
          }
        }
      } catch (e) {
        debugPrint('[SmartShoppingAiService] Error calling model $model: $e');
      }
    }
    return null;
  }

  static ShoppingCompatibilityResult _buildDeterministicCompatibility(
    ProspectiveProduct product,
    List<WardrobeItemModel> wardrobeItems,
  ) {
    if (wardrobeItems.isEmpty) {
      return ShoppingCompatibilityResult(
        product: product,
        compatibilityScore: 9.0,
        scoreLevel: 'HIGH',
        recommendationStatus: 'MÓN ĐỒ NỀN TẢNG TUYỆT VỜI ✨',
        recommendationReason:
            'Tủ đồ của bạn còn trống, đây sẽ là món đồ khởi đầu xuất sắc để xây dựng phong cách cá nhân.',
        matchingItemsCount: 0,
        compatibleItems: [],
        suggestedOutfits: [],
        colorHarmonyAnalysis:
            'Tông màu ${product.color} là gam màu cơ bản dễ dàng phát triển tủ đồ con nhộng (Capsule Wardrobe).',
        silhouetteAnalysis: 'Kiểu dáng đa năng, phù hợp nhiều hoàn cảnh.',
      );
    }

    // 1. Tìm các món đồ hợp theo bánh xe màu sắc và phân loại
    final compItems = <WardrobeItemModel>[];
    for (final item in wardrobeItems) {
      if (_isCompatible(product, item)) {
        compItems.add(item);
      }
    }

    // Nếu không khớp món nào thì lấy các món khác category
    if (compItems.isEmpty) {
      compItems.addAll(
          wardrobeItems.where((w) => w.category != product.category).take(4));
    }

    // Kiểm tra trùng lặp
    final duplicate = wardrobeItems.any((item) =>
        item.category == product.category &&
        item.color.toLowerCase() == product.color.toLowerCase());

    final ratio = compItems.length / wardrobeItems.length;
    double score = 7.5 + (ratio * 2.3);
    if (score > 9.8) score = 9.8;
    if (duplicate) score -= 1.2;

    String level = 'HIGH';
    String status = 'NÊN MUA NGAY 🔥';
    if (score < 7.0) {
      level = 'LOW';
      status = 'CÂN NHẮC KỸ ⚠️';
    } else if (score < 8.5) {
      level = 'MEDIUM';
      status = 'RẤT ĐÁNG MUA ✨';
    }

    final isFan = product.title.toLowerCase().contains('quạt') ||
        product.title.toLowerCase().contains('fan');

    final reason = isFan
        ? 'Phụ kiện quạt cầm tay tiện ích giúp giải nhiệt tức thì, cực kỳ lý tưởng mang theo cùng các outfit hè khi đi làm, dạo phố hay du lịch.'
        : duplicate
            ? 'Bạn đã có món đồ tương tự trong tủ. Hãy cân nhắc xem có thực sự cần thêm không.'
            : 'Sản phẩm kết hợp hài hòa với ${compItems.length}/${wardrobeItems.length} món đồ hiện có và phù hợp phong cách bạn đang theo đuổi.';

    final colorHarmony = _getColorHarmonyText(product.color, compItems);
    final silhouette = isFan
        ? 'Thiết kế cầm tay nhỏ gọn, hiện đại với quai đeo tiện lợi, tạo điểm nhấn năng động và thực tế cho set đồ ngoài trời.'
        : _getSilhouetteText(product.category);

    final suggested = _buildFallbackSuggestedOutfits(product, compItems);

    return ShoppingCompatibilityResult(
      product: product,
      compatibilityScore: double.parse(score.toStringAsFixed(1)),
      scoreLevel: level,
      recommendationStatus: status,
      recommendationReason: reason,
      matchingItemsCount: compItems.length,
      compatibleItems: compItems,
      suggestedOutfits: suggested,
      colorHarmonyAnalysis: colorHarmony,
      silhouetteAnalysis: silhouette,
      isDuplicate: duplicate,
    );
  }

  static bool _isCompatible(
      ProspectiveProduct product, WardrobeItemModel item) {
    // Không phối 2 món cùng một danh mục (trừ khoác ngoài và phụ kiện)
    if (product.category == item.category &&
        product.category != WardrobeCategory.accessories) {
      return false;
    }

    // Màu trung tính (Trắng, Đen, Xám, Be, Nâu, Xanh Navy) phối được với hầu hết mọi màu
    const neutralColors = {
      'trắng',
      'đen',
      'xám',
      'be',
      'nâu',
      'xanh navy',
      'white',
      'black',
      'grey',
      'beige',
      'navy'
    };
    final pColor = product.color.toLowerCase();
    final iColor = item.color.toLowerCase();

    if (neutralColors.contains(pColor) || neutralColors.contains(iColor)) {
      return true;
    }

    // Cùng tone hoặc tương phản nhẹ
    return pColor == iColor ||
        (pColor.contains('xanh') && iColor.contains('trắng'));
  }

  static String _getColorHarmonyText(
      String color, List<WardrobeItemModel> compItems) {
    final names =
        compItems.take(2).map((e) => '"${e.name}" (${e.color})').join(', ');
    return 'Gam màu $color tạo hiệu ứng thị giác hài hòa khi đi kèm với $names.';
  }

  static String _getSilhouetteText(WardrobeCategory cat) {
    switch (cat) {
      case WardrobeCategory.outerwear:
        return 'Phom áo khoác dáng chuẩn, tạo hiệu ứng xếp lớp (layering) làm tăng chiều sâu cho tổng thể trang phục.';
      case WardrobeCategory.bottoms:
        return 'Dáng quần tôn chân, dễ dàng sơ vin cùng áo sơ mi hoặc buông tự nhiên với áo phông.';
      case WardrobeCategory.tops:
        return 'Dáng áo thoải mái, cổ áo tinh tế giúp tôn phần thân trên và cân đối tỷ lệ cơ thể.';
      case WardrobeCategory.shoes:
        return 'Phom giày gọn gàng, độ nâng đế vừa phải giúp tôn dáng và năng động cả ngày.';
      case WardrobeCategory.dresses:
        return 'Thiết kế liền thân liền mạch, thắt eo nhẹ nhàng tôn đường conc tự nhiên.';
      case WardrobeCategory.accessories:
        return 'Điểm nhấn phụ kiện/tiện ích cầm tay tinh tế giúp kết nối các item đơn sắc thành một set đồ hoàn chỉnh.';
    }
  }

  static List<SuggestedOutfitPair> _buildFallbackSuggestedOutfits(
    ProspectiveProduct product,
    List<WardrobeItemModel> compItems,
  ) {
    final outfits = <SuggestedOutfitPair>[];

    final isFan = product.title.toLowerCase().contains('quạt') ||
        product.title.toLowerCase().contains('fan');

    if (isFan) {
      outfits.add(SuggestedOutfitPair(
        title: 'Set Dạo Phố & Du Lịch Mùa Hè Tiện Lợi',
        style: 'Casual / Outdoor',
        wardrobeItems: compItems.take(2).toList(),
        stylingTip:
            'Phụ kiện cầm tay tiện ích giúp giải nhiệt tức thì khi diện áo thun, quần short hoặc đồ dạo phố cuối tuần.',
      ));
      if (compItems.length > 2) {
        outfits.add(SuggestedOutfitPair(
          title: 'Set Đi Làm / Đi Học Năng Động Hè',
          style: 'Smart Casual',
          wardrobeItems: compItems.skip(2).take(2).toList(),
          stylingTip:
              'Kích thước nhỏ gọn kèm dây đeo, dễ bỏ túi tote hoặc balo, sẵn sàng xua tan cái nóng khi ra ngoài.',
        ));
      }
      return outfits;
    }

    // Set 1: Đi làm / Lịch thiệp
    final formalMatches = compItems
        .where((i) => i.tags.any((t) =>
            t.contains('Casual') ||
            t.contains('công sở') ||
            t.contains('thanh lịch')))
        .toList();
    if (formalMatches.isNotEmpty) {
      outfits.add(SuggestedOutfitPair(
        title: 'Set Công Sở & Hội Họp Lịch Thiệp',
        style: 'Smart Casual',
        wardrobeItems: formalMatches.take(2).toList(),
        stylingTip:
            'Sơ vin chỉn chu và kết hợp giày/túi cùng tông màu để tăng vẻ chuyên nghiệp.',
      ));
    }

    // Set 2: Dạo phố / Cuối tuần
    final casualMatches =
        compItems.where((i) => !formalMatches.contains(i)).toList();
    final listForSet2 = casualMatches.isNotEmpty ? casualMatches : compItems;

    if (listForSet2.isNotEmpty) {
      outfits.add(SuggestedOutfitPair(
        title: 'Set Dạo Phố Cuối Tuần Năng Động',
        style: 'Streetwear / Casual',
        wardrobeItems: listForSet2.take(2).toList(),
        stylingTip:
            'Thêm sneakers trắng và phụ kiện tối giản để tạo cảm giác trẻ trung, tự tin.',
      ));
    }

    return outfits;
  }
}

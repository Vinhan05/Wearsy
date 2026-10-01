import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../models/outfit_model.dart';
import '../providers/outfit_provider.dart';
import 'outfit_detail_screen.dart';
import '../../../core/services/smart_fit_ai_service.dart';
import '../../../core/theme/app_theme.dart';

// Data Models
enum _ChatSender { user, ai }

class _ChatMessage {
  final _ChatSender sender;
  final String text;
  final OutfitModel? outfit;
  _ChatMessage({required this.sender, required this.text, this.outfit});
}

class AiStylistChatScreen extends StatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  State<AiStylistChatScreen> createState() => _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends State<AiStylistChatScreen> {
  final TextEditingController _promptCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text:
              'Xin chào! Tôi là WEARSY AI Stylist ✨\nHôm nay bạn muốn đi đâu? Hãy cho tôi biết dịp hay hoàn cảnh của bạn (ví dụ: "đi đám cưới", "đi làm công sở", "hẹn hò tối nay") — tôi sẽ phân tích toàn bộ tủ đồ và phối ngay bộ trang phục hoàn hảo nhất nhé!',
        ));
      });
    });
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendPrompt([String? presetText]) async {
    final userText = (presetText ?? _promptCtrl.text).trim();
    if (userText.isEmpty || _isLoading) return;
    final wardrobe = Provider.of<WardrobeProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _messages.add(_ChatMessage(sender: _ChatSender.user, text: userText));
      _isLoading = true;
    });
    _promptCtrl.clear();
    _scrollToBottom();

    try {
      final heightCm = (auth.user?.bodyMeasurements?['height'] as num?)?.toDouble() ?? 170.0;
      final weightKg = (auth.user?.bodyMeasurements?['weight'] as num?)?.toDouble() ?? 62.0;
      final userName = auth.user?.fullName ?? 'bạn';

      final outfitResult = await SmartFitAiService.generateSmartFitOutfit(
        wardrobeItems: wardrobe.allItems,
        heightCm: heightCm,
        weightKg: weightKg,
        occasion: userText,
        userName: userName,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text: outfitResult.aiReason.isNotEmpty
              ? outfitResult.aiReason
              : 'Dưới đây là gợi ý phối đồ AI tối ưu nhất từ tủ đồ của bạn:',
          outfit: outfitResult,
        ));
      });

      final outfitProvider = Provider.of<OutfitProvider>(context, listen: false);
      await outfitProvider.addOutfitFromChat(outfitResult);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text: '😔 Có lỗi xảy ra khi kết nối AI Stylist. Vui lòng kiểm tra lại kết nối hoặc thử lại nhé!',
        ));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderBanner(),
            Expanded(child: _buildMessageList()),
            if (_isLoading) _buildLoadingIndicator(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo_icon.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  'W',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wearsy AI Stylist',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Trợ lý phối đồ & Thử đồ thông minh',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 12),
          Text(
            'WEARSY AI đang quan sát tủ đồ & phối trang phục...',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (ctx, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.sender == _ChatSender.user;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bot message bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo_icon.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  'W',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppTheme.darkTextPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                if (msg.outfit != null) ...[
                  const SizedBox(height: 12),
                  _buildOutfitCard(msg.outfit!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(OutfitModel outfit) {
    final wardrobe = Provider.of<WardrobeProvider>(context, listen: false);
    final selectedItems = wardrobe.allItems
        .where((item) => outfit.itemIds.contains(item.id))
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rendered Image Header if available
          if (outfit.coverImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: _buildCoverImage(outfit.coverImageUrl),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Scores
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outfit.name,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            outfit.eleganceScore.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected Items Thumbnails
                Text(
                  'Các món đồ được chọn (${selectedItems.length} món):',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, idx) {
                      final item = selectedItems[idx];
                      return Container(
                        width: 160,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildItemThumbnail(item),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    item.category.displayName,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.darkTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Action button: View Detail
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(
                      'Xem Chi Tiết & Thử Đồ 2D',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutfitDetailScreen(outfit: outfit),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String imageSrc) {
    if (imageSrc.startsWith('data:image/')) {
      final base64Content = imageSrc.split(',').last;
      return Image.memory(
        base64Decode(base64Content),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    } else if (imageSrc.startsWith('http://') || imageSrc.startsWith('https://')) {
      return Image.network(
        imageSrc,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    } else if (File(imageSrc).existsSync()) {
      return Image.file(
        File(imageSrc),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.checkroom_rounded, size: 40, color: Colors.grey),
    );
  }

  Widget _buildItemThumbnail(WardrobeItemModel item) {
    final path = item.imageUrl;
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.contain);
    } else if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    return const Icon(Icons.checkroom, color: Colors.grey, size: 24);
  }

  Widget _buildBottomSection() {
    final suggestions = ['Đi dự đám cưới', 'Hẹn hò cafe cuối tuần', 'Đi làm công sở'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: suggestions.map((s) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _sendPrompt(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.lavenderCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          s,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.lavenderCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.darkTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập dịp đi chơi, đi làm, dự tiệc...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppTheme.darkTextSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                  onPressed: () => _sendPrompt(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

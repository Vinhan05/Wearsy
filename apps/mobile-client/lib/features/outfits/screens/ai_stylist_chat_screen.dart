import 'package:wearsy_mobile/core/theme/app_fonts.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../models/outfit_model.dart';
import '../providers/outfit_provider.dart';
import 'outfit_detail_screen.dart';
import '../../../core/services/smart_fit_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
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

  void _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  void _listenVoicePrompt() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      try {
        _speechAvailable = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (_) {
            if (mounted) setState(() => _isListening = false);
          },
        );
      } catch (_) {
        _speechAvailable = false;
      }
    }

    if (_speechAvailable) {
      if (mounted) setState(() => _isListening = true);
      await _speech.listen(
        localeId: 'vi_VN',
        onResult: (result) {
          if (mounted) {
            setState(() {
              _promptCtrl.text = result.recognizedWords;
              _promptCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _promptCtrl.text.length),
              );
            });
          }
        },
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Không thể khởi động micro hoặc thiết bị không hỗ trợ nhận diện giọng nói.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
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

  Future<void> _sendPrompt(
      {String? presetText, bool forceFinalize = false}) async {
    final userText = (presetText ?? _promptCtrl.text).trim();
    if (userText.isEmpty && !forceFinalize) return;
    if (_isLoading) return;

    final wardrobe = Provider.of<WardrobeProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final displayText =
        forceFinalize && userText.isEmpty ? '✨ Chốt & Phối đồ ngay' : userText;

    setState(() {
      _messages.add(_ChatMessage(sender: _ChatSender.user, text: displayText));
      _isLoading = true;
    });
    _promptCtrl.clear();
    _scrollToBottom();

    try {
      final heightCm =
          (auth.user?.bodyMeasurements?['height'] as num?)?.toDouble() ?? 170.0;
      final weightKg =
          (auth.user?.bodyMeasurements?['weight'] as num?)?.toDouble() ?? 62.0;
      final userName = auth.user?.fullName ?? 'bạn';
      final gender = auth.user?.bodyMeasurements?['gender']?.toString() ?? 'Nữ';

      final history = _messages
          .map((m) => {
                'role': m.sender == _ChatSender.user ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final chatResponse = await SmartFitAiService.chatWithStylist(
        messages: history,
        wardrobeItems: wardrobe.allItems,
        heightCm: heightCm,
        weightKg: weightKg,
        gender: gender,
        userName: userName,
        forceFinalize: forceFinalize,
      );

      if (!mounted) return;

      final action = chatResponse['action']?.toString() ?? 'CONVERSATION';
      if (action == 'FINALIZE_OUTFIT' && chatResponse['outfit'] != null) {
        final outfitResult = chatResponse['outfit'] as OutfitModel;
        setState(() {
          _isLoading = false;
          _messages.add(_ChatMessage(
            sender: _ChatSender.ai,
            text: chatResponse['reply']?.toString() ?? outfitResult.aiReason,
            outfit: outfitResult,
          ));
        });

        final outfitProvider =
            Provider.of<OutfitProvider>(context, listen: false);
        await outfitProvider.addOutfitFromChat(outfitResult);
      } else {
        setState(() {
          _isLoading = false;
          _messages.add(_ChatMessage(
            sender: _ChatSender.ai,
            text: chatResponse['reply']?.toString() ??
                'Tôi có thể giúp bạn phối thêm chi tiết gì không?',
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text:
              '😔 Có lỗi xảy ra khi kết nối AI Stylist. Vui lòng thử lại nhé!',
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
                style: AppFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Trợ lý phối đồ & Thử đồ thông minh',
                style: AppFonts.inter(
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
            style: AppFonts.inter(
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
                style: AppFonts.inter(
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
                    style: AppFonts.inter(
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
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
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
                        style: AppFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            outfit.eleganceScore.toStringAsFixed(1),
                            style: AppFonts.inter(
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
                  style: AppFonts.inter(
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
                                    style: AppFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    item.category.displayName,
                                    maxLines: 1,
                                    style: AppFonts.inter(
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
                      'Xem Chi Tiết Outfit',
                      style: AppFonts.inter(
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
    final suggestions = [
      'Đi hẹn hò lãng mạn',
      'Đi làm công sở',
      'Dự tiệc cưới'
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action button: Chốt & Phối đồ ngay
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome,
                    color: Color(0xFFFDCB6E), size: 18),
                label: Text(
                  '✨ Chốt & Phối đồ ngay',
                  style: AppFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _sendPrompt(forceFinalize: true),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendPrompt(presetText: s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.lavenderCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        s,
                        style: AppFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkTextPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.lavenderCard,
              borderRadius: BorderRadius.circular(24),
              border: _isListening
                  ? Border.all(
                      color: Colors.redAccent.withOpacity(0.6), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: AppFonts.inter(
                      fontSize: 14,
                      color: AppTheme.darkTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? '🎙️ Đang lắng nghe giọng nói...'
                          : 'Nhập dịp đi chơi, đi làm, dự tiệc...',
                      hintStyle: AppFonts.inter(
                        fontSize: 13.5,
                        color: _isListening
                            ? Colors.redAccent
                            : AppTheme.darkTextSecondary,
                        fontWeight:
                            _isListening ? FontWeight.w500 : FontWeight.normal,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.redAccent.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: _isListening
                        ? 'Đang ghi âm (chạm để dừng)'
                        : 'Nhập bằng giọng nói',
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening
                          ? Colors.redAccent
                          : AppTheme.primaryColor,
                    ),
                    onPressed: _listenVoicePrompt,
                  ),
                ),
                IconButton(
                  tooltip: 'Gửi',
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

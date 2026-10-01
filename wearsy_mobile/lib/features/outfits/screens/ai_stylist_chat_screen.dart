import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../models/outfit_model.dart';
import '../providers/outfit_provider.dart';
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

  static const String _geminiApiKey =
      'YOUR_GEMINI_API_KEY';
  static const String _geminiModel = 'gemini-1.5-flash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text:
              'Xin chào! Tôi là WEARSY AI Stylist ✨\nHôm nay bạn muốn đi đâu? Hãy cho tôi biết dịp hay hoàn cảnh của bạn — tôi sẽ gợi ý bộ outfit hoàn hảo từ tủ đồ của bạn nhé!',
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
          duration: const Duration(milliseconds: 350),
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
      final result = await _callGeminiStylist(
        userPrompt: userText,
        wardrobeItems: wardrobe.allItems,
        userName: auth.user?.fullName ?? 'bạn',
        heightCm: (auth.user?.bodyMeasurements?['height'] as num?)?.toDouble() ?? 172.0,
        weightKg: (auth.user?.bodyMeasurements?['weight'] as num?)?.toDouble() ?? 65.0,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text: result.reply,
          outfit: result.outfit,
        ));
      });
      if (result.outfit != null) {
        final outfitProvider = Provider.of<OutfitProvider>(context, listen: false);
        await outfitProvider.addOutfitFromChat(result.outfit!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          sender: _ChatSender.ai,
          text: '😔 Có lỗi xảy ra khi kết nối AI. Vui lòng thử lại nhé!',
        ));
      });
    }
    _scrollToBottom();
  }

  Future<_StylistResult> _callGeminiStylist({
    required String userPrompt,
    required List<WardrobeItemModel> wardrobeItems,
    required String userName,
    required double heightCm,
    required double weightKg,
  }) async {
    final wardrobeJson = wardrobeItems.map((item) => {
          'id': item.id,
          'name': item.name,
          'category': item.category.displayName,
          'color': item.color,
          'tags': item.tags,
        }).toList();

    final systemPrompt = '''
Bạn là WEARSY AI Stylist - Trợ lý thời trang cá nhân cho ứng dụng WEARSY.
Người dùng: $userName

TỦ ĐỒ HIỆN TẠI (${wardrobeItems.length} món):
${jsonEncode(wardrobeJson)}

YÊU CẦU CỦA NGƯỜI DÙNG: "$userPrompt"

PHẢN HỒI (JSON THUẦN TÚY):
{
  "reply": "Lời gợi ý ngắn gọn bằng tiếng Việt",
  "has_outfit": false,
  "outfit": null
}
''';

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': systemPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'responseMimeType': 'application/json',
        },
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final jsonResponse = jsonDecode(response.body);
    final text = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) throw Exception('Không có phản hồi');
    final parsed = jsonDecode(text.trim()) as Map<String, dynamic>;
    final reply = parsed['reply']?.toString() ?? 'Xin lỗi, tôi chưa hiểu rõ yêu cầu.';
    return _StylistResult(reply: reply, outfit: null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Banner matching tủ đồ (3).png
            _buildHeaderBanner(),

            // Chat Message List
            Expanded(child: _buildMessageList()),

            // Suggestion pills + Prompt Input Bar
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
                'Wearsy AI Chat',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Trợ lý phối đồ cá nhân',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
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

    // Bot message bubble matching tủ đồ (3).png
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
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final suggestions = ['Dự tiệc', 'Cafe với bạn', 'Đi làm'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Suggestion Pills matching tủ đồ (3).png
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
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

          // Prompt Input Bar matching tủ đồ (3).png
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.lavenderCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _promptCtrl,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Bạn muốn phối đồ như thế nào ....',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppTheme.darkTextSecondary,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendPrompt(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StylistResult {
  final String reply;
  final OutfitModel? outfit;
  _StylistResult({required this.reply, this.outfit});
}

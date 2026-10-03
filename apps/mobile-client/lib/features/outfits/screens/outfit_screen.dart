import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/outfit_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import 'ai_stylist_chat_screen.dart';
import 'outfit_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class OutfitScreen extends StatelessWidget {
  const OutfitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OutfitBody();
  }
}

class _OutfitBody extends StatelessWidget {
  const _OutfitBody();

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context); // Listen to Theme changes
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildFilterPills(context),
            const SizedBox(height: 12),
            Expanded(child: _buildGrid(context)),
          ],
        ),
      ),
      floatingActionButton: _buildChatFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            'Phối đồ AI',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkTextPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primaryColor,
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Gần đây',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final outfitProvider = Provider.of<OutfitProvider>(context);
    final wardrobeProvider =
        Provider.of<WardrobeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final outfits = outfitProvider.filteredOutfits;

    if (outfits.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.lavenderCard,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  color: AppTheme.primaryLight,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chưa Có Outfit AI Nào',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tài khoản mới chưa lưu bộ phối đồ nào. Hãy trò chuyện với Wearsy AI Stylist để tạo outfit chuẩn phong cách của bạn!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.darkTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 18),
                label: Text(
                  'Tạo Outfit Mới Với AI',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(value: outfitProvider),
                          ChangeNotifierProvider.value(value: wardrobeProvider),
                          ChangeNotifierProvider.value(value: authProvider),
                        ],
                        child: const AiStylistChatScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: outfits.length,
      itemBuilder: (context, index) {
        final outfit = outfits[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: outfitProvider),
                    ChangeNotifierProvider.value(value: wardrobeProvider),
                    ChangeNotifierProvider.value(value: authProvider),
                  ],
                  child: OutfitDetailScreen(outfit: outfit),
                ),
              ),
            );
          },
          child: _OutfitCard(
            title: outfit.name,
            score: outfit.aiScore.toStringAsFixed(1),
            imageUrl: outfit.coverImageUrl,
          ),
        );
      },
    );
  }

  Widget _buildChatFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 8),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(
                    value: Provider.of<OutfitProvider>(context, listen: false),
                  ),
                  ChangeNotifierProvider.value(
                    value:
                        Provider.of<WardrobeProvider>(context, listen: false),
                  ),
                  ChangeNotifierProvider.value(
                    value: Provider.of<AuthProvider>(context, listen: false),
                  ),
                ],
                child: const AiStylistChatScreen(),
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        label: Text(
          'Wearsy AI Chat',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final String title;
  final String score;
  final String imageUrl;

  const _OutfitCard({
    required this.title,
    required this.score,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lavenderCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Top lavender header bar with Title & Score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF383350),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨ ', style: TextStyle(fontSize: 10)),
                        Text(
                          score,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Image
            Expanded(
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.lavenderCard,
                  child: Icon(Icons.checkroom_rounded,
                      color: AppTheme.primaryLight, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

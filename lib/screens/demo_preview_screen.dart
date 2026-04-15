import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DemoPreviewScreen extends StatelessWidget {
  const DemoPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aesthetic Tokens from app.dart
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);

    return Scaffold(
      backgroundColor: pureBlack,
      body: Stack(
        children: [
          // Background Gradient Depth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    creamColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hierarchical Header (Breadcrumbs)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBreadcrumb(context, "Mono", isFirst: true),
                          _buildChevron(),
                          _buildBreadcrumb(context, "Projects"),
                          _buildChevron(),
                          _buildBreadcrumb(context, "Social Privacy", isActive: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Detailed Convenience",
                        style: GoogleFonts.outfit(
                          color: creamColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        "Organize your social thoughts by folder hierarchy.",
                        style: GoogleFonts.inter(
                          color: creamColor.withValues(alpha: 0.4),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Text Stream Feed
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildStreamCard(
                        context,
                        "Initial thoughts on localized encryption. We are moving away from traditional cloud structures to ensure user sovereignty.",
                        "System Architecture",
                        "2m ago",
                        hasBadge: true,
                      ),
                      _buildStreamCard(
                        context,
                        "The concept of 'Text Streaming' allows for a continuous flow of high-quality thoughts without the noise of algorithmic feeds.",
                        "Product Philosophy",
                        "15m ago",
                      ),
                      _buildStreamCard(
                        context,
                        "Hierarchical folders are not just for files. They are for the context of our digital lives.",
                        "User Experience",
                        "1h ago",
                        hasBadge: true,
                      ),
                      const SizedBox(height: 100), // Bottom padding for FAB area demo
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Glassmorphism Bottom Navigation Mock
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: creamColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: creamColor.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavIcon(Icons.auto_awesome_motion_rounded, true, creamColor),
                      _buildNavIcon(Icons.search_rounded, false, creamColor),
                      _buildNavIcon(Icons.folder_copy_rounded, false, creamColor),
                      _buildNavIcon(Icons.person_2_rounded, false, creamColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, String text, {bool isActive = false, bool isFirst = false}) {
    const creamColor = Color(0xFFF7F2E8);
    return Text(
      text,
      style: GoogleFonts.inter(
        color: isActive ? creamColor : creamColor.withValues(alpha: 0.3),
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }

  Widget _buildChevron() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(Icons.chevron_right_rounded, color: const Color(0xFFF7F2E8).withValues(alpha: 0.2), size: 14),
    );
  }

  Widget _buildStreamCard(BuildContext context, String content, String category, String time, {bool hasBadge = false}) {
    const creamColor = Color(0xFFF7F2E8);
    const surfaceBlack = Color(0xFF121212);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: creamColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: creamColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: creamColor.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              if (hasBadge)
                Icon(Icons.verified_user_rounded, color: creamColor.withValues(alpha: 0.6), size: 14),
              const SizedBox(width: 8),
              Text(
                time,
                style: GoogleFonts.inter(
                  color: creamColor.withValues(alpha: 0.2),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              color: creamColor.withValues(alpha: 0.85),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isActive, Color color) {
    return Icon(
      icon,
      color: isActive ? color : color.withValues(alpha: 0.3),
      size: 26,
    );
  }
}

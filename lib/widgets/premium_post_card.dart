import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class PremiumPostCard extends StatelessWidget {
  final Post post;
  final String folderName;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PremiumPostCard({
    super.key,
    required this.post,
    required this.folderName,
    this.isReply = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);

    return Container(
      margin: EdgeInsets.only(bottom: isReply ? 8 : 16, left: isReply ? 32 : 0),
      padding: EdgeInsets.all(isReply ? 20 : 24),
      decoration: BoxDecoration(
        color: creamColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: creamColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (post.authorName != null) {
                      final prefs = await SharedPreferences.getInstance();
                      final myName = prefs.getString('user_display_name') ?? 'Me';
                      
                      if (!context.mounted) return;
                      
                      if (post.authorName == myName) {
                        // Navigate to My Profile tab (tab index 3)
                        context.go('/?tab=3');
                      } else {
                        context.push('/profile/view/${Uri.encodeComponent(post.authorName!)}');
                      }
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isReply ? 10 : 12,
                        backgroundColor: creamColor.withValues(alpha: 0.1),
                        backgroundImage: post.authorAvatarUrl != null ? NetworkImage(post.authorAvatarUrl!) : null,
                        child: post.authorAvatarUrl == null 
                          ? Text((post.authorName ?? 'M')[0], style: TextStyle(color: creamColor, fontSize: isReply ? 8 : 10))
                          : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName ?? 'Administrator',
                              style: GoogleFonts.inter(
                                color: creamColor.withValues(alpha: 0.6), 
                                fontSize: isReply ? 12 : 13, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isReply)
                              Text(
                                folderName.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: creamColor.withValues(alpha: 0.2),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d').format(post.createdAt),
                    style: GoogleFonts.inter(
                      color: creamColor.withValues(alpha: 0.2),
                      fontSize: 10,
                    ),
                  ),
                  if (onEdit != null || onDelete != null) ...[
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, color: creamColor.withValues(alpha: 0.2), size: 20),
                      color: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: creamColor.withValues(alpha: 0.05))),
                      offset: const Offset(0, 40),
                      onSelected: (value) {
                        HapticFeedback.selectionClick();
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: creamColor.withValues(alpha: 0.6)),
                                const SizedBox(width: 12),
                                Text('Edit', style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.6), fontSize: 13)),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent.withValues(alpha: 0.5)),
                                const SizedBox(width: 12),
                                Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent.withValues(alpha: 0.5), fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: GoogleFonts.inter(
              color: creamColor.withValues(alpha: 0.9),
              fontSize: isReply ? 14 : 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (!isReply) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                _buildAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "Reply",
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (onReply != null) {
                      onReply!();
                    } else {
                      context.push('/compose?parentId=${post.id}&folderId=${post.folderId}');
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAction({required IconData icon, required String label, required VoidCallback onTap}) {
    const creamColor = Color(0xFFF7F2E8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: creamColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: creamColor.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: creamColor.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

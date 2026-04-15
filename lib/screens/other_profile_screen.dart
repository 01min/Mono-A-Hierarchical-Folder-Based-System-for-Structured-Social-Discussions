import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/post.dart';
import '../models/folder.dart';
import '../widgets/premium_post_card.dart';

class OtherProfileScreen extends StatefulWidget {
  final String authorName;
  final String? initialBio;
  final String? initialAvatarUrl;

  const OtherProfileScreen({
    super.key, 
    required this.authorName,
    this.initialBio,
    this.initialAvatarUrl,
  });

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  List<Post> _posts = [];
  List<Folder> _folders = [];
  String? _bio;
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isNotifEnabled = false;

  @override
  void initState() {
    super.initState();
    _bio = widget.initialBio;
    _avatarUrl = widget.initialAvatarUrl;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final db = context.read<DatabaseService>();
      
      // 1. Fetch all posts by this author locally using optimized query
      final allPosts = db.getPostsByAuthor(widget.authorName);
      final folders = db.getAllFolders();
      
      // 2. Extract Bio and Avatar from the latest post
      if (allPosts.isNotEmpty) {
        final latest = allPosts.first;
        _bio = latest.authorBio ?? widget.initialBio;
        _avatarUrl = latest.authorAvatarUrl ?? widget.initialAvatarUrl;
      }

      if (mounted) {
        setState(() {
          // Only show posts that belong to a shared folder (privacy: General is private)
          _posts = allPosts.where((p) => p.parentPostId == null && p.folderId != null).toList();
          _folders = folders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotifEnabled = prefs.getBool('notif_author_${widget.authorName}') ?? false;
    });
  }

  Future<void> _toggleNotif() async {
    final prefs = await SharedPreferences.getInstance();
    final newState = !_isNotifEnabled;
    await prefs.setBool('notif_author_${widget.authorName}', newState);
    HapticFeedback.mediumImpact();
    setState(() {
      _isNotifEnabled = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);

    return Scaffold(
      backgroundColor: pureBlack,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: creamColor,
          backgroundColor: const Color(0xFF121212),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Premium Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBreadcrumb(context, "Mono", onTap: () => context.go('/')),
                          _buildChevron(),
                          _buildBreadcrumb(context, "Profile", isActive: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.authorName,
                                        style: GoogleFonts.outfit(
                                          color: creamColor,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _toggleNotif,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _isNotifEnabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, 
                                          color: _isNotifEnabled ? Colors.yellowAccent.withValues(alpha: 0.8) : creamColor.withValues(alpha: 0.2), 
                                          size: 20
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _bio ?? "Local administrator & curator",
                                    style: GoogleFonts.inter(
                                      color: creamColor.withValues(alpha: 0.4),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: creamColor.withValues(alpha: 0.05),
                            backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                            child: _avatarUrl == null 
                              ? Text(widget.authorName[0].toUpperCase(), style: GoogleFonts.outfit(color: creamColor, fontSize: 24, fontWeight: FontWeight.w600))
                              : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    "SHARED POSTS",
                    style: GoogleFonts.inter(
                      color: creamColor.withValues(alpha: 0.2),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              // 3. Post List
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: creamColor)),
                )
              else if (_posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No message visible yet.",
                      style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.2)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _posts[index];
                        final folder = _folders.firstWhere(
                          (f) => f.id == post.folderId, 
                          orElse: () => Folder(id: '', name: 'SHARED', colorValue: 0xFF9E9E9E),
                        );
                        return PremiumPostCard(
                          post: post, 
                          folderName: folder.name,
                        );
                      },
                      childCount: _posts.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, String text, {bool isActive = false, VoidCallback? onTap}) {
    const creamColor = Color(0xFFF7F2E8);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: isActive ? creamColor : creamColor.withValues(alpha: 0.3),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildChevron() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(Icons.chevron_right_rounded, color: const Color(0xFFF7F2E8).withValues(alpha: 0.2), size: 14),
    );
  }
}

import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/post.dart';
import '../models/folder.dart';
import '../widgets/premium_post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  List<Post> _posts = [];
  List<Post> _replies = [];
  List<Folder> _folders = [];
  String _displayName = 'Me';
  String _bio = 'Local administrator & curator';
  String? _avatarUrl;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<DatabaseService>();
    final prefs = await SharedPreferences.getInstance();
    
    final allMyPosts = db.getPosts().where((p) => !p.isRemote).toList();
    final folders = db.getAllFolders();
    
    if (mounted) {
      setState(() {
        _posts = allMyPosts.where((p) => p.parentPostId == null).toList();
        _replies = allMyPosts.where((p) => p.parentPostId != null).toList();
        _folders = folders;
        _displayName = prefs.getString('user_display_name') ?? 'Me';
        _bio = prefs.getString('user_bio') ?? 'Local administrator & curator';
        _avatarUrl = prefs.getString('user_avatar_url');
      });
    }
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
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildBreadcrumb("Mono"),
                              _buildChevron(),
                              _buildBreadcrumb("Me", isActive: true),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayName,
                                      style: GoogleFonts.outfit(
                                        color: creamColor,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _bio,
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
                                  ? Text(_displayName[0].toUpperCase(), style: GoogleFonts.outfit(color: creamColor, fontSize: 24, fontWeight: FontWeight.w600))
                                  : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: -8, // Move slightly outside padding area
                        right: -8, // Move slightly outside padding area
                        child: IconButton(
                          onPressed: () async {
                            await context.push('/settings');
                            _loadData();
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: creamColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.settings_rounded, color: creamColor.withValues(alpha: 0.4), size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Custom Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  child: Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      color: pureBlack,
                      border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: creamColor,
                      labelColor: creamColor,
                      unselectedLabelColor: creamColor.withValues(alpha: 0.2),
                      indicatorWeight: 1,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Replies'),
                      ],
                      onTap: (index) => setState(() {}),
                    ),
                  ),
                ),
              ),

              // 3. List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                sliver: _tabController.index == 0 
                  ? _buildPostList(_posts) 
                  : _buildPostList(_replies),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Text(
              'Still quiet here.',
              style: GoogleFonts.inter(color: const Color(0xFFF7F2E8).withValues(alpha: 0.2), fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];
          final folder = _folders.firstWhere(
            (f) => f.id == post.folderId, 
            orElse: () => Folder(id: '', name: 'General', colorValue: 0xFF9E9E9E),
          );

          return PremiumPostCard(
            post: post, 
            folderName: folder.name,
            onEdit: () async {
              HapticFeedback.lightImpact();
              await context.push('/compose?postId=${post.id}');
              _loadData();
            },
            onDelete: () async {
              final db = context.read<DatabaseService>();
              await db.deletePost(post.id);
              _loadData();
            },
          );
        },
        childCount: posts.length,
      ),
    );
  }

  Widget _buildBreadcrumb(String text, {bool isActive = false}) {
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

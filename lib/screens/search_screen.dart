import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/database_service.dart';
import '../models/post.dart';
import '../models/folder.dart';
import '../widgets/premium_post_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Post> _searchResults = [];
  List<Folder> _folderResults = [];
  List<Folder> _folders = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final db = context.read<DatabaseService>();
    setState(() {
      _folders = db.getFolders();
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _folderResults = [];
        _isSearching = false;
      });
      return;
    }

    final db = context.read<DatabaseService>();
    final results = db.searchPosts(query);
    final folderResults = db.searchFolders(query);
    setState(() {
      _searchResults = results;
      _folderResults = folderResults;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);
    const surfaceBlack = Color(0xFF121212);

    return Scaffold(
      backgroundColor: pureBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Premium Header (Breadcrumbs & Search Input)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildBreadcrumb(context, "Mono"),
                      _buildChevron(),
                      _buildBreadcrumb(context, "Explore", isActive: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: surfaceBlack,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: creamColor.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: creamColor.withValues(alpha: 0.2), size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: false,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.inter(color: creamColor, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Search posts, tags, spaces...',
                              hintStyle: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.2)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Icon(Icons.close_rounded, color: creamColor.withValues(alpha: 0.2), size: 20),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Results or Folders with Pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadInitialData();
                  if (_isSearching) _onSearchChanged(_searchController.text);
                },
                color: creamColor,
                backgroundColor: const Color(0xFF121212),
                child: _isSearching
                  ? _buildSearchResults(context)
                  : _buildInitialView(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),
        Text(
          "Quick Spaces",
          style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.6), fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._folders.map((folder) => ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/folder/${folder.id}?name=${Uri.encodeComponent(folder.name)}');
          },
          leading: Text(folder.icon, style: const TextStyle(fontSize: 20)),
          title: Text(folder.name, style: GoogleFonts.inter(color: creamColor, fontSize: 15)),
          trailing: Icon(Icons.chevron_right_rounded, color: creamColor.withValues(alpha: 0.1)),
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    
    if (_searchResults.isEmpty && _folderResults.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          const SizedBox(height: 100),
          Center(child: Text("No results found", style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.2)))),
        ],
      );
    }
    
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_folderResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Spaces",
              style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.4), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _folderResults.length,
              itemBuilder: (context, index) {
                final folder = _folderResults[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/folder/${folder.id}?name=${Uri.encodeComponent(folder.name)}');
                    },
                    backgroundColor: creamColor.withValues(alpha: 0.05),
                    side: BorderSide(color: creamColor.withValues(alpha: 0.05)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(folder.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(folder.name, style: GoogleFonts.inter(color: creamColor, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        if (_searchResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Posts",
              style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.4), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          ..._searchResults.map((post) {
            final folder = _folders.firstWhere((f) => f.id == post.folderId, orElse: () => Folder(id: '', name: 'Unknown', colorValue: 0xFF9E9E9E));
            return PremiumPostCard(
              post: post, 
              folderName: folder.name,
              onEdit: () async {
                HapticFeedback.lightImpact();
                await context.push('/compose?postId=${post.id}');
                if (mounted) _onSearchChanged(_searchController.text);
              },
              onReply: () async {
                HapticFeedback.lightImpact();
                await context.push('/compose?parentId=${post.id}&folderId=${post.folderId}');
                if (mounted) _onSearchChanged(_searchController.text);
              },
              onDelete: () async {
                final db = context.read<DatabaseService>();
                await db.deletePost(post.id);
                if (mounted) _onSearchChanged(_searchController.text);
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _buildBreadcrumb(BuildContext context, String text, {bool isActive = false}) {
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

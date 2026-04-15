import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/folder.dart';
import '../models/post.dart';
import '../widgets/premium_post_card.dart';

class FolderView extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  List<Post> _posts = [];
  List<Folder> _subFolders = [];
  List<Folder> _folders = [];
  Folder? _folder;
  bool _isNotifEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;
    final db = context.read<DatabaseService>();
    final posts = db.getPosts(folderId: widget.folderId);
    final subFolders = db.getFolders(parentId: widget.folderId);
    final folder = db.getFolder(widget.folderId);
    
    _loadNotifPrefs();

    setState(() {
      _posts = posts;
      _subFolders = subFolders;
      _folders = db.getAllFolders();
      _folder = folder;
    });
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotifEnabled = prefs.getBool('notif_space_${widget.folderId}') ?? false;
    });
  }

  Future<void> _toggleNotif() async {
    final prefs = await SharedPreferences.getInstance();
    final newState = !_isNotifEnabled;
    await prefs.setBool('notif_space_${widget.folderId}', newState);
    HapticFeedback.mediumImpact();
    setState(() {
      _isNotifEnabled = newState;
    });
  }

  void _showAddSubFolderDialog() {
    final controller = TextEditingController();
    final cream = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: Text('New Space in ${widget.folderName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Sub-space name...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: Text('Cancel', style: TextStyle(color: cream.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final db = innerContext.read<DatabaseService>();
                final subFolder = Folder(
                  id: const Uuid().v4(),
                  parentId: widget.folderId,
                  name: name,
                  icon: '📁',
                  colorValue: _folder?.colorValue ?? cream.value,
                );
                final navigator = Navigator.of(innerContext);
                await db.saveFolder(subFolder);
                if (mounted) {
                  navigator.pop();
                  _loadData();
                }
              } else {
                HapticFeedback.heavyImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cream,
              foregroundColor: Colors.black,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    final cream = Theme.of(context).colorScheme.primary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: cream.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8), 
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<DatabaseService>();
      await db.deletePost(post.id);
      if (mounted) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);

    // Build hierarchy for breadcrumbs
    List<Folder> hierarchy = [];
    String? currentId = widget.folderId;
    while (currentId != null) {
      final f = _folders.firstWhere((folder) => folder.id == currentId, orElse: () => Folder(id: '', name: ''));
      if (f.id.isNotEmpty) {
        hierarchy.insert(0, f);
        currentId = f.parentId;
      } else {
        currentId = null;
      }
    }

    return Scaffold(
      backgroundColor: pureBlack,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => context.push('/compose?folderId=${widget.folderId}'),
          backgroundColor: creamColor,
          child: const Icon(Icons.add_rounded, color: pureBlack),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: creamColor,
          backgroundColor: const Color(0xFF121212),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Premium Header (Breadcrumbs & Large Title)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.hardEdge,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildBreadcrumb(context, "Mono", onTap: () => context.go('/?tab=0')),
                                  _buildChevron(),
                                  _buildBreadcrumb(context, "Spaces", onTap: () => context.go('/?tab=2')),
                                  ...hierarchy.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final f = entry.value;
                                    final isLast = index == hierarchy.length - 1;
                                    
                                    return Row(
                                      children: [
                                        _buildChevron(),
                                        _buildBreadcrumb(
                                          context, 
                                          f.name, 
                                          isActive: isLast,
                                          onTap: isLast ? null : () => context.push('/folder/${f.id}?name=${Uri.encodeComponent(f.name)}'),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleNotif,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isNotifEnabled ? creamColor.withValues(alpha: 0.1) : creamColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isNotifEnabled ? Icons.notifications_active_rounded : Icons.notifications_outlined, 
                                color: _isNotifEnabled ? Colors.yellowAccent.withValues(alpha: 0.8) : creamColor.withValues(alpha: 0.4), 
                                size: 20
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _showCreateSubSpaceDialog,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: creamColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_rounded, color: creamColor, size: 20),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: creamColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.more_vert_rounded, color: creamColor, size: 20),
                            ),
                            color: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteSpaceConfirmation();
                              } else if (value == 'leave') {
                                _leaveCommunity();
                              }
                            },
                            itemBuilder: (context) => [
                              if (_folder?.isShared == true)
                                PopupMenuItem(
                                  value: 'leave',
                                  child: Row(
                                    children: [
                                      Icon(Icons.exit_to_app_rounded, size: 18, color: creamColor.withValues(alpha: 0.8)),
                                      const SizedBox(width: 12),
                                      const Text('Leave Community', style: TextStyle(color: creamColor)),
                                    ],
                                  ),
                                )
                              else
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withValues(alpha: 0.8)),
                                      const SizedBox(width: 12),
                                      const Text('Delete Space', style: TextStyle(color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.folderName,
                        style: GoogleFonts.outfit(
                          color: creamColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_posts.length} social thoughts in this space.',
                        style: GoogleFonts.inter(
                          color: creamColor.withValues(alpha: 0.4),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Sub-spaces
              if (_folders.any((f) => f.parentId == widget.folderId))
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Text(
                          'SUB-SPACES', 
                          style: GoogleFonts.inter(
                            color: creamColor.withValues(alpha: 0.2), 
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: _folders.where((f) => f.parentId == widget.folderId).length,
                          itemBuilder: (context, index) {
                            final subFolder = _folders.where((f) => f.parentId == widget.folderId).toList()[index];
                            return _PremiumSubSpaceCard(folder: subFolder);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

              // 3. Post Stream (Wide Premium Cards)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final topLevelPosts = _posts.where((p) => p.parentPostId == null).toList();
                      if (index >= topLevelPosts.length) return null;
                      
                      final post = topLevelPosts[index];
                      final replies = _posts.where((p) => p.parentPostId == post.id).toList();

                      return Column(
                        children: [
                          PremiumPostCard(
                            post: post, 
                            folderName: widget.folderName,
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
                          ),
                          if (replies.isNotEmpty)
                            ...replies.map((reply) => PremiumPostCard(
                              post: reply,
                              folderName: widget.folderName,
                              isReply: true,
                              onEdit: () async {
                                HapticFeedback.lightImpact();
                                await context.push('/compose?postId=${reply.id}');
                                _loadData();
                              },
                              onDelete: () async {
                                final db = context.read<DatabaseService>();
                                await db.deletePost(reply.id);
                                _loadData();
                              },
                            )),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
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

  Future<void> _showCreateSubSpaceDialog() async {
    const creamColor = Color(0xFFF7F2E8);
    final nameController = TextEditingController();
    String selectedEmoji = "📁";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: creamColor.withValues(alpha: 0.05))),
          title: Text("New Sub-space", style: GoogleFonts.outfit(color: creamColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final emojis = ["📁", "💡", "📝", "🚀", "🎨", "🍵", "🌱", "🧘"];
                      final nextIndex = (emojis.indexOf(selectedEmoji) + 1) % emojis.length;
                      setDialogState(() => selectedEmoji = emojis[nextIndex]);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: creamColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      autofocus: true,
                      style: GoogleFonts.inter(color: creamColor),
                      decoration: InputDecoration(
                        hintText: "Sub-space Name",
                        hintStyle: TextStyle(color: creamColor.withValues(alpha: 0.2)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: creamColor.withValues(alpha: 0.4))),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final db = context.read<DatabaseService>();
                  final newFolder = Folder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    parentId: widget.folderId,
                    icon: selectedEmoji,
                    colorValue: 0xFFF7F2E8,
                  );
                  await db.saveFolder(newFolder);
                  _loadData();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Create", style: TextStyle(color: creamColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteSpaceConfirmation() async {
    final cream = Theme.of(context).colorScheme.primary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Space?'),
        content: const Text('This will delete the space, all sub-spaces, and all posts within them. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: cream.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<DatabaseService>();
      await db.deleteFolder(widget.folderId);
      if (mounted) {
        context.go('/?tab=0'); // Go back to Home Feed
      }
    }
  }

  Future<void> _leaveCommunity() async {
    final cream = Theme.of(context).colorScheme.primary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Community?'),
        content: const Text('This will remove the community from your list. You will need an invite link to rejoin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: cream.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cream, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<DatabaseService>();
      await db.deleteFolder(widget.folderId); // Locally delete
      if (mounted) {
        context.go('/?tab=0');
      }
    }
  }
}

class _PremiumSubSpaceCard extends StatelessWidget {
  final Folder folder;
  const _PremiumSubSpaceCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const surfaceBlack = Color(0xFF121212);

    return GestureDetector(
      onTap: () => context.push('/folder/${folder.id}?name=${Uri.encodeComponent(folder.name)}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: creamColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folder.icon, style: const TextStyle(fontSize: 24)),
            const Spacer(),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: creamColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


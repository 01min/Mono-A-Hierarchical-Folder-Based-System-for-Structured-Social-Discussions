import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/cloud_service.dart';
import '../models/folder.dart';
import '../models/post.dart';
import '../widgets/premium_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Folder> _folders = [];
  List<Post> _recentPosts = [];
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initCloudSync();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final db = context.read<DatabaseService>();
    final folders = db.getAllFolders();
    final posts = db.getPosts(folderId: _selectedFolderId);

    setState(() {
      _folders = folders;
      _recentPosts = posts;
    });
  }

  void _initCloudSync() {
    final db = context.read<DatabaseService>();
    final folders = db.getAllFolders();
    final cloud = context.read<CloudService>();
    final syncFolders = folders.where((f) => f.isShared && f.encryptionKey != null).toList();
    
    if (syncFolders.isNotEmpty) {
      cloud.startRealtimeSync(syncFolders, db);
      cloud.startFolderSync(syncFolders, db, _loadData); 
    }
  }

  void _showAddFolderDialog() {
    final controller = TextEditingController();
    final cream = Theme.of(context).colorScheme.primary;
    Folder? parentFolder;
    
    showDialog(
      context: context,
      builder: (innerContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Space'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Creative Ideas, Daily Rants...',
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Folder>(
                decoration: InputDecoration(
                  labelText: 'Parent Folder (Optional)',
                  labelStyle: TextStyle(color: cream.withValues(alpha: 0.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                items: [
                  const DropdownMenuItem<Folder>(
                    value: null,
                    child: Text('No Parent (Root)'),
                  ),
                  ..._folders.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text('${f.icon} ${f.name}'),
                  )),
                ],
                onChanged: (val) => setDialogState(() => parentFolder = val),
              ),
            ],
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
                  final folder = Folder(
                    id: const Uuid().v4(),
                    parentId: parentFolder?.id,
                    name: name,
                    colorValue: parentFolder?.colorValue ?? 0xFF9E9E9E,
                    isShared: parentFolder?.isShared ?? false,
                    encryptionKey: parentFolder?.encryptionKey,
                  );
                  await db.saveFolder(folder);
                  
                  // Sync to cloud if shared
                  if (folder.isShared) {
                    final cloud = innerContext.read<CloudService>();
                    await cloud.syncFolderMetadata(folder);
                  }

                  if (mounted) {
                    Navigator.pop(innerContext);
                    _loadData();
                  }
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
      ),
    );
  }

  void _showSpaceSettings(Folder folder) {
    final nameController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder.isShared ? 'Community Settings' : 'Space Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              readOnly: folder.parentId == null,
              decoration: InputDecoration(
                labelText: 'Name',
                helperText: folder.parentId == null ? 'Root folder names are fixed.' : null,
                helperStyle: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: folder.parentId == null ? null : () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                folder.name = newName;
                final db = context.read<DatabaseService>();
                await db.saveFolder(folder);
                
                // Sync to cloud if shared
                if (folder.isShared) {
                  final cloud = context.read<CloudService>();
                  await cloud.syncFolderMetadata(folder);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: Text('Save', style: TextStyle(color: folder.parentId == null ? Colors.white24 : null)),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              folder.isShared ? Icons.exit_to_app_rounded : Icons.delete_outline, 
              color: folder.isShared ? const Color(0xFFF7F2E8).withValues(alpha: 0.6) : Colors.redAccent
            ),
            title: Text(folder.isShared ? 'Leave Community' : 'Delete Folder', 
              style: TextStyle(
                color: folder.isShared ? const Color(0xFFF7F2E8) : Colors.redAccent, 
                fontWeight: FontWeight.bold
              )
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(folder.isShared ? 'Leave Community?' : 'Delete Space?'),
                  content: Text('All local messages in "${folder.name}" will be deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                final db = context.read<DatabaseService>();
                await db.deleteFolder(folder.id);
                if (mounted) {
                  Navigator.pop(context); 
                  _loadData();
                }
              }
            },
          ),
        ],
      ),
    );
  }


  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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

  void _showFolderOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                  title: Text('Create Local Space', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddFolderDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.group_add, color: Theme.of(context).colorScheme.primary),
                  title: Text('Join E2E Community', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showJoinCommunityDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinCommunityDialog() {
    final linkController = TextEditingController();
    final nameController = TextEditingController();
    final cream = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Join Community'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: linkController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Paste mono://join? link here...'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Community Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = linkController.text.trim();
              final name = nameController.text.trim();
              if (link.startsWith('mono://join') && name.isNotEmpty) {
                final uri = Uri.parse(link);
                final groupId = uri.queryParameters['groupId'];
                final key = uri.queryParameters['key'];
                if (groupId != null && key != null) {
                  final db = innerContext.read<DatabaseService>();
                  await db.saveFolder(Folder(
                    id: groupId,
                    name: name,
                    colorValue: 0xFF2962FF,
                    isShared: true,
                    encryptionKey: key,
                  ));
                  if (mounted) {
                    Navigator.pop(innerContext);
                    _loadData();
                  }
                  return;
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);

    return Scaffold(
      backgroundColor: pureBlack,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => context.push('/compose${_selectedFolderId != null ? "?folderId=$_selectedFolderId" : "" }'),
          backgroundColor: creamColor,
          child: const Icon(Icons.add_rounded, color: pureBlack),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.hardEdge,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildBreadcrumb(context, "Mono", isFirst: true, onTap: () {
                            setState(() => _selectedFolderId = null);
                            _loadData();
                          }),
                          _buildChevron(),
                          _buildBreadcrumb(context, _selectedFolderId == null ? "General" : "Explore"),
                          if (_selectedFolderId != null) ...[
                            ..._getFolderPath(_selectedFolderId).asMap().entries.map((entry) {
                              final f = entry.value;
                              final isLast = entry.key == _getFolderPath(_selectedFolderId).length - 1;
                              return Row(
                                children: [
                                  _buildChevron(),
                                  _buildBreadcrumb(
                                    context, 
                                    f.name, 
                                    isActive: isLast,
                                    onTap: isLast ? null : () {
                                      setState(() => _selectedFolderId = f.id);
                                      _loadData();
                                    },
                                  ),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFolderId == null ? "Latest Feed" : _folders.firstWhere((f) => f.id == _selectedFolderId).name,
                      style: GoogleFonts.outfit(
                        color: creamColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Organize your social thoughts by folder hierarchy.",
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

            // 2. Horizontal Folder Picker (Mini)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _folders.where((f) => f.parentId == null).length + 2,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final isAdd = index == _folders.where((f) => f.parentId == null).length + 1;
                        final rootFolders = _folders.where((f) => f.parentId == null).toList();
                        
                        if (isAdd) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: _showCreateSpaceDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: creamColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: creamColor.withValues(alpha: 0.05)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add_rounded, color: creamColor, size: 16),
                                ),
                              ),
                            ),
                          );
                        }

                        final folder = isAll ? null : rootFolders[index - 1];
                        // check if this root folder is part of current selection's parentage
                        bool isSelected;
                        if (isAll) {
                          isSelected = _selectedFolderId == null;
                        } else {
                          final path = _getFolderPath(_selectedFolderId);
                          isSelected = path.any((f) => f.id == folder!.id);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedFolderId = isAll ? null : folder!.id);
                              _loadData();
                            },
                            onLongPress: isAll ? null : () {
                              HapticFeedback.heavyImpact();
                              context.push('/folder/${folder!.id}?name=${Uri.encodeComponent(folder.name)}');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? creamColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? creamColor.withValues(alpha: 0.1) : Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  isAll ? 'All' : folder!.name,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? creamColor : creamColor.withValues(alpha: 0.3),
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Sub-folder Row (Animate in if selected folder has children OR is a sub-folder itself)
                  if (_selectedFolderId != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Show children of selected folder
                          ..._folders.where((f) => f.parentId == _selectedFolderId).map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFolderId = f.id),
                              onLongPress: () {
                                HapticFeedback.heavyImpact();
                                _showSpaceSettings(f);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: creamColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    f.name,
                                    style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ),

            // 3. Post Stream (Wide Premium Cards)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    List<Post> topLevelPosts;
                    if (_selectedFolderId == null) {
                      topLevelPosts = _recentPosts.where((p) => p.parentPostId == null).toList();
                    } else {
                      final targetIds = _getDescendantIds(_selectedFolderId!);
                      topLevelPosts = _recentPosts.where((p) => targetIds.contains(p.folderId) && p.parentPostId == null).toList();
                    }
                    
                    if (index >= topLevelPosts.length) return null;
                    
                    final post = topLevelPosts[index];
                    final folder = _folders.firstWhere(
                      (f) => f.id == post.folderId, 
                      orElse: () => Folder(id: '', name: 'General', colorValue: 0xFF9E9E9E),
                    );

                    final replies = _recentPosts.where((p) => p.parentPostId == post.id).toList();

                    return Column(
                      children: [
                        PremiumPostCard(
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
                        ),
                          ...replies.map((reply) => PremiumPostCard(
                            post: reply,
                            folderName: folder.name,
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

  Widget _buildBreadcrumb(BuildContext context, String text, {bool isActive = false, bool isFirst = false, VoidCallback? onTap}) {
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

  Future<void> _showCreateSpaceDialog() async {
    const creamColor = Color(0xFFF7F2E8);
    final nameController = TextEditingController();
    String selectedEmoji = "📁";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: creamColor.withValues(alpha: 0.05))),
          title: Text("New Space", style: GoogleFonts.outfit(color: creamColor, fontWeight: FontWeight.bold)),
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
                        hintText: "Space Name",
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final db = context.read<DatabaseService>();
                  final newFolder = Folder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    icon: selectedEmoji,
                    colorValue: 0xFFF7F2E8,
                  );
                  await db.saveFolder(newFolder);
                  _loadData();
                  if (mounted) Navigator.pop(context);
                } else {
                  HapticFeedback.heavyImpact();
                }
              },
              child: const Text("Create", style: TextStyle(color: creamColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  List<Folder> _getFolderPath(String? folderId) {
    if (folderId == null) return [];
    List<Folder> path = [];
    String? currentId = folderId;
    while (currentId != null) {
      final f = _folders.firstWhere((f) => f.id == currentId, orElse: () => Folder(id: '', name: ''));
      if (f.id.isNotEmpty) {
        path.insert(0, f);
        currentId = f.parentId;
      } else {
        currentId = null;
      }
    }
    return path;
  }

  Set<String> _getDescendantIds(String folderId) {
    Set<String> ids = {folderId};
    List<String> toProcess = [folderId];
    while (toProcess.isNotEmpty) {
      final parentId = toProcess.removeAt(0);
      final children = _folders.where((f) => f.parentId == parentId).map((f) => f.id);
      ids.addAll(children);
      toProcess.addAll(children);
    }
    return ids;
  }
}


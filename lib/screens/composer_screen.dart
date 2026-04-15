import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/cloud_service.dart';
import '../services/encryption_service.dart';
import '../models/post.dart';
import '../models/folder.dart';

class ComposerScreen extends StatefulWidget {
  final String? initialFolderId;
  final String? postId;
  final String? parentId;

  const ComposerScreen({super.key, this.initialFolderId, this.postId, this.parentId});

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen> {
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  List<Folder> _allFolders = [];
  Folder? _selectedFolder;
  Post? _editingPost;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  List<Folder> _allFoldersRaw = [];

  Future<void> _initData() async {
    final db = context.read<DatabaseService>();
    _allFoldersRaw = db.getAllFolders();
    
    if (widget.postId != null) {
      _editingPost = db.getPost(widget.postId!);
      if (_editingPost != null) {
        _contentController.text = _editingPost!.content;
        _tagsController.text = _editingPost!.tags.join(' ');
        if (_editingPost!.folderId != null) {
          _selectedFolder = db.getFolder(_editingPost!.folderId!);
        }
      }
    } else {
      if (widget.initialFolderId != null) {
        _selectedFolder = db.getFolder(widget.initialFolderId!);
      }
    }
    if (mounted) setState(() {});
  }

  void _showFolderSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Text('SELECT SPACE', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildFolderHierarchy(null, 0),
                    const Divider(),
                    ListTile(
                      leading: const Text('🚫', style: TextStyle(fontSize: 20)),
                      title: Text('Uncategorized', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      subtitle: Text('Local private feed', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
                      onTap: () {
                        setState(() => _selectedFolder = null);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderHierarchy(String? parentId, int depth) {
    final children = _allFoldersRaw.where((f) => f.parentId == parentId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      children: children.map((folder) {
        final hasChildren = _allFoldersRaw.any((f) => f.parentId == folder.id);
        
        if (!hasChildren) {
          return Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: ListTile(
              leading: Text(folder.icon, style: const TextStyle(fontSize: 20)),
              title: Text(folder.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
              onTap: () {
                setState(() => _selectedFolder = folder);
                Navigator.pop(context);
              },
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: ExpansionTile(
            key: PageStorageKey(folder.id),
            leading: Text(folder.icon, style: const TextStyle(fontSize: 20)),
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFolder = folder);
                      Navigator.pop(context);
                    },
                    child: Text(folder.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), size: 18),
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.only(right: 16),
            childrenPadding: EdgeInsets.zero,
            children: [
              _buildFolderHierarchy(folder.id, depth + 1),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _post() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final tags = _tagsController.text
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t : '#$t')
        .toList();

    final db = context.read<DatabaseService>();
    
    final prefs = await SharedPreferences.getInstance();
    final authorName = prefs.getString('user_display_name') ?? 'Me';
    final authorAvatarUrl = prefs.getString('user_avatar_url');
    final authorBio = prefs.getString('user_bio') ?? 'Local administrator & curator';

    if (_editingPost != null) {
      _editingPost!.content = content;
      _editingPost!.tags = tags;
      _editingPost!.authorName = authorName;
      _editingPost!.authorAvatarUrl = authorAvatarUrl; 
      _editingPost!.authorBio = authorBio;
      await db.savePost(_editingPost!);
    } else {
      final post = Post(
        id: const Uuid().v4(),
        content: content,
        folderId: _selectedFolder?.id,
        tags: tags,
        parentPostId: widget.parentId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorBio: authorBio,
      );
      await db.savePost(post);
      
      if (_selectedFolder != null && _selectedFolder!.isShared == true && _selectedFolder!.encryptionKey != null) {
        // Only sync if a shared folder is selected and encryption is ready
        final encryptedContent = EncryptionService.encryptMessage(post.content, _selectedFolder!.encryptionKey!);
        final cloud = context.read<CloudService>();
        await cloud.syncPost(post, encryptedContent);
      }
      // General posts (where _selectedFolder is null) are strictly LOCAL ONLY
    }

    if (!mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postId != null;
    final cream = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Thread' : 'New Thread'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TextButton(
                onPressed: _post,
                style: TextButton.styleFrom(
                  backgroundColor: cream,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor, // Reverted to background color for contrast
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(isEditing ? 'Update' : 'Post', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: GestureDetector(
              onTap: _showFolderSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cream.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cream.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedFolder?.icon ?? '📁', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _selectedFolder?.name ?? 'Select Space',
                        style: TextStyle(
                          color: cream.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: cream.withValues(alpha: 0.3)),
                    if (_selectedFolder == null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.lock_outline, size: 14, color: cream.withValues(alpha: 0.2)),
                      const SizedBox(width: 4),
                      Text('LOCAL ONLY', style: TextStyle(color: cream.withValues(alpha: 0.2), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView( // Added scrollability for long content
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _contentController,
                    autofocus: true,
                    maxLines: null,
                    minLines: 5,
                    style: TextStyle(fontSize: 19, height: 1.6, color: cream),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(color: cream.withValues(alpha: 0.15), fontSize: 19),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Tags Preview
                  if (_tagsController.text.isNotEmpty) ...[
                    Wrap(
                        spacing: 8,
                        children: _tagsController.text
                            .split(RegExp(r'[\s,]+'))
                            .where((t) => t.isNotEmpty)
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cream.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t.startsWith('#') ? t : '#$t',
                                    style: TextStyle(color: cream.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  const Divider(height: 32),
                  TextField(
                    controller: _tagsController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(fontSize: 15, color: cream.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Multiple labels? Separate with spaces",
                      hintStyle: TextStyle(color: cream.withValues(alpha: 0.15), fontSize: 14),
                      prefixIcon: Icon(Icons.label_outline, size: 20, color: cream.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/database_service.dart';
import '../services/cloud_service.dart';
import '../models/folder.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> {
  List<Folder> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final db = context.read<DatabaseService>();
    final folders = db.getFolders(parentId: null);
    
    // Start cloud sync for shared folders to keep names up to date
    final cloud = context.read<CloudService>();
    final sharedFolders = folders.where((f) => f.isShared && f.encryptionKey != null).toList();
    if (sharedFolders.isNotEmpty) {
      cloud.startFolderSync(sharedFolders, db, _loadData);
    }

    setState(() {
      _folders = folders;
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
          onRefresh: () async => _loadData(),
          color: creamColor,
          backgroundColor: const Color(0xFF121212),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBreadcrumb("Mono"),
                          _buildChevron(),
                          _buildBreadcrumb("Spaces", isActive: true),
                          const Spacer(),
                          IconButton(
                            onPressed: _showCreateSpaceDialog,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: creamColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_rounded, color: creamColor, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Digital Spaces",
                        style: GoogleFonts.outfit(
                          color: creamColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Hierarchical organization for your posts.",
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

              // Grid of Spaces
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _folders.isEmpty 
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          "Create your first digital space.",
                          style: GoogleFonts.inter(color: creamColor.withValues(alpha: 0.2), fontSize: 14),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final folder = _folders[index];
                          return _SpaceGridCard(folder: folder);
                        },
                        childCount: _folders.length,
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
                      // Simple emoji picker logic (could be expanded)
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

class _SpaceGridCard extends StatelessWidget {
  final Folder folder;
  const _SpaceGridCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const surfaceBlack = Color(0xFF121212);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/folder/${folder.id}?name=${Uri.encodeComponent(folder.name)}');
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceBlack,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: creamColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folder.icon, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: creamColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View Posts",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: creamColor.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

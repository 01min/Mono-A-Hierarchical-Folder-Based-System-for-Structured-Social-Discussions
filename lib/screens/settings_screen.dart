import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/cloud_service.dart';
import '../models/folder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _nameController.text = prefs.getString('user_display_name') ?? 'Me';
      _bioController.text = prefs.getString('user_bio') ?? 'Local administrator & curator';
      _avatarUrl = prefs.getString('user_avatar_url');
    });
  }

  Future<void> _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_display_name') ?? 'Me';
      _avatarUrl = prefs.getString('user_avatar_url');
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_display_name', name);
  }

  Future<void> _saveBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_bio', bio);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 400);
    
    if (image != null && mounted) {
      setState(() => _isUploading = true);
      final cloud = context.read<CloudService>();
      final url = await cloud.uploadAvatar(File(image.path));
      
      if (url != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_url', url);
        setState(() {
          _avatarUrl = url;
          _isUploading = false;
        });
      } else {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload avatar.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.themeMode == ThemeMode.dark;
    final cream = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _SectionHeader(title: 'IDENTITY'),
          Center(
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: cream.withValues(alpha: 0.1),
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null 
                      ? Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?', 
                          style: TextStyle(color: cream, fontSize: 32, fontWeight: FontWeight.bold))
                      : null,
                  ),
                  if (_isUploading)
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.black54,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: cream, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SettingsTile(
            leading: const Icon(Icons.person_outline),
            title: 'Display Name',
            subtitle: 'How you appear on your posts.',
            trailing: SizedBox(
              width: 120,
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.end,
                onChanged: _saveName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter name',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            leading: const Icon(Icons.history_edu_rounded),
            title: 'Personal Bio',
            subtitle: 'Your custom signature.',
            trailing: SizedBox(
              width: 120,
              child: TextField(
                controller: _bioController,
                textAlign: TextAlign.end,
                onChanged: _saveBio,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter bio',
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
          const _SectionHeader(title: 'COMMUNITY'),
          _SettingsTile(
            leading: const Icon(Icons.send_rounded),
            title: 'Invite a Friend',
            subtitle: 'Generate unlimited secure E2E invite links.',
            onTap: () => _generateInvite(context),
          ),
          const SizedBox(height: 16),
          const _SettingsTile(
            leading: Icon(Icons.info_outline),
            title: 'About Mono',
            subtitle: 'v1.0.0 - Privacy focused local-first social network.',
          ),
        ],
      ),
    );
  }

  Future<void> _generateInvite(BuildContext context) async {
    const creamColor = Color(0xFFF7F2E8);
    final nameController = TextEditingController();
    String selectedEmoji = "👥";
    bool confirmed = false;

    // 1. Ask for community name
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: creamColor.withValues(alpha: 0.05))),
          title: Text("Community Name", style: GoogleFonts.outfit(color: creamColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Give your new community a name before inviting friends.', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final emojis = ["👥", "🌐", "🍻", "🏠", "🎮", "📚", "🎨", "🌮"];
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
                        hintText: "E.g. Family Chat",
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
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  confirmed = true;
                  Navigator.pop(context);
                }
              },
              child: const Text("Next", style: TextStyle(color: creamColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (!confirmed || !context.mounted) return;

    // 2. Generate E2E invite Link
    final dummyKey = EncryptionService.generateGroupKey();
    final groupId = const Uuid().v4();
    final inviteLink = 'mono://join?groupId=$groupId&key=$dummyKey';
    
    // 3. Create the space locally for the host
    final db = context.read<DatabaseService>();
    final newFolder = Folder(
      id: groupId,
      name: nameController.text.trim(),
      icon: selectedEmoji,
      colorValue: 0xFFF7F2E8,
      isShared: true,
      encryptionKey: dummyKey,
    );
    await db.saveFolder(newFolder);

    // 4. Sync metadata to cloud
    final cloud = context.read<CloudService>();
    await cloud.syncFolderMetadata(newFolder);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this encrypted link carefully. It contains the key required to read messages.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(inviteLink, style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.grey),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: leading,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

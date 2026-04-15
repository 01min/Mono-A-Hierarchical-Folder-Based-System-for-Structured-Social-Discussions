import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/folder.dart';
import 'database_service.dart';
import 'encryption_service.dart';
import 'notification_service.dart';

class CloudService {
  final SupabaseClient? _client;
  StreamSubscription? _postSubscription;
  StreamSubscription? _folderSubscription;

  CloudService({SupabaseClient? client}) : _client = client;

  // Initialize Supabase.
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      );
    } catch (e) {
      // Ignore if keys are not set yet
    }
  }

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return _client;
    }
  }

  bool get isConnected => client != null;

  // Upload avatar to public storage and return URL
  Future<String?> uploadAvatar(File file) async {
    if (!isConnected) return null;
    try {
      // 1. Compress Image
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 400,
        minHeight: 400,
      );

      if (compressedFile == null) return null;
      final fileToUpload = File(compressedFile.path);

      // 2. Upload
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client!.storage.from('avatars').upload(fileName, fileToUpload);
      
      final url = client!.storage.from('avatars').getPublicUrl(fileName);
      return url;
    } catch (e) {
      if (e.toString().contains('Bucket not found')) {
        print('❌ Supabase Error: Storage bucket "avatars" not found. Please create it and set to Public.');
      } else {
        print('Avatar upload error: $e');
      }
      return null;
    }
  }

  // Sync encrypted post to the cloud
  Future<void> syncPost(Post post, String encryptedContent) async {
    if (!isConnected) return;
    try {
      await client!.from('posts').upsert({
        'id': post.id,
        'folder_id': post.folderId,
        'encrypted_content': encryptedContent,
        'tags': post.tags,
        'author_name': post.authorName,
        'author_avatar_url': post.authorAvatarUrl,
        'author_bio': post.authorBio,
        'created_at': post.createdAt.toIso8601String(),
      });
    } catch (e) {
      print('Cloud sync error: $e');
    }
  }

  // Sync folder metadata (name, icon)
  Future<void> syncFolderMetadata(Folder folder) async {
    if (!isConnected || !folder.isShared) return;
    try {
      await client!.from('shared_folders').upsert({
        'id': folder.id,
        'name': folder.name,
        'icon': folder.icon,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Folder metadata sync error: $e');
    }
  }

  // Subscribe to folder metadata changes
  void startFolderSync(List<Folder> sharedFolders, DatabaseService db, Function? onUpdate) {
    if (!isConnected || sharedFolders.isEmpty) return;
    
    final folderIds = sharedFolders.map((f) => f.id).toList();
    _folderSubscription?.cancel();

    _folderSubscription = client!.from('shared_folders')
      .stream(primaryKey: ['id'])
      .inFilter('id', folderIds)
      .listen((List<Map<String, dynamic>> rawFolders) {
        bool changed = false;
        for (final raw in rawFolders) {
          final id = raw['id'] as String;
          final local = db.getFolder(id);
          if (local != null) {
            final newName = raw['name'] as String? ?? local.name;
            final newIcon = raw['icon'] as String? ?? local.icon;
            if (local.name != newName || local.icon != newIcon) {
              local.name = newName;
              local.icon = newIcon;
              db.saveFolder(local);
              changed = true;
            }
          }
        }
        if (changed && onUpdate != null) {
          onUpdate();
        }
      });
  }

  // Subscribe to real-time events for joined groups
  void startRealtimeSync(List<Folder> sharedFolders, DatabaseService db) {
    if (!isConnected || sharedFolders.isEmpty) return;

    final folderIds = sharedFolders.map((f) => f.id).toList();
    
    // Unsubscribe existing
    _postSubscription?.cancel();

    _postSubscription = client!.from('posts')
      .stream(primaryKey: ['id'])
      .inFilter('folder_id', folderIds)
      .listen((List<Map<String, dynamic>> rawPosts) async {
        for (final raw in rawPosts) {
          final folderId = raw['folder_id'] as String;
          final folder = sharedFolders.firstWhere((f) => f.id == folderId);

          if (folder.encryptionKey != null) {
            final encryptedContent = raw['encrypted_content'] as String;
            final decryptedContent = EncryptionService.decryptMessage(encryptedContent, folder.encryptionKey!);
            
            final tagsList = (raw['tags'] as List?)?.cast<String>() ?? [];
            
            final post = Post(
              id: raw['id'],
              folderId: folderId,
              content: decryptedContent,
              tags: tagsList,
              isRemote: true,
              authorName: raw['author_name'] as String?,
              authorAvatarUrl: raw['author_avatar_url'] as String?,
              authorBio: raw['author_bio'] as String?,
              createdAt: DateTime.tryParse(raw['created_at'] ?? '') ?? DateTime.now(),
            );

            final postId = raw['id'] as String;
            final existingPost = db.getPost(postId);
            
            if (existingPost == null) {
              // This is a NEW post! Check if we should notify
              _handleNewPostNotification(raw, decryptedContent, folderId);
            }

            db.savePost(post);
          }
        }
      });
  }

  Future<void> _handleNewPostNotification(Map<String, dynamic> raw, String content, String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    final authorName = raw['author_name'] as String?;
    final myName = prefs.getString('user_display_name') ?? 'Me';

    // Don't notify for our own posts
    if (authorName == myName) return;

    // Check granular preferences
    final bool isFolderNotifEnabled = prefs.getBool('notif_space_$folderId') ?? false;
    final bool isAuthorNotifEnabled = (authorName != null) ? (prefs.getBool('notif_author_$authorName') ?? false) : false;

    if (isFolderNotifEnabled || isAuthorNotifEnabled) {
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: raw['id'].hashCode,
        title: authorName ?? 'New Community Post',
        body: content.length > 100 ? '${content.substring(0, 97).trim()}...' : content,
        payload: folderId,
      );
    }
  }

  void dispose() {
    _postSubscription?.cancel();
    _folderSubscription?.cancel();
  }
}

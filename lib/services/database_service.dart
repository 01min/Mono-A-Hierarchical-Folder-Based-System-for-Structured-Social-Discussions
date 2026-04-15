import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/folder.dart';
import '../models/post.dart';

class DatabaseService {
  static const String _foldersBox = 'folders';
  static const String _postsBox = 'posts';

  late Box _folderBox;
  late Box _postBox;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();
    
    // 1. Obtain or generate the master encryption key safely
    final encryptionKey = await _getEncryptionKey();
    
    // 2. Open boxes with AES Cipher
    _folderBox = await Hive.openBox(_foldersBox, encryptionCipher: HiveAesCipher(encryptionKey));
    _postBox = await Hive.openBox(_postsBox, encryptionCipher: HiveAesCipher(encryptionKey));
  }

  Future<Uint8List> _getEncryptionKey() async {
    const keyPath = 'mono_root_db_key';
    final containsKey = await _secureStorage.containsKey(key: keyPath);
    
    if (!containsKey) {
      // Generate a new 32-byte key
      final key = Hive.generateSecureKey();
      await _secureStorage.write(key: keyPath, value: base64UrlEncode(key));
      return Uint8List.fromList(key);
    } else {
      // Retrieve the existing key
      final encodedKey = await _secureStorage.read(key: keyPath);
      return base64Url.decode(encodedKey!);
    }
  }

  // --- Folder Operations ---
  List<Folder> getFolders({String? parentId}) {
    return _folderBox.values
        .map((e) => Folder.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((f) => f.parentId == parentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Folder> getAllFolders() {
    return _folderBox.values
        .map((e) => Folder.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveFolder(Folder folder) async {
    await _folderBox.put(folder.id, folder.toMap());
  }

  Future<void> deleteFolder(String id) async {
    // 1. Get all child folders to delete recursively
    final children = _folderBox.values
        .map((e) => Folder.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((f) => f.parentId == id)
        .toList();
    
    for (final child in children) {
      await deleteFolder(child.id);
    }

    // 2. Delete this folder
    await _folderBox.delete(id);

    // 3. Delete all posts in this folder
    final postsToDelete = _postBox.keys.where((key) {
      final map = _postBox.get(key);
      return map != null && map['folderId'] == id;
    }).toList();
    for (final key in postsToDelete) {
      await _postBox.delete(key);
    }
  }

  // --- Post Operations ---
  List<Post> getPosts({String? folderId, int? limit, int? offset}) {
    var posts = _postBox.values
        .map((e) => Post.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();

    if (folderId != null) {
      posts = posts.where((p) => p.folderId == folderId).toList();
    }

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (offset != null && offset < posts.length) {
      posts = posts.sublist(offset);
    }
    
    if (limit != null && limit < posts.length) {
      posts = posts.sublist(0, limit);
    }

    return posts;
  }

  List<Post> getPostsByAuthor(String authorName) {
    return _postBox.values
        .map((e) => Post.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((p) => p.authorName == authorName)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> savePost(Post post) async {
    await _postBox.put(post.id, post.toMap());
  }

  Future<void> deletePost(String id) async {
    await _postBox.delete(id);
  }

  List<Post> searchPosts(String query) {
    final q = query.toLowerCase();
    return _postBox.values
        .map((e) => Post.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((p) => 
          p.content.toLowerCase().contains(q) || 
          p.tags.any((tag) => tag.toLowerCase().contains(q))
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Folder> searchFolders(String query) {
    final q = query.toLowerCase();
    return _folderBox.values
        .map((e) => Folder.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
  }

  Folder? getFolder(String id) {
    final map = _folderBox.get(id);
    if (map == null) return null;
    return Folder.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Post? getPost(String id) {
    final map = _postBox.get(id);
    if (map == null) return null;
    return Post.fromMap(Map<dynamic, dynamic>.from(map));
  }
}

class Post {
  final String id;
  String? folderId;
  String content;
  List<String> mediaPaths;
  List<String> tags;
  String? parentPostId;
  bool isRemote;
  String? authorName;
  String? authorAvatarUrl; // Added for profile pictures
  String? authorBio;      // Added for personal signature
  DateTime createdAt;

  Post({
    required this.id,
    this.folderId,
    required this.content,
    List<String>? mediaPaths,
    List<String>? tags,
    this.parentPostId,
    this.isRemote = false,
    this.authorName,
    this.authorAvatarUrl,
    this.authorBio,
    DateTime? createdAt,
  })  : mediaPaths = mediaPaths ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'content': content,
      'mediaPaths': mediaPaths,
      'tags': tags,
      'parentPostId': parentPostId,
      'isRemote': isRemote,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'authorBio': authorBio,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Post.fromMap(Map<dynamic, dynamic> map) {
    return Post(
      id: map['id'] as String? ?? 'unk',
      folderId: map['folderId'] as String?,
      content: map['content'] as String? ?? '',
      mediaPaths: (map['mediaPaths'] as List?)?.cast<String>() ?? [],
      tags: (map['tags'] as List?)?.cast<String>() ?? [],
      parentPostId: map['parentPostId'] as String?,
      isRemote: map['isRemote'] as bool? ?? false,
      authorName: map['authorName'] as String?,
      authorAvatarUrl: map['authorAvatarUrl'] as String?,
      authorBio: map['authorBio'] as String?,
      createdAt: map['createdAt'] != null 
        ? (DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now())
        : DateTime.now(),
    );
  }
}

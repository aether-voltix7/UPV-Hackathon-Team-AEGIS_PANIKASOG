import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory {
  community,
  verified,
  tasks,
  news,
}

class PostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final String barangay;
  final String city;
  final String title;
  final String caption;
  final String? imageUrl;
  final List<String> imageUrls; // new multi-image field
  final List<String> tags; // e.g. ['Clean-up', 'Trash Collection', 'Beach']
  final PostCategory category;
  final bool isUrgent;
  final List<String> urgentReasons; // e.g. ['Injured people']
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final DateTime createdAt;
  final String? relatedTaskId; // links to a Task if category == tasks

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    required this.barangay,
    required this.city,
    required this.title,
    required this.caption,
    this.imageUrl,
    this.imageUrls = const [],
    this.tags = const [],
    this.category = PostCategory.community,
    this.isUrgent = false,
    this.urgentReasons = const [],
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.relatedTaskId,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorUsername: d['authorUsername'] ?? '',
      authorAvatarUrl: d['authorAvatarUrl'],
      authorIsVerified: d['authorIsVerified'] ?? false,
      barangay: d['barangay'] ?? '',
      city: d['city'] ?? '',
      title: d['title'] ?? '',
      caption: d['caption'] ?? '',
      imageUrl: d['imageUrl'],
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
      category: _categoryFromString(d['category']),
      isUrgent: d['isUrgent'] ?? false,
      urgentReasons: List<String>.from(d['urgentReasons'] ?? []),
      upvotes: d['upvotes'] ?? 0,
      downvotes: d['downvotes'] ?? 0,
      commentCount: d['commentCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedTaskId: d['relatedTaskId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorUsername': authorUsername,
        'authorAvatarUrl': authorAvatarUrl,
        'authorIsVerified': authorIsVerified,
        'barangay': barangay,
        'city': city,
        'title': title,
        'caption': caption,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'tags': tags,
        'category': category.name,
        'isUrgent': isUrgent,
        'urgentReasons': urgentReasons,
        'upvotes': upvotes,
        'downvotes': downvotes,
        'commentCount': commentCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'relatedTaskId': relatedTaskId,
      };

  static PostCategory _categoryFromString(String? s) {
    switch (s) {
      case 'verified':
        return PostCategory.verified;
      case 'tasks':
        return PostCategory.tasks;
      case 'news':
        return PostCategory.news;
      default:
        return PostCategory.community;
    }
  }

    PostModel copyWith({
      int? upvotes,
      int? downvotes,
      int? commentCount,
      List<String>? imageUrls,
    }) => PostModel(
        id: id,
        authorId: authorId,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        authorIsVerified: authorIsVerified,
        barangay: barangay,
        city: city,
        title: title,
        caption: caption,
        imageUrl: imageUrl,
        imageUrls: imageUrls ?? this.imageUrls,
        tags: tags,
        category: category,
        isUrgent: isUrgent,
        urgentReasons: urgentReasons,
        upvotes: upvotes ?? this.upvotes,
        downvotes: downvotes ?? this.downvotes,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
        relatedTaskId: relatedTaskId,
      );
}

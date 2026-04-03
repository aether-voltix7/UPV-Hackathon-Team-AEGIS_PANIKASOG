import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/urgent_task_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Feed ──────────────────────────────────────────────────────────────────

  Query<Map<String, dynamic>> feedQuery({PostCategory? category}) {
    Query<Map<String, dynamic>> q =
        _db.collection('posts').orderBy('createdAt', descending: true);
    if (category != null) {
      q = q.where('category', isEqualTo: category.name);
    }
    return q;
  }

  Future<PostModel?> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  // ─── Create Post ───────────────────────────────────────────────────────────

  Future<PostModel> createPost({
    required String authorId,
    required String authorUsername,
    String? authorAvatarUrl,
    bool authorIsVerified = false,
    required String barangay,
    required String city,
    required String title,
    required String caption,
    File? imageFile,
    required List<String> tags,
    required PostCategory category,
    bool isUrgent = false,
    List<String> urgentReasons = const [],
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      final ref = FirebaseStorage.instance.ref(
        'posts/${DateTime.now().millisecondsSinceEpoch}_$authorId.jpg',
      );
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final docRef = _db.collection('posts').doc();
    final post = PostModel(
      id: docRef.id,
      authorId: authorId,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      authorIsVerified: authorIsVerified,
      barangay: barangay,
      city: city,
      title: title,
      caption: caption,
      imageUrl: imageUrl,
      tags: tags,
      category: category,
      isUrgent: isUrgent,
      urgentReasons: urgentReasons,
      createdAt: DateTime.now(),
    );
    await docRef.set(post.toFirestore());
    return post;
  }

  // ─── Voting ────────────────────────────────────────────────────────────────

  Future<String?> getUserVote(String postId, String userId) async {
    final doc = await _db
        .collection('posts')
        .doc(postId)
        .collection('votes')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return data['type'] as String?;
  }

  Future<void> vote({
    required String postId,
    required String userId,
    required String voteType,
  }) async {
    final postRef = _db.collection('posts').doc(postId);
    final voteRef = postRef.collection('votes').doc(userId);

    await _db.runTransaction((tx) async {
      final voteDoc = await tx.get(voteRef);

      // Fix: avoid null-aware subscript inside ternary — read separately
      String? existingVote;
      if (voteDoc.exists) {
        final voteData = voteDoc.data();
        existingVote = voteData != null ? voteData['type'] as String? : null;
      }

      if (existingVote == voteType) {
        // Toggle off — remove vote
        tx.delete(voteRef);
        tx.update(postRef, {
          '${voteType}votes': FieldValue.increment(-1),
        });
      } else {
        // Switch vote or new vote
        if (existingVote != null) {
          tx.update(postRef, {
            '${existingVote}votes': FieldValue.increment(-1),
          });
        }
        tx.set(voteRef, {
          'type': voteType,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {
          '${voteType}votes': FieldValue.increment(1),
        });
      }
    });
  }

  // ─── Urgent Tasks ──────────────────────────────────────────────────────────

  Stream<List<UrgentTaskModel>> urgentTasksStream() {
    return _db
        .collection('tasks')
        .where('isUrgent', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .orderBy('scheduledAt')
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UrgentTaskModel.fromFirestore(d))
            .toList());
  }

  // ─── Mock data for development ─────────────────────────────────────────────

  static List<PostModel> get mockPosts => [
        PostModel(
          id: 'mock_1',
          authorId: 'uid_1',
          authorUsername: 'juan_org',
          authorIsVerified: true,
          barangay: 'Brgy. Mainis',
          city: 'Iloilo City',
          title: 'Successful Cleanup Drive',
          caption:
              'Our community cleanup drive was a huge success! 🌊 Thanks to '
              'all the amazing volunteers who pitched in to clear debris, sweep '
              'streets, and participated in our disaster preparedness community '
              'session. Your time and effort made a real difference—together, '
              "we're stronger and our community is cleaner and safer. 💪 "
              '#BrgyMainis #CleanupSuccess #DisasterReady',
          tags: const ['Clean-up', 'Trash Collection', 'Beach'],
          category: PostCategory.community,
          upvotes: 1287,
          commentCount: 45,
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        PostModel(
          id: 'mock_2',
          authorId: 'uid_2',
          authorUsername: 'barangay_official',
          authorIsVerified: true,
          barangay: 'Brgy. Molo',
          city: 'Iloilo City',
          title: 'Stranded on Rooftops in Brgy. Aegis',
          caption:
              'Residents stranded due to flash flood. Rescue teams are on '
              'their way. Please avoid the area.',
          tags: const ['Flood', 'Rescue Needed', 'Relief Mission'],
          category: PostCategory.verified,
          isUrgent: true,
          urgentReasons: const ['Injured people'],
          upvotes: 543,
          commentCount: 87,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];

  static List<UrgentTaskModel> get mockUrgentTasks => [
        UrgentTaskModel(
          id: 'utask_1',
          title: 'Medical Assistance for Injured Individuals...',
          barangay: 'Brgy. Rizal',
          city: 'Iloilo City',
          category: 'Emergency Response',
          tags: const ['Injured People'],
          points: 250,
          volunteersNeeded: 214,
          volunteersAccepted: 18,
          scheduledAt: DateTime(2025, 3, 21, 14, 0),
          urgency: UrgencyLevel.urgent,
          urgentReasons: const [
            'This task involves injured people',
            'This task is also verified and officially tagged as urgent by #DisasterDyvert',
          ],
          isVerifiedUrgent: true,
        ),
      ];

      // ─── User Posts ───────────────────────────────────────────

    Stream<List<PostModel>> getPostsByUser(String userId) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
}
}


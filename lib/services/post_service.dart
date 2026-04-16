import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../models/post_model.dart';
import '../models/urgent_task_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hardcoded Iloilo City landmarks (LatLng)
  static const List<Map<String, dynamic>> _landmarks = [
    {'name': 'Iloilo City Hall', 'lat': 10.7202, 'lng': 122.5621},
    {'name': 'St. Paul\'s Hospital', 'lat': 10.7189, 'lng': 122.5675},
    {'name': 'Iloilo Mission Hospital', 'lat': 10.7132, 'lng': 122.5633},
    {'name': 'Iloilo Provincial Capitol', 'lat': 10.7043, 'lng': 122.5667},
  ];

  // Keyword sets
  static const List<String> _urgentKeywords = [
    'fire', 'flood', 'earthquake', 'typhoon', 'rescue', 'evacuate', 'help',
    'emergency', 'stranded', 'injured'
  ];
  static const List<String> _suspiciousKeywords = [
    'rumor', 'hearsay', 'maybe', 'not sure', 'fake', 'hoax', 'allegedly'
  ];

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

  // ─── Create Post with Smart Proactive Filter ──────────────────────────────
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
    List<File> imageFiles = const [],
    Position? userLocation, // NEW: location from provider
  }) async {
    List<String> imageUrls = [];

    // Handle single imageFile (backward compatibility)
    if (imageFile != null) {
      final ref = FirebaseStorage.instance.ref(
        'posts/${DateTime.now().millisecondsSinceEpoch}_$authorId.jpg',
      );
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    // Handle multiple imageFiles
    for (final file in imageFiles) {
      final ref = FirebaseStorage.instance.ref(
        'posts/${DateTime.now().millisecondsSinceEpoch}_${file.hashCode}.jpg',
      );
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    // --- SMART PROACTIVE FILTER ANALYSIS ---
    final fullContent = "$title $caption";
    final analysis = _analyzeContent(fullContent, userLocation);

    final docRef = _db.collection('posts').doc();
    final post = PostModel(
      id: docRef.id,
      authorId: authorId,
      authorUsername: authorUsername.isNotEmpty
          ? authorUsername
          : 'user_${authorId.substring(0, 6)}',
      authorAvatarUrl: authorAvatarUrl,
      authorIsVerified: authorIsVerified,
      barangay: barangay,
      city: city,
      title: title,
      caption: caption,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      imageUrls: imageUrls,
      tags: tags,
      category: category,
      isUrgent: isUrgent,
      urgentReasons: urgentReasons,
      createdAt: DateTime.now(),
      isValidated: analysis['isValidated'],
      validationSource: analysis['source'],
    );
    await docRef.set(post.toFirestore());
    return post;
  }

  // ─── Private Analysis Method ──────────────────────────────────────────────
  Map<String, dynamic> _analyzeContent(String content, Position? userLocation) {
    final lowerContent = content.toLowerCase();

    // 1. Keyword Analysis
    bool hasUrgentKeyword = _urgentKeywords.any((kw) => lowerContent.contains(kw));
    bool hasSuspiciousKeyword = _suspiciousKeywords.any((kw) => lowerContent.contains(kw));

    // 2. Pattern Checks
    int exclamationCount = content.split('').where((c) => c == '!').length;
    bool excessiveExclamations = exclamationCount > 3;
    bool isAllUppercase = content == content.toUpperCase() &&
        content.trim().isNotEmpty &&
        content.contains(RegExp(r'[A-Z]'));

    // 3. Geofencing Logic (only if userLocation is provided)
    bool nearLandmark = false;
    String landmarkName = '';
    if (userLocation != null) {
      for (final landmark in _landmarks) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          landmark['lat'],
          landmark['lng'],
        );
        if (distance <= 200) { // within 200 meters
          nearLandmark = true;
          landmarkName = landmark['name'];
          break;
        }
      }
    }

    // Decision Logic
    if (nearLandmark) {
      return {'isValidated': true, 'source': 'Verified Location ($landmarkName)'};
    } else if (hasUrgentKeyword && !hasSuspiciousKeyword) {
      return {'isValidated': true, 'source': 'Urgent Keyword Match'};
    } else if (excessiveExclamations || isAllUppercase) {
      return {'isValidated': false, 'source': 'Suspicious Pattern (ALL CAPS or !!!)'};
    } else if (hasSuspiciousKeyword) {
      return {'isValidated': false, 'source': 'Suspicious Keyword Detected'};
    } else {
      return {'isValidated': false, 'source': 'Default - Needs Review'};
    }
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

      String? existingVote;
      if (voteDoc.exists) {
        final voteData = voteDoc.data();
        existingVote = voteData != null ? voteData['type'] as String? : null;
      }

      if (existingVote == voteType) {
        tx.delete(voteRef);
        tx.update(postRef, {
          '${voteType}votes': FieldValue.increment(-1),
        });
      } else {
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

  // ─── Urgent Tasks Stream ──────────────────────────────────────────────────
  Stream<List<UrgentTaskModel>> urgentTasksStream() {
    return _db
        .collection('tasks')
        .where('isUrgent', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .orderBy('scheduledStart')
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UrgentTaskModel.fromFirestore(d))
            .toList());
  }

  // ─── User Posts Stream ────────────────────────────────────────────────────
  Stream<List<PostModel>> getPostsByUser(String userId) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // ─── Mock data for development (unchanged) ────────────────────────────────
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
          taskId: 'task_1',
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
}
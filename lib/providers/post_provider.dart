import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/urgent_task_model.dart';
import '../services/post_service.dart';

enum FeedFilter { all, community, verified, tasks, news }

class PostProvider extends ChangeNotifier {
  final PostService _service;

  PostProvider(this._service) {
    // FIX: Don't pre-load mock urgent tasks — let the stream populate them.
    //      Starting with an empty list avoids the race where mocks flash
    //      before real data arrives.
    _listenUrgentTasks();
  }

  // ─── Feed state ─────────────────────────────────────────────────────────────
  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  FeedFilter _activeFilter = FeedFilter.all;
  String? _error;

  // ─── Urgent Tasks state ─────────────────────────────────────────────────────
  List<UrgentTaskModel> _urgentTasks = [];
  bool _urgentDrawerExpanded = true;

  // ─── Create post state ──────────────────────────────────────────────────────
  bool _isCreatingPost = false;

  // ─── Per-user vote cache  (postId → 'up'|'down'|null) ──────────────────────
  // FIX: This is now populated from Firestore on feed load so votes persist
  //      across sessions.  Previously it was always empty on app start.
  final Map<String, String?> _userVotes = {};
  String? _voteUserId;

  // ─── Getters ────────────────────────────────────────────────────────────────
  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  FeedFilter get activeFilter => _activeFilter;
  String? get error => _error;
  List<UrgentTaskModel> get urgentTasks => _urgentTasks;
  bool get urgentDrawerExpanded => _urgentDrawerExpanded;
  bool get isCreatingPost => _isCreatingPost;
  String? userVoteFor(String postId) => _userVotes[postId];

  // ─── Load / Refresh ─────────────────────────────────────────────────────────

  Future<void> loadFeed({bool refresh = false, String? userId}) async {
    if (_isLoading) return;
    if (userId != null) _voteUserId = userId;
    if (refresh) {
      _posts = [];
      _hasMore = true;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _service.feedQuery().get();
      _posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

      // FIX: Do NOT append mock posts to real Firestore data.
      //      Mock posts caused the feed to show stale/fake content on every
      //      load and made upvote counts inconsistent (mocks have hardcoded
      //      values that never match Firestore).
      // if (kDebugMode && _posts.isEmpty) {
      //   _posts.addAll(PostService.mockPosts); // only in debug when empty
      // }

      _hasMore = false;

      // FIX: Load persisted votes for all loaded posts so the thumbs
      //      up/down highlight correctly from the first frame.
      if (_voteUserId != null) {
        await _loadVotesForPosts(_posts.map((p) => p.id).toList(), _voteUserId!);
      }
    } catch (e) {
      _error = 'Failed to load posts. Pull to refresh.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Batch-loads vote state from Firestore for the given post IDs.
  Future<void> _loadVotesForPosts(List<String> postIds, String userId) async {
    // Run fetches concurrently — safe for typical feed sizes (≤50 posts).
    final futures = postIds.map((id) async {
      final vote = await _service.getUserVote(id, userId);
      if (vote != null) _userVotes[id] = vote;
    });
    await Future.wait(futures);
    notifyListeners();
  }

  // ─── Filtering ──────────────────────────────────────────────────────────────

  void setFilter(FeedFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    loadFeed(refresh: true);
    notifyListeners();
  }

  // ─── Voting ─────────────────────────────────────────────────────────────────

  Future<void> vote({
    required String postId,
    required String userId,
    required String voteType,
  }) async {
    _voteUserId = userId;
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final existingVote = _userVotes[postId];

    // Optimistic update.
    int upDelta = 0, downDelta = 0;
    if (existingVote == voteType) {
      if (voteType == 'up') upDelta = -1;
      if (voteType == 'down') downDelta = -1;
      _userVotes[postId] = null;
    } else {
      if (existingVote == 'up') upDelta -= 1;
      if (existingVote == 'down') downDelta -= 1;
      if (voteType == 'up') upDelta += 1;
      if (voteType == 'down') downDelta += 1;
      _userVotes[postId] = voteType;
    }

    _posts[index] = post.copyWith(
      upvotes: post.upvotes + upDelta,
      downvotes: post.downvotes + downDelta,
    );
    notifyListeners();

    try {
      await _service.vote(postId: postId, userId: userId, voteType: voteType);
    } catch (_) {
      // Roll back on error.
      _posts[index] = post;
      _userVotes[postId] = existingVote;
      notifyListeners();
    }
  }

  // ─── Urgent Tasks ────────────────────────────────────────────────────────────

  void _listenUrgentTasks() {
    _service.urgentTasksStream().listen((tasks) {
      if (tasks.isNotEmpty) {
        // Live data available — use it exclusively.
        _urgentTasks = tasks;
      } else {
        // Firestore returned empty (no urgent tasks right now) — show mocks
        // only in debug so testers can see the UI.
        if (kDebugMode) {
          _urgentTasks = PostService.mockUrgentTasks;
        } else {
          _urgentTasks = [];
        }
      }
      notifyListeners();
    }, onError: (_) {
      // Stream error (offline, permissions, etc.) — fall back to mocks.
      _urgentTasks = PostService.mockUrgentTasks;
      notifyListeners();
    });
  }

  void toggleUrgentDrawer() {
    _urgentDrawerExpanded = !_urgentDrawerExpanded;
    notifyListeners();
  }

  // ─── Create Post ─────────────────────────────────────────────────────────────

  Future<PostModel?> createPost({
    required String authorId,
    required String authorUsername,
    String? authorAvatarUrl,
    bool authorIsVerified = false,
    required String barangay,
    required String city,
    required String title,
    required String caption,
    File? imageFile,
    List<File> imageFiles = const [],
    required List<String> tags,
    required PostCategory category,
  }) async {
    _isCreatingPost = true;
    notifyListeners();

    try {
      final post = await _service.createPost(
        authorId: authorId,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        authorIsVerified: authorIsVerified,
        barangay: barangay,
        city: city,
        title: title,
        caption: caption,
        imageFile: imageFiles.isNotEmpty ? imageFiles.first : imageFile,
        imageFiles: imageFiles,
        tags: tags,
        category: category,
      );
      _posts.insert(0, post);
      notifyListeners();
      return post;
    } catch (e) {
      _error = 'Failed to create post. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _isCreatingPost = false;
      notifyListeners();
    }
  }
}
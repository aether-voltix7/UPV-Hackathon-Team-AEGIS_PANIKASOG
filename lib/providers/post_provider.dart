import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/urgent_task_model.dart';
import '../services/post_service.dart';

enum FeedFilter { all, community, verified, tasks, news }

class PostProvider extends ChangeNotifier {
  final PostService _service;

  PostProvider(this._service) {
    _urgentTasks = PostService.mockUrgentTasks;
    _listenUrgentTasks();
  }

  

  // ─── Feed state ────────────────────────────────────────────────────────────
  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  FeedFilter _activeFilter = FeedFilter.all;
  String? _error;

  // ─── Urgent Tasks state ────────────────────────────────────────────────────
  List<UrgentTaskModel> _urgentTasks = [];
  bool _urgentDrawerExpanded = true;

  // ─── Create post state ─────────────────────────────────────────────────────
  bool _isCreatingPost = false;

  // ─── User votes cache  (postId -> 'up'|'down'|null) ───────────────────────
  final Map<String, String?> _userVotes = {};

  // ─── Getters ───────────────────────────────────────────────────────────────
  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  FeedFilter get activeFilter => _activeFilter;
  String? get error => _error;
  List<UrgentTaskModel> get urgentTasks => _urgentTasks;
  bool get urgentDrawerExpanded => _urgentDrawerExpanded;
  bool get isCreatingPost => _isCreatingPost;
  String? userVoteFor(String postId) => _userVotes[postId];

  // ─── Load / Refresh ────────────────────────────────────────────────────────

  Future<void> loadFeed({bool refresh = false}) async {
  if (_isLoading) return;
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
    _posts.addAll(PostService.mockPosts); // mock posts
    _hasMore = false;
  } catch (e) {
    _error = 'Failed to load posts. Pull to refresh.';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // ─── Filtering ─────────────────────────────────────────────────────────────

  void setFilter(FeedFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    loadFeed(refresh: true);
    notifyListeners();
  }

  // ─── Voting ────────────────────────────────────────────────────────────────

  Future<void> vote({
    required String postId,
    required String userId,
    required String voteType,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final existingVote = _userVotes[postId];

    // Optimistic update
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
      await _service.vote(
          postId: postId, userId: userId, voteType: voteType);
    } catch (_) {
      // Roll back on error
      _posts[index] = post;
      _userVotes[postId] = existingVote;
      notifyListeners();
    }
  }

  // ─── Urgent Tasks ──────────────────────────────────────────────────────────

    void _listenUrgentTasks() {
    _service.urgentTasksStream().listen((tasks) {
      final mockIds = PostService.mockUrgentTasks.map((t) => t.id).toSet();
      final liveIds = tasks.map((t) => t.id).toSet();
      _urgentTasks = [
        ...tasks,
        // only add mocks that don't clash with live data
        ...PostService.mockUrgentTasks.where((t) => !liveIds.contains(t.id)),
      ];
      notifyListeners();
    }, onError: (e) {
      _urgentTasks = PostService.mockUrgentTasks;
      notifyListeners();
    });
  }

  void toggleUrgentDrawer() {
    _urgentDrawerExpanded = !_urgentDrawerExpanded;
    notifyListeners();
  }

  // ─── Create Post ───────────────────────────────────────────────────────────

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
        imageFile: imageFile,
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
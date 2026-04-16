import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../models/post_model.dart';
import '../models/urgent_task_model.dart';
import '../services/post_service.dart';

enum FeedFilter { all, community, verified, tasks, news }

class PostProvider extends ChangeNotifier {
  final PostService _service;

  PostProvider(this._service) {
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
      _hasMore = false;

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

  Future<void> _loadVotesForPosts(List<String> postIds, String userId) async {
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
      _posts[index] = post;
      _userVotes[postId] = existingVote;
      notifyListeners();
    }
  }

  // ─── Urgent Tasks ────────────────────────────────────────────────────────────
  void _listenUrgentTasks() {
    _service.urgentTasksStream().listen((tasks) {
      if (tasks.isNotEmpty) {
        _urgentTasks = tasks;
      } else {
        if (kDebugMode) {
          _urgentTasks = PostService.mockUrgentTasks;
        } else {
          _urgentTasks = [];
        }
      }
      notifyListeners();
    }, onError: (_) {
      _urgentTasks = PostService.mockUrgentTasks;
      notifyListeners();
    });
  }

  void toggleUrgentDrawer() {
    _urgentDrawerExpanded = !_urgentDrawerExpanded;
    notifyListeners();
  }

  // ─── Create Post (updated to accept userLocation) ─────────────────────────
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
    Position? userLocation, // NEW: location for validation
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
        userLocation: userLocation,
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
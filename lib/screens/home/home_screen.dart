import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../tasks/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/urgent_tasks_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadFeed(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<PostProvider>().loadFeed();
    }
  }

  Future<void> _handleVote(
      BuildContext context, PostModel post, String voteType) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    await context.read<PostProvider>().vote(
          postId: post.id,
          userId: userId,
          voteType: voteType,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: _HomeAppBar(),
      body: _HomeBody(
        scrollCtrl: _scrollCtrl,
        onVote: _handleVote,
      ),
    );
  }
}

// ─── App Bar ───────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.directions_run, color: AppColors.primary, size: 22),
          SizedBox(width: 6),
          Text('PANIKASOG', style: AppTextStyles.logoText),
        ],
      ),
      actions: [
        // Avatar
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.chipBg,
            backgroundImage:
                user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
            child: user?.avatarUrl == null
                ? Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textDark, size: 22),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  final ScrollController scrollCtrl;
  final Future<void> Function(BuildContext, PostModel, String) onVote;

  const _HomeBody({required this.scrollCtrl, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    return Stack(
      children: [
        // ── Scrollable feed ──────────────────────────────────────────────────
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<PostProvider>().loadFeed(refresh: true),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              // Search bar + filter chips
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: const Column(
                    children: [
                      // ── Onboarding banner (first-time users) ───────────────
                      _OnboardingBanner(),
                      SizedBox(height: 12),

                      // ── Search bar ─────────────────────────────────────────
                      AppSearchField(hint: 'Search posts...'),
                      SizedBox(height: 10),

                      // ── Filter chips ───────────────────────────────────────
                      _FilterChips(),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Posts ────────────────────────────────────────────────────
              if (postProvider.isLoading && postProvider.posts.isEmpty)
                const SliverToBoxAdapter(child: _LoadingFeed())
              else if (postProvider.posts.isEmpty)
                const SliverToBoxAdapter(child: _EmptyFeed())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i == postProvider.posts.length) {
                        return postProvider.hasMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 120);
                      }
                      final post = postProvider.posts[i];
                      final userId = context.read<AuthProvider>().user?.uid;
                      return PostCard(
                        post: post,
                        currentUserId: userId,
                        userVote: postProvider.userVoteFor(post.id),
                        onUpvote: () => onVote(ctx, post, 'up'),
                        onDownvote: () => onVote(ctx, post, 'down'),
                      );
                    },
                    childCount: postProvider.posts.length + 1,
                  ),
                ),

              // Space for urgent drawer
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),

        // ── Urgent Tasks drawer (pinned bottom) ──────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: UrgentTasksDrawer(
            tasks: postProvider.urgentTasks,
            isExpanded: postProvider.urgentDrawerExpanded,
            onToggle: postProvider.toggleUrgentDrawer,
            onTaskTap: (task) async {
              // First try Firestore
              final doc = await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(task.taskId)
                  .get();
              if (!context.mounted) return;

              TaskModel? fullTask;
              if (doc.exists) {
                fullTask = TaskModel.fromFirestore(doc);
              } else {
                // Fall back to mock tasks (for development)
                fullTask = TaskModel.mockTasks
                    .where((t) => t.id == task.taskId)
                    .firstOrNull;
              }

              if (fullTask != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(task: fullTask!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task details not found.')),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─── Onboarding banner (shown on first visit) ──────────────────────────────────
class _OnboardingBanner extends StatefulWidget {
  const _OnboardingBanner();

  @override
  State<_OnboardingBanner> createState() => _OnboardingBannerState();
}

class _OnboardingBannerState extends State<_OnboardingBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.waving_hand, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This is the Homepage',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
                const Text(
                  'Stay informed about your community.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _visible = false),
            child: const Icon(Icons.close, color: AppColors.hintGrey, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chips row ──────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final active = context.watch<PostProvider>().activeFilter;
    final onChanged = context.read<PostProvider>().setFilter;
    const filters = [
      (FeedFilter.all, 'All'),
      (FeedFilter.community, 'Community'),
      (FeedFilter.verified, 'Verified'),
      (FeedFilter.tasks, 'Tasks'),
      (FeedFilter.news, 'News'),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (filter, label) = filters[i];
          final isActive = active == filter;
          return GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isActive ? AppColors.white : AppColors.textGrey,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Loading skeleton ──────────────────────────────────────────────────────────
class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _Shimmer(width: 36, height: 36, radius: 18),
                SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Shimmer(width: 100, height: 12),
                  SizedBox(height: 4),
                  _Shimmer(width: 140, height: 10),
                ]),
              ]),
              SizedBox(height: 12),
              _Shimmer(width: double.infinity, height: 14),
              SizedBox(height: 8),
              _Shimmer(width: 200, height: 10),
              SizedBox(height: 12),
              _Shimmer(width: double.infinity, height: 180),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 8});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
              const Color(0xFFEEEEEE), const Color(0xFFE0E0E0), _ctrl.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── Empty feed ────────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.newspaper_outlined, size: 64, color: AppColors.borderGrey),
          SizedBox(height: 16),
          Text('No posts yet', style: AppTextStyles.h2),
          SizedBox(height: 8),
          Text(
            'Be the first to share something with your community.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

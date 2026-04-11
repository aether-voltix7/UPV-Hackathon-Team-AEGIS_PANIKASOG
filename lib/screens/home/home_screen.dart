import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/text_styles.dart';
import '../../models/post_model.dart';
import '../../models/task_model.dart';
import '../../models/urgent_task_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/vote_dialog.dart';
import '../../widgets/app_logo.dart';
import '../tasks/task_detail_screen.dart';
import 'post_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _figmaPurple = Color(0xFF520052);

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  FeedFilter _selectedFilter = FeedFilter.all;
  bool _urgentExpanded = false;

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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<PostProvider>().loadFeed();
    }
  }

  List<PostModel> _filteredPosts(List<PostModel> allPosts) {
    var filtered = allPosts;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.caption.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    switch (_selectedFilter) {
      case FeedFilter.community:
        return filtered.where((p) => p.category == PostCategory.community).toList();
      case FeedFilter.verified:
        return filtered.where((p) => p.authorIsVerified).toList();
      case FeedFilter.tasks:
        return filtered.where((p) => p.category == PostCategory.tasks).toList();
      case FeedFilter.news:
        return filtered.where((p) => p.category == PostCategory.news).toList();
      default:
        return filtered;
    }
  }

  Future<void> _handleVote(
      BuildContext context, PostModel post, String voteType) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    final confirmed = await showVoteDialog(
      context: context,
      post: post,
      voteType: voteType,
    );
    if (confirmed == true && context.mounted) {
      await context.read<PostProvider>().vote(
            postId: post.id,
            userId: userId,
            voteType: voteType,
          );
    }
  }

  Widget _buildStickyFilterRow() {
    return Container(
      color: const Color(0xFFFCF5F7),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'All',
              isSelected: _selectedFilter == FeedFilter.all,
              onSelected: () => setState(() => _selectedFilter = FeedFilter.all),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _FilterChip(
              label: 'Community',
              isSelected: _selectedFilter == FeedFilter.community,
              onSelected: () => setState(() => _selectedFilter = FeedFilter.community),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FilterChip(
              label: 'Verified',
              isSelected: _selectedFilter == FeedFilter.verified,
              onSelected: () => setState(() => _selectedFilter = FeedFilter.verified),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FilterChip(
              label: 'Tasks',
              isSelected: _selectedFilter == FeedFilter.tasks,
              onSelected: () => setState(() => _selectedFilter = FeedFilter.tasks),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FilterChip(
              label: 'News',
              isSelected: _selectedFilter == FeedFilter.news,
              onSelected: () => setState(() => _selectedFilter = FeedFilter.news),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final auth = context.watch<AuthProvider>();
    final allPosts = postProvider.posts;
    final filteredPosts = _filteredPosts(allPosts);
    final urgentTasks = postProvider.urgentTasks;

    final Color backgroundColor = const Color(0xFFFCF5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(iconSize: 100),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(auth.user?.avatarUrl ?? 'https://via.placeholder.com/150'),
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87, size: 26),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => postProvider.loadFeed(refresh: true),
            color: const Color(0xFFC2185B),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: _figmaPurple,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search posts...',
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(Icons.search, color: _figmaPurple, size: 15),
                                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF111111)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 31,
                          height: 33,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _figmaPurple,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: _figmaPurple.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.tune, color: Colors.white, size: 16),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    minExtent: 50,
                    maxExtent: 50,
                    child: _buildStickyFilterRow(),
                  ),
                ),

                if (postProvider.isLoading && allPosts.isEmpty)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFFC2185B))))
                else if (postProvider.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(postProvider.error!, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => postProvider.loadFeed(refresh: true),
                            child: const Text('Retry')
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredPosts.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('No posts found', style: AppTextStyles.bodyMedium)))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final post = filteredPosts[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: PostCard(
                            post: post,
                            currentUserId: auth.user?.uid,
                            userVote: postProvider.userVoteFor(post.id),
                            onUpvote: () => _handleVote(context, post, 'up'),
                            onDownvote: () => _handleVote(context, post, 'down'),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                          ),
                        );
                      },
                      childCount: filteredPosts.length,
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),

          if (urgentTasks.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: _UrgentCollapsible(
                expanded: _urgentExpanded,
                onToggle: () => setState(() => _urgentExpanded = !_urgentExpanded),
                tasks: urgentTasks,
              ),
            ),
        ],
      ),
    );
  }
}

class _UrgentCollapsible extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final List<UrgentTaskModel> tasks;

  const _UrgentCollapsible({
    required this.expanded,
    required this.onToggle,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC2185B),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Urgent Tasks',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A2A66),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(color: Colors.black12, height: 1, thickness: 1),
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return _UrgentTaskTile(task: task);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentTaskTile extends StatelessWidget {
  final UrgentTaskModel task;
  const _UrgentTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final fullTask = TaskModel(
          id: task.id,
          title: task.title,
          description: task.urgentReasons.join(', '),
          barangay: task.barangay,
          city: task.city,
          category: TaskCategory.emergencyResponse,
          points: task.points,
          volunteersNeeded: task.volunteersNeeded,
          volunteersAccepted: task.volunteersAccepted,
          scheduledStart: task.scheduledAt,
          scheduledEnd: task.scheduledAt.add(const Duration(hours: 2)),
          createdBy: '',
          isUrgent: true,
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: fullTask)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_outlined, color: Colors.black54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.barangay}, ${task.city} • ${task.points} pts',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const activeBorder = Color(0xFFDF0B33);
    const activeStart = Color(0xFFDF0B33);
    const activeEnd = Color(0xFFAB0857);

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [activeStart, activeEnd])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: activeBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF111111),
            fontWeight: FontWeight.w500,
            fontSize: 11,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtent;
  final double maxExtent;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.minExtent != minExtent ||
        oldDelegate.maxExtent != maxExtent ||
        oldDelegate.child != child;
  }
}
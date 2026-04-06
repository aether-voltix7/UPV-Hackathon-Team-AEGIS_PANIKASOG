import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../tasks/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/urgent_tasks_drawer.dart';
import '../../widgets/vote_dialog.dart';

class HomeScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: RefreshIndicator(
        onRefresh: () => postProvider.loadFeed(refresh: true),
        child: CustomScrollView(
          slivers: [
            // Urgent tasks drawer (pinned at top)
            SliverToBoxAdapter(
              child: UrgentTasksDrawer(
                tasks: postProvider.urgentTasks,
                isExpanded: postProvider.urgentDrawerExpanded,
                onToggle: postProvider.toggleUrgentDrawer,
                onTaskTap: (UrgentTaskModel urgentTask) {
                  final task = TaskModel(
                    id: urgentTask.id,
                    title: urgentTask.title,
                    description: urgentTask.urgentReasons.join(', '),
                    barangay: urgentTask.barangay,
                    city: urgentTask.city,
                    category: TaskCategory.emergencyResponse,
                    points: urgentTask.points,
                    volunteersNeeded: urgentTask.volunteersNeeded,
                    volunteersAccepted: urgentTask.volunteersAccepted,
                    scheduledStart: urgentTask.scheduledAt,
                    scheduledEnd: urgentTask.scheduledAt.add(const Duration(hours: 2)),
                    createdBy: '',
                    isUrgent: true,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
                },
              ),
            ),
            // Post feed
            if (postProvider.isLoading && postProvider.posts.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (postProvider.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(postProvider.error!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => postProvider.loadFeed(refresh: true), child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (postProvider.posts.isEmpty)
              const SliverFillRemaining(child: Center(child: Text('No posts yet', style: AppTextStyles.bodyMedium)))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final post = postProvider.posts[i];
                    return PostCard(
                      post: post,
                      currentUserId: auth.user?.uid,
                      userVote: postProvider.userVoteFor(post.id),
                      onUpvote: () => postProvider.vote(postId: post.id, userId: auth.user?.uid ?? '', voteType: 'up'),
                      onDownvote: () => postProvider.vote(postId: post.id, userId: auth.user?.uid ?? '', voteType: 'down'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                    );
                  },
                  childCount: postProvider.posts.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
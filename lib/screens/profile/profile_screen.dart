import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/task_model.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Profile', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _ProfileHeader(user: user)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.hintGrey,
              indicatorColor: AppColors.primary,
              labelStyle: AppTextStyles.labelMedium,
              tabs: const [
                Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Info'),
                Tab(icon: Icon(Icons.grid_on, size: 18), text: 'Posts'),
                Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Tasks'),
                Tab(icon: Icon(Icons.report_outlined, size: 18), text: 'Reports'),
                Tab(icon: Icon(Icons.card_giftcard_outlined, size: 18), text: 'Rewards'),
              ],
            )),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _InfoTab(user: user),
            _UserPostsTab(userId: user.uid),
            _UserTasksTab(userId: user.uid),
            _UserReportsTab(userId: user.uid),
            _RewardsTab(user: user),
          ],
        ),
      ),
    );
  }
}

// Profile header (unchanged, but uses displayName)
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.chipBg,
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary))
                  : null,
            ),
            Positioned(bottom: 0, right: 0,
              child: Container(width: 26, height: 26,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: AppColors.white, size: 14)),
            ),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.displayName, style: AppTextStyles.h2),
            Text('@${user.username}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            if (user.address != null)
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.hintGrey),
                const SizedBox(width: 3),
                Text(user.address!, style: AppTextStyles.bodySmall),
              ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(20)),
              child: Text('Lvl 2 | ${user.level}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ])),
          Column(children: [
            Text('${user.points}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text('Impact\nPower', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey), textAlign: TextAlign.center),
          ]),
        ]),
        const SizedBox(height: 16),
        LinearPercentIndicator(
          lineHeight: 10, percent: (user.levelProgress / 100).clamp(0.0, 1.0),
          backgroundColor: AppColors.borderGrey,
          progressColor: AppColors.primary,
          barRadius: const Radius.circular(5), padding: EdgeInsets.zero,
          trailing: Padding(padding: const EdgeInsets.only(left: 8),
            child: Text('${user.levelProgress}%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 4),
        const Text('Level Progress', style: AppTextStyles.bodySmall),
      ]),
    );
  }
}

// Info tab with editable fields
class _InfoTab extends StatefulWidget {
  final UserModel user;
  const _InfoTab({required this.user});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'New $field')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newValue != null && newValue != currentValue) {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({field: newValue});
      await context.read<AuthProvider>().refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('User Details', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        _EditableField(label: 'First Name', value: user.firstName, icon: Icons.person_outline, onEdit: () => _editField('firstName', user.firstName)),
        _EditableField(label: 'Last Name', value: user.lastName, icon: Icons.person_outline, onEdit: () => _editField('lastName', user.lastName)),
        _EditableField(label: 'Username', value: '@${user.username}', icon: Icons.alternate_email, onEdit: () => _editField('username', user.username)),
        _EditableField(label: 'Address', value: user.address ?? '—', icon: Icons.location_on_outlined, onEdit: () => _editField('address', user.address ?? '')),
        _EditableField(label: 'Email', value: user.email, icon: Icons.email_outlined, onEdit: () => _editField('email', user.email)),
        _EditableField(label: 'Phone Number', value: user.phoneNumber ?? '—', icon: Icons.phone_outlined, onEdit: () => _editField('phoneNumber', user.phoneNumber ?? '')),
        const _EditableField(label: 'Password', value: '••••••••', icon: Icons.lock_outline, isPassword: true),
        const SizedBox(height: 8),
        _ChipListField(label: 'Skills', values: user.skills),
        const SizedBox(height: 12),
        _ChipListField(label: 'Preferred Tasks', values: user.preferredTasks),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Referral code', style: AppTextStyles.inputLabel.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              const Spacer(),
              GestureDetector(onTap: () {}, child: const Icon(Icons.copy, color: AppColors.white, size: 18)),
            ]),
            const SizedBox(height: 6),
            Text(user.referralCode ?? '—', style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: 3)),
            const SizedBox(height: 6),
            Text('* Invite a friend and earn 100 points each when they sign up with your code.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Achievements', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _AchievementBadge(icon: Icons.emoji_events, label: 'Complete 50\ntasks', earned: user.jobsFinished >= 50),
          _AchievementBadge(icon: Icons.emoji_events, label: 'Complete 20\ntasks', earned: user.jobsFinished >= 20),
          _AchievementBadge(icon: Icons.emoji_events, label: 'Complete 5\ntasks', earned: user.jobsFinished >= 5),
        ]),
        const SizedBox(height: 24),
        const Text('Stats', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        _StatRow(label: 'Jobs Taken', value: user.jobsTaken.toString()),
        const Divider(color: AppColors.borderGrey),
        _StatRow(label: 'Jobs Finished', value: user.jobsFinished.toString()),
        const Divider(color: AppColors.borderGrey),
        _StatRow(label: 'Date Joined', value: '${user.dateJoined.day}/${user.dateJoined.month}/${user.dateJoined.year}'),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label; final String value; final IconData icon; final bool isPassword; final VoidCallback? onEdit;
  const _EditableField({required this.label, required this.value, required this.icon, this.isPassword = false, this.onEdit});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium),
      ])),
      if (onEdit != null)
        GestureDetector(onTap: onEdit, child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18)),
    ]),
  );
}

class _ChipListField extends StatelessWidget {
  final String label; final List<String> values;
  const _ChipListField({required this.label, required this.values});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: AppTextStyles.inputLabel),
      const Spacer(),
      const Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
    ]),
    const SizedBox(height: 6),
    if (values.isEmpty)
      const Text('Not set', style: AppTextStyles.bodySmall)
    else
      Wrap(spacing: 6, runSpacing: 4, children: values.map((v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
        child: Text(v, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
      )).toList()),
  ]);
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon; final String label; final bool earned;
  const _AchievementBadge({required this.icon, required this.label, required this.earned});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: earned ? const Color(0xFFFFF8E1) : AppColors.lightGrey,
        shape: BoxShape.circle,
        border: Border.all(color: earned ? const Color(0xFFFFB300) : AppColors.borderGrey, width: 2),
      ),
      child: Icon(icon, color: earned ? const Color(0xFFFFB300) : AppColors.hintGrey, size: 36),
    ),
    const SizedBox(height: 6),
    Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: earned ? AppColors.textDark : AppColors.hintGrey), textAlign: TextAlign.center),
  ]);
}

class _StatRow extends StatelessWidget {
  final String label; final String value;
  const _StatRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Text(label, style: AppTextStyles.bodyMedium),
      const Spacer(),
      Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
    ]),
  );
}

// Tabs: Posts, Tasks, Reports, Rewards
class _UserPostsTab extends StatelessWidget {
  final String userId;
  const _UserPostsTab({required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: PostService().getPostsByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.grid_on_outlined, size: 64, color: AppColors.borderGrey),
            SizedBox(height: 12),
            Text('No posts yet', style: AppTextStyles.bodySmall),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: posts.length,
          itemBuilder: (context, i) => PostCard(
            post: posts[i],
            currentUserId: userId,
            userVote: null,
            onUpvote: () {},
            onDownvote: () {},
          ),
        );
      },
    );
  }
}

class _UserTasksTab extends StatelessWidget {
  final String userId;
  const _UserTasksTab({required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: FirebaseFirestore.instance.collection('tasks')
          .where('acceptedBy', isEqualTo: userId)
          .snapshots()
          .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.borderGrey),
            SizedBox(height: 12),
            Text('No tasks taken', style: AppTextStyles.bodySmall),
          ]));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(tasks[i].title, style: AppTextStyles.bodyMedium),
            subtitle: Text('Status: ${tasks[i].status.name}', style: AppTextStyles.bodySmall),
            trailing: Text('${tasks[i].points} pts', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
        );
      },
    );
  }
}

class _UserReportsTab extends StatelessWidget {
  final String userId;
  const _UserReportsTab({required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportModel>>(
      stream: FirebaseFirestore.instance.collection('reports')
          .where('reportedBy', isEqualTo: userId)
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.report_outlined, size: 64, color: AppColors.borderGrey),
            SizedBox(height: 12),
            Text('No reports submitted', style: AppTextStyles.bodySmall),
          ]));
        }
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(reports[i].title, style: AppTextStyles.bodyMedium),
            subtitle: Text('${reports[i].hazardSubcategory} • ${reports[i].status.name}', style: AppTextStyles.bodySmall),
          ),
        );
      },
    );
  }
}

class _RewardsTab extends StatelessWidget {
  final UserModel user;
  const _RewardsTab({required this.user});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Badges Earned', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        if (user.badges.isEmpty)
          const Text('No badges yet. Complete tasks to earn badges!', style: AppTextStyles.bodySmall)
        else
          Wrap(spacing: 12, children: user.badges.map((b) => Chip(label: Text(b))).toList()),
        const SizedBox(height: 24),
        const Text('Points History', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        // Placeholder – you can implement a Firestore subcollection for points history
        const Text('Coming soon', style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppColors.white, child: tabBar);
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}

// ─── Post Tab ────────────────────────────────────────────

class _UserPostsTabState extends State<_UserPostsTab> {
  late Stream<List<PostModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PostService().getPostsByUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const _EmptyTab(
            label: 'No posts yet',
            icon: Icons.grid_on_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            return PostCard(
              post: post,
              currentUserId: widget.userId,
              userVote: null,
              onUpvote: () {},
              onDownvote: () {},
            );
          },
        );
      },
    );
  }
}
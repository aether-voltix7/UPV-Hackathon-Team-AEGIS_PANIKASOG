import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/prohibited_keywords.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/task_model.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../services/user_progress_service.dart';

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

  Future<void> _updateAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    if (!mounted) return; // ADDED
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading...'), backgroundColor: AppColors.primary),
    );

    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
      await ref.putFile(File(file.path));
      if (!mounted) return; // ADDED
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'avatarUrl': url});
      if (!mounted) return; // ADDED
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return; // ADDED
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
          SliverToBoxAdapter(child: _ProfileHeader(user: user, onAvatarTap: () => _updateAvatar(context))),
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

// Profile header with avatar upload callback
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAvatarTap;
  const _ProfileHeader({required this.user, this.onAvatarTap});

  int _nextLevelExp(int exp) {
    for (int i = 0; i < LevelSystem.levels.length - 1; i++) {
      if (exp < LevelSystem.levels[i + 1].expRequired) {
        return LevelSystem.levels[i + 1].expRequired;
      }
    }
    return LevelSystem.levels.last.expRequired;
  }

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
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: AppColors.white, size: 14),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${user.firstName} ${user.lastName}', style: AppTextStyles.h2),
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
              child: Text('Lvl ${LevelSystem.getLevelIndex(user.exp) + 1} | ${user.level}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ])),
          Column(children: [
            Text('${user.points}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text('Impact\nPower', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey), textAlign: TextAlign.center),
          ]),
        ]),
        const SizedBox(height: 16),

        // Level + EXP display
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.level, style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: (user.levelProgress / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.borderGrey,
              progressColor: AppColors.primary,
              barRadius: const Radius.circular(5),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            Text(
              '${user.exp} / ${_nextLevelExp(user.exp)} EXP',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
            ),
          ])),
        ]),
        const SizedBox(height: 12),

        // Share / stats row
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text('Tap to share or view Rewards/Tasks/Reports →',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        ),
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
  String _filterText(String text) {
    String result = text;
    for (String keyword in prohibitedKeywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    return result;
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          onChanged: (value) {
            String filtered = _filterText(value);
            if (filtered != value) {
              controller.text = filtered;
              controller.selection = TextSelection.collapsed(offset: filtered.length);
            }
          },
          decoration: InputDecoration(hintText: 'New $field'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // For username, check availability
              if (field == 'username') {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
                  return;
                }
                try {
                  final existing = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: trimmed)
                      .get();
                  if (existing.docs.isNotEmpty && existing.docs.first.id != widget.user.uid) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username already taken')));
                    return;
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  return;
                }
              }
              if (mounted) Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newValue != null && newValue != currentValue && mounted) {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({field: newValue});
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$field updated!')));
      }
    }
  }

  Future<void> _editListField(String field, List<String> currentList) async {
    final controller = TextEditingController();
    final items = List<String>.from(currentList);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text('Edit $field'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    String filtered = _filterText(value);
                    if (filtered != value) {
                      controller.text = filtered;
                      controller.selection = TextSelection.collapsed(offset: filtered.length);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Add new item',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (controller.text.isNotEmpty && !items.contains(controller.text.trim())) {
                          setState(() => items.add(controller.text.trim()));
                          controller.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No items added'))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: items.map((item) => Chip(
                            label: Text(item),
                            onDeleted: () => setState(() => items.remove(item)),
                          )).toList(),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, items), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != null && result != currentList && mounted) {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({field: result});
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$field updated!')));
      }
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
        _EditableChipListField(
          label: 'Skills',
          values: user.skills,
          onEdit: () => _editListField('skills', user.skills),
        ),
        const SizedBox(height: 12),
        _EditableChipListField(
          label: 'Preferred Tasks',
          values: user.preferredTasks,
          onEdit: () => _editListField('preferredTasks', user.preferredTasks),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Referral code', style: AppTextStyles.inputLabel.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (user.referralCode != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied: ${user.referralCode}')),
                    );
                  }
                },
                child: const Icon(Icons.copy, color: AppColors.white, size: 18),
              ),
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
    Text(label, style: AppTextStyles.inputLabel),
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

class _EditableChipListField extends StatelessWidget {
  final String label;
  final List<String> values;
  final VoidCallback onEdit;
  const _EditableChipListField({required this.label, required this.values, required this.onEdit});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: AppTextStyles.inputLabel),
      const Spacer(),
      GestureDetector(onTap: onEdit, child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 16)),
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

// ─── Posts tab ─────────────────────────────────────────────────────────────
class _UserPostsTab extends StatefulWidget {
  final String userId;
  const _UserPostsTab({required this.userId});

  @override
  State<_UserPostsTab> createState() => _UserPostsTabState();
}

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

class _EmptyTab extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptyTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.borderGrey),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _UserTasksTab extends StatelessWidget {
  final String userId;
  const _UserTasksTab({required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('status', isEqualTo: TaskStatus.verified.name)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => TaskModel.fromFirestore(d))
              .where((task) => task.isAcceptedBy(userId))
              .toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return const _EmptyTab(label: 'No verified tasks yet', icon: Icons.verified_outlined);
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(tasks[i].title, style: AppTextStyles.bodyMedium),
            subtitle: Text(
              'Verified • ${tasks[i].barangay}, ${tasks[i].city}',
              style: AppTextStyles.bodySmall,
            ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.hintGrey, size: 48),
                const SizedBox(height: 12),
                Text('Error loading reports', style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Text(snapshot.error.toString(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.hintGrey, fontSize: 10)),
              ],
            ),
          );
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return const _EmptyTab(label: 'No reports submitted', icon: Icons.report_outlined);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: reports.length,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(reports[i].title, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(reports[i].status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reports[i].status.name.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${reports[i].hazardSubcategory} • ${reports[i].barangay}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.verified:
        return AppColors.success;
      case ReportStatus.resolved:
        return const Color(0xFF2196F3);
      case ReportStatus.dismissed:
        return AppColors.hintGrey;
      case ReportStatus.pending:
      default:
        return AppColors.primary;
    }
  }
}

class _RewardsTab extends StatelessWidget {
  final UserModel user;
  const _RewardsTab({required this.user});

  Map<String, String> _getBadgeIcon(String badgeId) {
    const iconMap = {
      'first_task': ('🎯', 'First Responder'),
      'five_tasks': ('🤝', 'Helping Hand'),
      'twenty_tasks': ('⭐', 'Dedicated Volunteer'),
      'fifty_tasks': ('🏆', 'Community Hero'),
      'hundred_tasks': ('👑', 'Legendary Responder'),
      'level_3': ('🌟', 'Rising Star'),
      'level_5': ('🔥', 'Elite Volunteer'),
      'level_8': ('💎', 'Champion'),
      'points_500': ('💰', 'Point Collector'),
      'points_1000': ('💎', 'Point Master'),
    };
    final (icon, label) = iconMap[badgeId] ?? ('🏅', 'Badge');
    return {'icon': icon, 'label': label};
  }

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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: user.badges.map((badgeId) {
              final badgeInfo = _getBadgeIcon(badgeId);
              return Chip(
                avatar: Text(badgeInfo['icon']!, style: const TextStyle(fontSize: 18)),
                label: Text(badgeInfo['label']!),
                backgroundColor: AppColors.chipBg,
                labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
        const Text('Partner Merchants & Rewards', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        _MerchantRewardCard(
          merchantName: 'Jollibee',
          reward: 'Free Chicken Sandwich',
          points: 150,
          icon: '🍗',
        ),
        const SizedBox(height: 10),
        _MerchantRewardCard(
          merchantName: 'SM Malls',
          reward: '₱500 Gift Card',
          points: 500,
          icon: '🛍️',
        ),
        const SizedBox(height: 10),
        _MerchantRewardCard(
          merchantName: 'Caltex',
          reward: '2L Free Gas',
          points: 300,
          icon: '⛽',
        ),
        const SizedBox(height: 10),
        _MerchantRewardCard(
          merchantName: 'Pharmacy',
          reward: 'First Aid Kit',
          points: 200,
          icon: '🏥',
        ),
      ],
    );
  }
}

class _MerchantRewardCard extends StatelessWidget {
  final String merchantName;
  final String reward;
  final int points;
  final String icon;

  const _MerchantRewardCard({
    required this.merchantName,
    required this.reward,
    required this.points,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchantName, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(reward, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(8)),
            child: Text('$points pts', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import 'task_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

IconData _categoryIcon(TaskCategory cat) {
  switch (cat) {
    case TaskCategory.medicalAssistance:
      return Icons.medical_services_outlined;
    case TaskCategory.cleanupRecovery:
      return Icons.cleaning_services_outlined;
    case TaskCategory.reliefDistribution:
      return Icons.volunteer_activism;
    case TaskCategory.preparedness:
      return Icons.shield_outlined;
    default:
      return Icons.assignment_outlined;
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      final user = context.read<AuthProvider>().user;
      if (user != null) provider.setCurrentUser(user.uid);
      provider.loadTasks(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final currentUserId = context.read<AuthProvider>().user?.uid;
    final myTasks = provider.myTasks.where((t) => t.acceptedBy == currentUserId).toList();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUserId != null
                  ? NetworkImage(context.read<AuthProvider>().user?.avatarUrl ?? 'https://via.placeholder.com/150')
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 0, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tasks',
                        style: TextStyle(
                          fontFamily: 'Onest',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF520052),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        // Tablet: side-by-side view
                        return Row(
                          children: [
                            Expanded(
                              child: _TaskListView(
                                tasks: provider.openTasks,
                                emptyMsg: 'No available tasks right now.',
                              ),
                            ),
                            Expanded(
                              child: Container(
                                color: AppColors.white,
                                child: _TaskListView(
                                  tasks: myTasks,
                                  emptyMsg: 'You have not accepted any tasks yet.',
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      // Mobile: tabbed view
                      return Column(
                        children: [
                          TabBar(
                            controller: _tabs,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.hintGrey,
                            indicatorColor: AppColors.primary,
                            labelStyle: AppTextStyles.labelMedium,
                            tabs: [
                              Tab(text: 'Available (${provider.openTasks.length})'),
                              Tab(text: 'My Tasks (${myTasks.length})'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _TaskListView(
                                  tasks: provider.openTasks,
                                  emptyMsg: 'No available tasks right now.',
                                ),
                                _TaskListView(
                                  tasks: myTasks,
                                  emptyMsg: 'You have not accepted any tasks yet.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  final List<TaskModel> tasks;
  final String emptyMsg;

  const _TaskListView({
    required this.tasks,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: AppColors.borderGrey),
            const SizedBox(height: 12),
            Text(emptyMsg, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<TaskProvider>().loadTasks(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isUrgent = task.category == TaskCategory.medicalAssistance;

          if (isUrgent) {
            return Column(
              children: [
                // Urgent header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF88061E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'URGENT',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Urgent info section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7EC),
                    border: Border.all(color: const Color(0xFF88061E), width: 1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'This task involves: ',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                          children: [
                            TextSpan(
                              text: 'injured people',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          text: 'This task is also verified and officially tagged as urgent by: ',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                          children: [
                            TextSpan(
                              text: 'IloiloCityGovt',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Task card
                TaskCard(
                  task: task,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  ),
                  isUrgent: true,
                ),
                const SizedBox(height: 16),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(task: task),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final bool isUrgent;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isUrgent = false,
  });

  String _postedAgoShort(DateTime date) {
    final diff = DateTime.now().difference(date).abs();
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final isEnded = DateTime.now().isAfter(task.scheduledEnd);

    return GestureDetector(
      onTap: isEnded ? null : onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: isUrgent ? Radius.zero : const Radius.circular(12),
            topRight: isUrgent ? Radius.zero : const Radius.circular(12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
          border: Border.all(
            color: isUrgent ? const Color(0xFF88061E) : const Color(0xFFDF0B33),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 61,
                  alignment: Alignment.center,
                  child: Icon(
                    _categoryIcon(task.category),
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTextStyles.h2.copyWith(
                      color: const Color(0xFF520052),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Location and time chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _DetailMetaChip(
                  icon: Icons.location_on,
                  text: '${task.barangay}, ${task.city}',
                ),
                _DetailMetaChip(
                  icon: Icons.access_time_filled,
                  text: 'Posted ${_postedAgoShort(task.scheduledStart)}',
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(label: task.categoryLabel),
                ...task.tags.take(2).map((t) => _TagChip(label: t)),
                if (task.tags.length > 2) _TagChip(label: '+${task.tags.length - 2}'),
              ],
            ),
            const SizedBox(height: 8),
            // Points
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.primary, size: 24),
                const SizedBox(width: 4),
                Text(
                  '${task.points} points',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Author
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFF947FFF),
                  child: Text(
                    _initials(task.createdBy),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  task.createdBy.isEmpty ? 'Task Organizer' : task.createdBy,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              task.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDark,
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Volunteers needed with progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${task.volunteersAccepted}/${task.volunteersNeeded} volunteers',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.volunteersNeeded > 0
                        ? task.volunteersAccepted / task.volunteersNeeded
                        : 0,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF947FFF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Date and time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy • h:mma').format(task.scheduledStart),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: isEnded ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnded ? Colors.grey[400] : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: Text(
                  isEnded ? 'Task Ended' : 'View Task Details >',
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    return (parts[0][0] + (parts.length > 1 ? parts[1][0] : '')).toUpperCase();
  }
}

class _DetailMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailMetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      );
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11)),
      );
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.urgent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.urgent, width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.urgent, size: 11),
          const SizedBox(width: 3),
          Text('URGENT', style: AppTextStyles.bodySmall.copyWith(color: AppColors.urgent, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
        ]),
      );
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg; String label;
    switch (status) {
      case TaskStatus.accepted: bg = const Color(0xFFE3F2FD); label = 'Accepted'; break;
      case TaskStatus.inProgress: bg = const Color(0xFFFFF3E0); label = 'In Progress'; break;
      case TaskStatus.completed: bg = const Color(0xFFE8F5E9); label = 'Completed'; break;
      case TaskStatus.verified: bg = const Color(0xFFE8F5E9); label = 'Verified ✓'; break;
      default: return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  const _TagChip({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECF3),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary, fontSize: 12)),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 13, color: AppColors.primary)),
            ],
          ]),
        ),
      );
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w500)),
      ]);
}

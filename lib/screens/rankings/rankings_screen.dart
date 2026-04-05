import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/leaderboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/leaderboard_service.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});
  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final LeaderboardService _service = LeaderboardService();

  bool _loading = true;
  List<LeaderboardEntry> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      List<LeaderboardEntry> entries;
      switch (_tabs.index) {
        case 0:
          entries = await _service.getWeeklyLeaderboard();
          break;
        case 1:
          entries = await _service.getMonthlyLeaderboard();
          break;
        default:
          entries = await _service.getAllTimeLeaderboard();
      }
      // Merge with mock data if real data is empty
      if (entries.isEmpty) {
        entries = _tabs.index == 0
            ? LeaderboardEntry.mockDaily
            : LeaderboardEntry.mockMonthly;
      }
      setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      print('Leaderboard error: $e');
      setState(() {
        _error = 'Failed to load leaderboard.';
        _entries = LeaderboardEntry.mockDaily; // fallback
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.leaderboard, color: AppColors.white, size: 32),
                    const SizedBox(height: 6),
                    const Text('Leaderboard',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
                    const SizedBox(height: 4),
                    Text('Top volunteers in your area',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                  ]),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.white,
              indicatorWeight: 3,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
                Tab(text: 'All Time'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: AppColors.hintGrey, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Retry', style: AppTextStyles.labelMedium),
                    ),
                  ]))
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // ── Podium (top 3) ──────────────────────────────
                        if (_entries.length >= 3)
                          _Podium(entries: _entries.take(3).toList()),
                        const SizedBox(height: 8),

                        // ── Ranked list (4+) ────────────────────────────
                        if (_entries.length > 3)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: _entries
                                  .skip(3)
                                  .map((e) => _RankRow(
                                        entry: e,
                                        isCurrentUser: e.userId == (currentUser?.uid ?? ''),
                                      ))
                                  .toList(),
                            ),
                          ),

                        // ── Empty state ─────────────────────────────────
                        if (_entries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(children: [
                              Icon(Icons.leaderboard_outlined, size: 64, color: AppColors.borderGrey),
                              SizedBox(height: 12),
                              Text('No data yet for this period', style: AppTextStyles.bodySmall),
                            ]),
                          ),

                        // ── Current user if not in top list ─────────────
                        if (currentUser != null &&
                            _entries.isNotEmpty &&
                            !_entries.any((e) => e.userId == currentUser.uid))
                          _CurrentUserCard(user: currentUser),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ─── Podium ────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries[0], second = entries[1], third = entries[2];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PodiumSlot(entry: second, podiumHeight: 80, crownColor: const Color(0xFFC0C0C0), medalLabel: '2'),
          _PodiumSlot(entry: first, podiumHeight: 110, crownColor: const Color(0xFFFFD700), medalLabel: '1', isFirst: true),
          _PodiumSlot(entry: third, podiumHeight: 60, crownColor: const Color(0xFFCD7F32), medalLabel: '3'),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double podiumHeight;
  final Color crownColor;
  final String medalLabel;
  final bool isFirst;

  const _PodiumSlot({
    required this.entry,
    required this.podiumHeight,
    required this.crownColor,
    required this.medalLabel,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.emoji_events, color: crownColor, size: isFirst ? 32 : 24),
      const SizedBox(height: 4),
      Stack(alignment: Alignment.bottomRight, children: [
        CircleAvatar(
          radius: isFirst ? 36 : 28,
          backgroundColor: AppColors.chipBg,
          backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
          child: entry.avatarUrl == null
              ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isFirst ? 24 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ))
              : null,
        ),
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: crownColor, shape: BoxShape.circle),
          child: Center(
            child: Text(medalLabel,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      Text(entry.username,
          style: AppTextStyles.labelMedium.copyWith(fontSize: isFirst ? 13 : 11),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
      Text('${entry.points} pts',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        width: isFirst ? 80 : 64,
        height: podiumHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [crownColor.withValues(alpha: 0.7), crownColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: Text('${entry.jobsFinished}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
        ),
      ),
    ]);
  }
}

// ─── Rank row (4+) ─────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const _RankRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.chipBg : AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.5))),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text('#${entry.rank}',
              style: AppTextStyles.h3.copyWith(color: AppColors.hintGrey)),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.lightGrey,
          backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
          child: entry.avatarUrl == null
              ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(entry.username,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            if (isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('You',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: AppColors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          Text('${entry.barangay}, ${entry.city}', style: AppTextStyles.bodySmall),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${entry.points}',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          const Text('pts', style: AppTextStyles.bodySmall),
        ]),
      ]),
    );
  }
}

// ─── Current user card ─────────────────────────────────────────────────────────
class _CurrentUserCard extends StatelessWidget {
  final dynamic user;
  const _CurrentUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary,
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.username,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text('Not in top rankings yet',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${user.points}',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          const Text('pts', style: AppTextStyles.bodySmall),
        ]),
      ]),
    );
  }
}
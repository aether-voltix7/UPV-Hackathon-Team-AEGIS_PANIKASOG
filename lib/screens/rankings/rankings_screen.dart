import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/text_styles.dart';
import '../../models/leaderboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/app_logo.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});
  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  static const Color _figmaPurple = Color(0xFF520052);
  static const Color _primaryGradientStart = Color(0xFFDF0B33);
  static const Color _primaryGradientEnd = Color(0xFFAB0857);

  final LeaderboardService _service = LeaderboardService();

  bool _loading = true;
  List<LeaderboardEntry> _entries = [];
  String? _error;
  bool _isWeekly = true;
  String _selectedFilter = 'All'; // 'All', 'Community', 'Individual'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      List<LeaderboardEntry> entries;
      if (_isWeekly) {
        entries = await _service.getWeeklyLeaderboard();
      } else {
        entries = await _service.getMonthlyLeaderboard();
      }
      // Merge with mock data if real data is empty
      if (entries.isEmpty) {
        entries = _isWeekly
            ? LeaderboardEntry.mockDaily
            : LeaderboardEntry.mockMonthly;
      }
      setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      debugPrint('Leaderboard error: $e');
      setState(() {
        _error = 'Failed to load leaderboard.';
        _entries = LeaderboardEntry.mockDaily; // fallback
        _loading = false;
      });
    }
  }

  void _toggleTimeframe(bool isWeekly) {
    if (_isWeekly != isWeekly) {
      setState(() => _isWeekly = isWeekly);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFFCF5F7),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUser?.avatarUrl != null
                  ? NetworkImage(currentUser!.avatarUrl!)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Icon(Icons.settings, color: Colors.black87, size: 26),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _figmaPurple))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _figmaPurple,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _figmaPurple,
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ── Leaderboard Title ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 16, 0, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Leaderboard',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: _figmaPurple,
                            ),
                          ),
                        ),
                      ),
                      // ── Toggle Buttons: Weekly/Monthly ──────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(29, 24, 29, 0),
                        child: _buildToggleButtons(),
                      ),
                      // ── Top 1-3 Section ─────────────────────────────
                      if (_entries.length >= 3)
                        _buildTopThreePodium(),
                      // ── Filter Chips ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(29, 24, 29, 0),
                        child: _buildFilterChips(),
                      ),
                      // ── "Top 1-3" Label ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(29, 20, 29, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Top 1-3',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _figmaPurple,
                            ),
                          ),
                        ),
                      ),
                      // ── Leaderboard List ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(29, 16, 29, 32),
                        child: Column(
                          children: _entries
                              .asMap()
                              .entries
                              .map((e) {
                                final entry = e.value;
                                final isCurrentUser = entry.userId == currentUserId;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildLeaderboardRow(entry, currentUserId, isCurrentUser),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryGradientStart, _primaryGradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleTimeframe(true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isWeekly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Weekly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Onest',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isWeekly ? _primaryGradientEnd : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleTimeframe(false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isWeekly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Onest',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: !_isWeekly ? _primaryGradientEnd : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThreePodium() {
    final entries = _entries.take(3).toList();
    // Reorder to show: 2nd, 1st, 3rd
    List<LeaderboardEntry> ordered = [];
    if (entries.isNotEmpty) ordered.add(entries[0]); // 1st
    if (entries.length >= 2) ordered.add(entries[1]); // 2nd
    if (entries.length >= 3) ordered.add(entries[2]); // 3rd

    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 16, 29, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd Place (Left)
          _buildPodiumCard(ordered[1], 2, 'gray'),
          const SizedBox(width: 16),
          // 1st Place (Center, tallest)
          _buildPodiumCard(ordered[0], 1, 'gold'),
          const SizedBox(width: 16),
          // 3rd Place (Right)
          _buildPodiumCard(ordered[2], 3, 'orange'),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(LeaderboardEntry entry, int rank, String color) {
    Color rankColor;
    Color borderColor;
    switch (color) {
      case 'gold':
        rankColor = const Color(0xFFFFD700);
        borderColor = _primaryGradientStart;
        break;
      case 'gray':
        rankColor = const Color(0xFFC0C0C0);
        borderColor = const Color(0xFF949494);
        break;
      case 'orange':
        rankColor = const Color(0xFFFFB86A);
        borderColor = const Color(0xFFFF8C00);
        break;
      default:
        rankColor = Colors.grey;
        borderColor = Colors.grey;
    }

    final isFirst = rank == 1;

    return Expanded(
      child: Column(
        children: [
          // Crown badge
          Container(
            width: isFirst ? 24 : 20,
            height: isFirst ? 24 : 20,
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? const LinearGradient(
                      colors: [_primaryGradientStart, _primaryGradientEnd],
                    )
                  : null,
              color: rank != 1 ? rankColor : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isFirst ? 12 : 10,
                  fontWeight: FontWeight.bold,
                  color: rank == 1 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Profile image with border
          Container(
            width: isFirst ? 80 : 70,
            height: isFirst ? 80 : 70,
            padding: const EdgeInsets.all(3.78),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 3.78),
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(entry.avatarUrl ?? 'https://via.placeholder.com/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Name
          Text(
            entry.username,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _figmaPurple,
            ),
          ),
          // EXP
          Text(
            '${entry.points} EXP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF353535),
            ),
          ),
          const SizedBox(height: 8),
          // Rank box
          Container(
            width: isFirst ? 80 : 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? const LinearGradient(
                      colors: [Color(0xFFFCD916), Color(0xFFFFD700)],
                    )
                  : rank == 2
                      ? LinearGradient(
                          colors: [rankColor.withValues(alpha: 0.7), rankColor],
                        )
                      : LinearGradient(
                          colors: [rankColor.withValues(alpha: 0.7), rankColor],
                        ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isFirst ? 30 : 20,
                  fontWeight: FontWeight.bold,
                  color: rank == 1 ? const Color(0xFFDC143C) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('All', _selectedFilter == 'All'),
        const SizedBox(width: 5),
        _buildFilterChip('Community', _selectedFilter == 'Community'),
        const SizedBox(width: 5),
        _buildFilterChip('Individual', _selectedFilter == 'Individual'),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [_primaryGradientStart, _primaryGradientEnd],
                )
              : null,
          color: isActive ? null : Colors.white,
          border: Border.all(
            color: _primaryGradientStart,
            width: isActive ? 0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Onest',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, String currentUserId, bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17.86, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Color(0xFFFFF5F7) : Colors.white,
        border: Border.all(
          color: _primaryGradientStart,
          width: 1.889,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser ? _primaryGradientStart.withValues(alpha: 0.15) : Color(0x1A000000),
            blurRadius: isCurrentUser ? 10 : 6,
            offset: Offset(0, isCurrentUser ? 6 : 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentUser ? _primaryGradientStart : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                entry.rank.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white : const Color(0xFF4A5565),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15.97),
          // Profile image
          Container(
            width: 48.975,
            height: 48.975,
            decoration: BoxDecoration(
              border: Border.all(
                color: _primaryGradientStart,
                width: 1.889,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(entry.avatarUrl ?? 'https://via.placeholder.com/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15.97),
          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.username,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryGradientStart,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryGradientStart, _primaryGradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontFamily: 'Onest',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Level ${entry.level}',
                  style: TextStyle(
                    fontFamily: 'Onest',
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.points.toString(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryGradientStart,
                ),
              ),
              Text(
                'EXP',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF6A7282),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
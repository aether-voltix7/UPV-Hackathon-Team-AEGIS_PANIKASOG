import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches all users ranked by points (all-time)
  Future<List<LeaderboardEntry>> getAllTimeLeaderboard() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('points', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .asMap()
        .entries
        .map((e) => LeaderboardEntry.fromFirestore(e.value, e.key + 1))
        .toList();
  }

  /// Fetches users ranked by weekly points
  /// Requires a 'weeklyPoints' field updated each week, falls back to points
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard() async {
    // Get start of current week (Monday)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    // Query tasks completed this week to calculate weekly points
    final tasksSnapshot = await _db
        .collection('tasks')
        .where('status', isEqualTo: 'verified')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate))
        .get();

    // Aggregate points per user from completed tasks this week
    final Map<String, int> weeklyPoints = {};
    for (final doc in tasksSnapshot.docs) {
      final data = doc.data();
      final userId = data['acceptedBy'] as String?;
      final points = (data['points'] ?? 0) as int;
      if (userId != null) {
        weeklyPoints[userId] = (weeklyPoints[userId] ?? 0) + points;
      }
    }

    if (weeklyPoints.isEmpty) {
      // Fallback to all-time if no weekly data
      return getAllTimeLeaderboard();
    }

    // Fetch user details for those with weekly points
    final userIds = weeklyPoints.keys.toList();
    final List<LeaderboardEntry> entries = [];

    for (final userId in userIds) {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final d = userDoc.data()!;
        entries.add(LeaderboardEntry(
          userId: userId,
          username: d['username'] ?? '',
          avatarUrl: d['avatarUrl'],
          barangay: d['address']?.toString().split(',').first.trim() ?? '',
          city: d['address']?.toString().contains(',') == true
              ? d['address'].toString().split(',').last.trim()
              : 'Iloilo City',
          points: weeklyPoints[userId] ?? 0,
          jobsFinished: d['jobsFinished'] ?? 0,
          rank: 0,
        ));
      }
    }

    // Sort and assign ranks
    entries.sort((a, b) => b.points.compareTo(a.points));
    return entries
        .asMap()
        .entries
        .map((e) => LeaderboardEntry(
              userId: e.value.userId,
              username: e.value.username,
              avatarUrl: e.value.avatarUrl,
              barangay: e.value.barangay,
              city: e.value.city,
              points: e.value.points,
              jobsFinished: e.value.jobsFinished,
              rank: e.key + 1,
            ))
        .toList();
  }

  /// Fetches users ranked by monthly points
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final tasksSnapshot = await _db
        .collection('tasks')
        .where('status', isEqualTo: 'verified')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .get();

    final Map<String, int> monthlyPoints = {};
    for (final doc in tasksSnapshot.docs) {
      final data = doc.data();
      final userId = data['acceptedBy'] as String?;
      final points = (data['points'] ?? 0) as int;
      if (userId != null) {
        monthlyPoints[userId] = (monthlyPoints[userId] ?? 0) + points;
      }
    }

    if (monthlyPoints.isEmpty) {
      return getAllTimeLeaderboard();
    }

    final userIds = monthlyPoints.keys.toList();
    final List<LeaderboardEntry> entries = [];

    for (final userId in userIds) {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final d = userDoc.data()!;
        entries.add(LeaderboardEntry(
          userId: userId,
          username: d['username'] ?? '',
          avatarUrl: d['avatarUrl'],
          barangay: d['address']?.toString().split(',').first.trim() ?? '',
          city: d['address']?.toString().contains(',') == true
              ? d['address'].toString().split(',').last.trim()
              : 'Iloilo City',
          points: monthlyPoints[userId] ?? 0,
          jobsFinished: d['jobsFinished'] ?? 0,
          rank: 0,
        ));
      }
    }

    entries.sort((a, b) => b.points.compareTo(a.points));
    return entries
        .asMap()
        .entries
        .map((e) => LeaderboardEntry(
              userId: e.value.userId,
              username: e.value.username,
              avatarUrl: e.value.avatarUrl,
              barangay: e.value.barangay,
              city: e.value.city,
              points: e.value.points,
              jobsFinished: e.value.jobsFinished,
              rank: e.key + 1,
            ))
        .toList();
  }
}
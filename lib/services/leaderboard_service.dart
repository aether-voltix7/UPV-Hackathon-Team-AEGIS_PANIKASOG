import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Base query for leaderboard (reusable)
  Future<List<LeaderboardEntry>> _getLeaderboardByField(String field) async {
    final snapshot = await _db
        .collection('users')
        .orderBy(field, descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .asMap()
        .entries
        .map((e) => LeaderboardEntry.fromFirestore(e.value, e.key + 1))
        .toList();
  }

  /// All-time leaderboard (uses total points)
  Future<List<LeaderboardEntry>> getAllTimeLeaderboard() async {
    return _getLeaderboardByField('points');
  }

  /// Weekly leaderboard (TEMP: uses total points for consistency)
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard() async {
    return _getLeaderboardByField('points');
  }

  /// Monthly leaderboard (TEMP: uses total points for consistency)
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
    return _getLeaderboardByField('points');
  }
}
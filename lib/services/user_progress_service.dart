import 'package:cloud_firestore/cloud_firestore.dart';

/// ─── Level Thresholds ─────────────────────────────────────────────────────────
/// Each level requires this much total EXP to reach
class LevelSystem {
  static const levels = [
    (title: 'Community Member', expRequired: 0),
    (title: 'Neighborhood Helper', expRequired: 100),
    (title: 'Barangay Volunteer', expRequired: 300),
    (title: 'Community Guardian', expRequired: 600),
    (title: 'Disaster Responder', expRequired: 1000),
    (title: 'Emergency Leader', expRequired: 1500),
    (title: 'Community Hero', expRequired: 2200),
    (title: 'Disaster Champion', expRequired: 3000),
  ];

  /// Returns current level title based on total EXP
  static String getLevelTitle(int exp) {
    String title = levels.first.title;
    for (final level in levels) {
      if (exp >= level.expRequired) title = level.title;
    }
    return title;
  }

  /// Returns progress (0–100) toward next level
  static int getLevelProgress(int exp) {
    for (int i = 0; i < levels.length - 1; i++) {
      final current = levels[i].expRequired;
      final next = levels[i + 1].expRequired;
      if (exp >= current && exp < next) {
        return ((exp - current) / (next - current) * 100).round();
      }
    }
    return 100; // max level
  }

  /// Returns current level index (0-based)
  static int getLevelIndex(int exp) {
    int index = 0;
    for (int i = 0; i < levels.length; i++) {
      if (exp >= levels[i].expRequired) index = i;
    }
    return index;
  }
}

/// ─── Badge Definitions ────────────────────────────────────────────────────────
class BadgeSystem {
  static const badges = [
    (id: 'first_task', label: 'First Responder', desc: 'Complete your first task', icon: '🎯'),
    (id: 'five_tasks', label: 'Helping Hand', desc: 'Complete 5 tasks', icon: '🤝'),
    (id: 'twenty_tasks', label: 'Dedicated Volunteer', desc: 'Complete 20 tasks', icon: '⭐'),
    (id: 'fifty_tasks', label: 'Community Hero', desc: 'Complete 50 tasks', icon: '🏆'),
    (id: 'hundred_tasks', label: 'Legendary Responder', desc: 'Complete 100 tasks', icon: '👑'),
    (id: 'level_3', label: 'Rising Star', desc: 'Reach Barangay Volunteer', icon: '🌟'),
    (id: 'level_5', label: 'Elite Volunteer', desc: 'Reach Disaster Responder', icon: '🔥'),
    (id: 'level_8', label: 'Champion', desc: 'Reach Disaster Champion', icon: '💎'),
    (id: 'points_500', label: 'Point Collector', desc: 'Earn 500 points', icon: '💰'),
    (id: 'points_1000', label: 'Point Master', desc: 'Earn 1000 points', icon: '💎'),
  ];

  /// Returns list of badge IDs earned based on user stats
  static List<String> getEarnedBadges({
    required int jobsFinished,
    required int totalPoints,
    required int exp,
  }) {
    final earned = <String>[];
    final levelIndex = LevelSystem.getLevelIndex(exp);

    if (jobsFinished >= 1) earned.add('first_task');
    if (jobsFinished >= 5) earned.add('five_tasks');
    if (jobsFinished >= 20) earned.add('twenty_tasks');
    if (jobsFinished >= 50) earned.add('fifty_tasks');
    if (jobsFinished >= 100) earned.add('hundred_tasks');
    if (levelIndex >= 2) earned.add('level_3');
    if (levelIndex >= 4) earned.add('level_5');
    if (levelIndex >= 7) earned.add('level_8');
    if (totalPoints >= 500) earned.add('points_500');
    if (totalPoints >= 1000) earned.add('points_1000');

    return earned;
  }
}

/// ─── Reward Catalog ───────────────────────────────────────────────────────────
class RewardCatalog {
  static const rewards = [
    (id: 'reward_1', label: 'Free Merienda', desc: 'Redeem at partner stores', points: 100, icon: '🍱'),
    (id: 'reward_2', label: 'Panikasog T-Shirt', desc: 'Official volunteer shirt', points: 300, icon: '👕'),
    (id: 'reward_3', label: 'Grocery Pack', desc: 'Basic grocery items pack', points: 500, icon: '🛒'),
    (id: 'reward_4', label: 'Certificate of Recognition', desc: 'Official LGU certificate', points: 200, icon: '📜'),
    (id: 'reward_5', label: 'Emergency Kit', desc: 'Basic disaster prep kit', points: 800, icon: '🎒'),
  ];
}

/// ─── User Progress Service ────────────────────────────────────────────────────
class UserProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Called after task verification — awards points + EXP, updates level/badges
  Future<void> awardTaskCompletion({
    required String userId,
    required int pointsEarned,
    required int expEarned,
  }) async {
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(userRef);
      if (!doc.exists) return;

      final data = doc.data()!;
      final currentPoints = (data['points'] ?? 0) as int;
      final currentExp = (data['exp'] ?? 0) as int;
      final currentJobsFinished = (data['jobsFinished'] ?? 0) as int;

      final newPoints = currentPoints + pointsEarned;
      final newExp = currentExp + expEarned;
      final newJobsFinished = currentJobsFinished + 1;

      final newLevel = LevelSystem.getLevelTitle(newExp);
      final newLevelProgress = LevelSystem.getLevelProgress(newExp);
      final newBadges = BadgeSystem.getEarnedBadges(
        jobsFinished: newJobsFinished,
        totalPoints: newPoints,
        exp: newExp,
      );

      tx.update(userRef, {
        'points': newPoints,
        'exp': newExp,
        'jobsFinished': newJobsFinished,
        'level': newLevel,
        'levelProgress': newLevelProgress,
        'badges': newBadges,
      });
    });
  }

  /// Called when user accepts a task
  Future<void> incrementJobsTaken(String userId) async {
    await _db.collection('users').doc(userId).update({
      'jobsTaken': FieldValue.increment(1),
    });
  }

  /// Redeem a reward — deducts points
  Future<bool> redeemReward({
    required String userId,
    required String rewardId,
    required int pointsCost,
  }) async {
    final userRef = _db.collection('users').doc(userId);

    try {
      await _db.runTransaction((tx) async {
        final doc = await tx.get(userRef);
        if (!doc.exists) throw Exception('User not found');

        final currentPoints = (doc.data()!['points'] ?? 0) as int;
        if (currentPoints < pointsCost) throw Exception('Not enough points');

        tx.update(userRef, {
          'points': currentPoints - pointsCost,
        });

        // Log redemption
        final redemptionRef = _db.collection('redemptions').doc();
        tx.set(redemptionRef, {
          'userId': userId,
          'rewardId': rewardId,
          'pointsSpent': pointsCost,
          'redeemedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user's redemption history
  Future<List<Map<String, dynamic>>> getRedemptions(String userId) async {
    final snapshot = await _db
        .collection('redemptions')
        .where('userId', isEqualTo: userId)
        .orderBy('redeemedAt', descending: true)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String barangay;
  final String city;
  final int points;
  final int jobsFinished;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.barangay,
    required this.city,
    required this.points,
    required this.jobsFinished,
    required this.rank,
  });

  /// Calculate level from points (1000 EXP = 1 level, minimum level 1)
  int get level => (points ~/ 1000) + 1;

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc, int rank) {
    final d = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      userId: doc.id,
      username: d['username'] ?? '',
      avatarUrl: d['avatarUrl'],
      barangay: d['barangay'] ?? '',
      city: d['city'] ?? '',
      points: d['points'] ?? 0,
      jobsFinished: d['jobsFinished'] ?? 0,
      rank: rank,
    );
  }

  static List<LeaderboardEntry> get mockDaily => [
    const LeaderboardEntry(userId: 'u1', username: 'Glawen Baber', avatarUrl: null, barangay: 'Brgy. Rizal', city: 'Iloilo City', points: 1264, jobsFinished: 14, rank: 1),
    const LeaderboardEntry(userId: 'u2', username: 'Robert Lampong', avatarUrl: null, barangay: 'Brgy. Molo', city: 'Iloilo City', points: 1188, jobsFinished: 12, rank: 2),
    const LeaderboardEntry(userId: 'u3', username: 'Ghar Pagaduan', avatarUrl: null, barangay: 'Brgy. La Paz', city: 'Iloilo City', points: 1102, jobsFinished: 11, rank: 3),
    const LeaderboardEntry(userId: 'u4', username: 'Cris Duvmmd', avatarUrl: null, barangay: 'Brgy. Jaro', city: 'Iloilo City', points: 948, jobsFinished: 9, rank: 4),
    const LeaderboardEntry(userId: 'u5', username: 'Yuga Setora', avatarUrl: null, barangay: 'Brgy. Mandurriao', city: 'Iloilo City', points: 821, jobsFinished: 8, rank: 5),
  ];

  static List<LeaderboardEntry> get mockMonthly => [
    const LeaderboardEntry(userId: 'u2', username: 'Robert Lampong', avatarUrl: null, barangay: 'Brgy. Molo', city: 'Iloilo City', points: 8420, jobsFinished: 67, rank: 1),
    const LeaderboardEntry(userId: 'u1', username: 'Glawen Baber', avatarUrl: null, barangay: 'Brgy. Rizal', city: 'Iloilo City', points: 7903, jobsFinished: 62, rank: 2),
    const LeaderboardEntry(userId: 'u5', username: 'Yuga Setora', avatarUrl: null, barangay: 'Brgy. Mandurriao', city: 'Iloilo City', points: 6750, jobsFinished: 54, rank: 3),
    const LeaderboardEntry(userId: 'u3', username: 'Ghar Pagaduan', avatarUrl: null, barangay: 'Brgy. La Paz', city: 'Iloilo City', points: 5210, jobsFinished: 41, rank: 4),
    const LeaderboardEntry(userId: 'u4', username: 'Cris Duvmmd', avatarUrl: null, barangay: 'Brgy. Jaro', city: 'Iloilo City', points: 4820, jobsFinished: 38, rank: 5),
  ];
}

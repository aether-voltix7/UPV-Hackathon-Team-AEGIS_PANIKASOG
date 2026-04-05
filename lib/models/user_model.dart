import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String name;
  final String username;
  final String? address;
  final List<String> skills;
  final List<String> preferredTasks;
  final String? referralCode;
  final String? usedReferralCode;
  final int points;
  final int jobsTaken;
  final int jobsFinished;
  final String? avatarUrl;
  final String level;
  final int levelProgress; // 0–100
  final int exp;
  final DateTime dateJoined;
  final List<String> badges;

  const UserModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    required this.name,
    required this.username,
    this.address,
    this.skills = const [],
    this.preferredTasks = const [],
    this.referralCode,
    this.usedReferralCode,
    this.points = 0,
    this.jobsTaken = 0,
    this.jobsFinished = 0,
    this.avatarUrl,
    this.level = 'Community Member',
    this.levelProgress = 0,
    this.exp = 0,
    required this.dateJoined,
    this.badges = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      address: data['address'],
      skills: List<String>.from(data['skills'] ?? []),
      preferredTasks: List<String>.from(data['preferredTasks'] ?? []),
      referralCode: data['referralCode'],
      usedReferralCode: data['usedReferralCode'],
      points: data['points'] ?? 0,
      jobsTaken: data['jobsTaken'] ?? 0,
      jobsFinished: data['jobsFinished'] ?? 0,
      avatarUrl: data['avatarUrl'],
      level: data['level'] ?? 'Community Member',
      levelProgress: data['levelProgress'] ?? 0,
      exp: data['exp'] ?? 0,
      dateJoined: (data['dateJoined'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'username': username,
      'address': address,
      'skills': skills,
      'preferredTasks': preferredTasks,
      'referralCode': referralCode,
      'usedReferralCode': usedReferralCode,
      'points': points,
      'jobsTaken': jobsTaken,
      'jobsFinished': jobsFinished,
      'avatarUrl': avatarUrl,
      'level': level,
      'levelProgress': levelProgress,
      'exp': exp,
      'dateJoined': Timestamp.fromDate(dateJoined),
      'badges': badges,
    };
  }

  UserModel copyWith({
    String? email,
    String? phoneNumber,
    String? name,
    String? username,
    String? address,
    List<String>? skills,
    List<String>? preferredTasks,
    String? referralCode,
    String? usedReferralCode,
    int? points,
    int? jobsTaken,
    int? jobsFinished,
    String? avatarUrl,
    String? level,
    int? levelProgress,
    int? exp,
    List<String>? badges,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      username: username ?? this.username,
      address: address ?? this.address,
      skills: skills ?? this.skills,
      preferredTasks: preferredTasks ?? this.preferredTasks,
      referralCode: referralCode ?? this.referralCode,
      usedReferralCode: usedReferralCode ?? this.usedReferralCode,
      points: points ?? this.points,
      jobsTaken: jobsTaken ?? this.jobsTaken,
      jobsFinished: jobsFinished ?? this.jobsFinished,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      levelProgress: levelProgress ?? this.levelProgress,
      exp: exp ?? this.exp,
      dateJoined: dateJoined,
      badges: badges ?? this.badges,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, username: $username, points: $points)';
}

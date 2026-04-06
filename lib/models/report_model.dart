import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, verified, resolved, dismissed }

class HazardCategory {
  final String id;
  final String label;
  final String emoji;
  final List<String> subcategories;

  const HazardCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.subcategories,
  });

  static const List<HazardCategory> all = [
    HazardCategory(
        id: 'natural',
        label: 'Natural',
        emoji: '🌪️',
        subcategories: [
          'Typhoon / Storm',
          'Flood',
          'Storm Surge',
          'Drought',
          'Landslide',
        ]),
    HazardCategory(
        id: 'geological',
        label: 'Geological',
        emoji: '🌋',
        subcategories: [
          'Earthquake',
          'Volcanic Eruption',
          'Tsunami',
          'Ground Fissure',
          'Liquefaction',
        ]),
    HazardCategory(
        id: 'environmental',
        label: 'Environmental',
        emoji: '☣️',
        subcategories: [
          'Oil Spill',
          'Air Pollution',
          'Water Contamination',
          'Chemical Spill',
          'Wildfire',
        ]),
    HazardCategory(
        id: 'accidents_infrastructure',
        label: 'Accidents & Infrastructure Disruptions',
        emoji: '🏗️',
        subcategories: [
          'Power outage / Blackout',
          'Bridge collapse',
          'Dam failure',
        ]),
    HazardCategory(
        id: 'utility_service',
        label: 'Utility & Service Failures',
        emoji: '⚡',
        subcategories: [
          'Water supply interruption',
          'Telecommunication loss',
          'Gas leak',
          'Sewer / Drainage overflow',
        ]),
    HazardCategory(
        id: 'transportation',
        label: 'Transportation Accidents',
        emoji: '🚗',
        subcategories: [
          'Vehicle accident',
          'Road blockage',
          'Ship / Boat accident',
        ]),
    HazardCategory(
        id: 'human_made',
        label: 'Human-Generated Events',
        emoji: '⚠️',
        subcategories: [
          'Armed conflict',
          'Terrorism / Bomb threat',
          'Mass gathering incident',
          'Fire incident',
        ]),
  ];
}

class ReportModel {
  final String id;
  final String reportedBy;
  final String reporterUsername;
  final String? reporterAvatarUrl;
  final String title;
  final String description;
  final String hazardCategoryId;
  final String hazardSubcategory;
  final String barangay;
  final String city;
  final double? latitude;
  final double? longitude;
  final DateTime reportedAt;
  final ReportStatus status;
  final List<String> imageUrls;
  final int upvotes;

  const ReportModel({
    required this.id,
    required this.reportedBy,
    required this.reporterUsername,
    this.reporterAvatarUrl,
    required this.title,
    required this.description,
    required this.hazardCategoryId,
    required this.hazardSubcategory,
    required this.barangay,
    required this.city,
    this.latitude,
    this.longitude,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    this.imageUrls = const [],
    this.upvotes = 0,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reportedBy: d['reportedBy'] ?? '',
      reporterUsername: d['reporterUsername'] ?? '',
      reporterAvatarUrl: d['reporterAvatarUrl'],
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      hazardCategoryId: d['hazardCategoryId'] ?? '',
      hazardSubcategory: d['hazardSubcategory'] ?? '',
      barangay: d['barangay'] ?? '',
      city: d['city'] ?? '',
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      reportedAt: (d['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _statusFromString(d['status']),
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
      upvotes: d['upvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reportedBy': reportedBy,
        'reporterUsername': reporterUsername,
        'reporterAvatarUrl': reporterAvatarUrl,
        'title': title,
        'description': description,
        'hazardCategoryId': hazardCategoryId,
        'hazardSubcategory': hazardSubcategory,
        'barangay': barangay,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'reportedAt': Timestamp.fromDate(reportedAt),
        'status': status.name,
        'imageUrls': imageUrls,
        'upvotes': upvotes,
      };

  static ReportStatus _statusFromString(String? s) {
    switch (s) {
      case 'verified':
        return ReportStatus.verified;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  String get categoryLabel => HazardCategory.all
      .firstWhere((c) => c.id == hazardCategoryId,
          orElse: () => const HazardCategory(
              id: '', label: 'Unknown', emoji: '⚠️', subcategories: []))
      .label;

  static List<ReportModel> get mockReports => [
        ReportModel(
          id: 'report_1',
          reportedBy: 'uid_1',
          reporterUsername: 'juan_org',
          title: 'Flooded Road - Brgy. Rizal',
          description:
              'Main road completely flooded. Water level up to knee height. Vehicles cannot pass.',
          hazardCategoryId: 'natural',
          hazardSubcategory: 'Flood',
          barangay: 'Brgy. Rizal Pala-Pala I',
          city: 'Iloilo City',
          latitude: 10.6916,
          longitude: 122.5622,
          reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: ReportStatus.verified,
          upvotes: 34,
        ),
        ReportModel(
          id: 'report_2',
          reportedBy: 'uid_2',
          reporterUsername: 'maria_r',
          title: 'Power Outage - Brgy. Molo',
          description: 'No electricity since 6am. Affecting 3 blocks.',
          hazardCategoryId: 'utility_service',
          hazardSubcategory: 'Power outage / Blackout',
          barangay: 'Brgy. Poblacion Molo',
          city: 'Iloilo City',
          latitude: 10.6950,
          longitude: 122.5460,
          reportedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: ReportStatus.pending,
          upvotes: 12,
        ),
      ];
}

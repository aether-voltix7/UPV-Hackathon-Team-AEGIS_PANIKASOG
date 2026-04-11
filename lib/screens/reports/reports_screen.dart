import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  bool _mapExpanded = false;
  String _selectedFilter = 'All';
  String? _selectedReportId;

  static const List<String> _filters = [
    'All',
    'Pinned',
    'Verified',
    'Natural',
    'Man-made',
  ];

  Stream<List<ReportModel>> get _reportsStream => FirebaseFirestore.instance
      .collection('reports')
      .orderBy('reportedAt', descending: true)
      .snapshots()
      .map((snap) {
    final liveReports = snap.docs.map(ReportModel.fromFirestore).toList();
    return [...liveReports, ...ReportModel.mockReports];
  });

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
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
              backgroundImage:
                  NetworkImage(auth.user?.avatarUrl ?? 'https://via.placeholder.com/150'),
              backgroundColor: Colors.grey[300],
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 0, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reports',
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
            child: StreamBuilder<List<ReportModel>>(
              stream: _reportsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final reports = snapshot.data ?? [];
                final filtered = _applyFilters(reports);

                if (filtered.isNotEmpty &&
                    _selectedReportId != null &&
                    !filtered.any((r) => r.id == _selectedReportId)) {
                  _selectedReportId = filtered.first.id;
                }
                if (filtered.isEmpty) _selectedReportId = null;

                return _mapExpanded
                    ? _buildExpandedLayout(filtered)
                    : _buildDefaultLayout(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ReportModel> _applyFilters(List<ReportModel> reports) {
    final query = _searchController.text.trim().toLowerCase();
    return reports.where((report) {
      final matchesQuery = query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.description.toLowerCase().contains(query) ||
          report.hazardSubcategory.toLowerCase().contains(query) ||
          report.barangay.toLowerCase().contains(query) ||
          report.city.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      switch (_selectedFilter) {
        case 'Pinned':
          return report.upvotes >= 20;
        case 'Verified':
          return report.status == ReportStatus.verified;
        case 'Natural':
          return _isNaturalCategory(report.hazardCategoryId);
        case 'Man-made':
          return !_isNaturalCategory(report.hazardCategoryId);
        default:
          return true;
      }
    }).toList();
  }

  bool _isNaturalCategory(String categoryId) {
    return categoryId == 'natural' ||
        categoryId == 'geological' ||
        categoryId == 'environmental';
  }

  Widget _buildDefaultLayout(List<ReportModel> reports) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _SearchAndFilterBar(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          onTuneTap: () {},
        ),
        const SizedBox(height: 8),
        _FilterRow(
          selectedFilter: _selectedFilter,
          filters: _filters,
          onSelect: (value) => setState(() => _selectedFilter = value),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 180,
            child: Stack(
              children: [
                _ReportsMap(
                  reports: reports,
                  selectedReportId: _selectedReportId,
                  onMapCreated: (controller) => _mapController = controller,
                  onMarkerTap: (id) => setState(() => _selectedReportId = id),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _RoundMapButton(
                    icon: Icons.fullscreen,
                    onTap: () => setState(() => _mapExpanded = true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Reports',
          style: AppTextStyles.h2.copyWith(color: const Color(0xFF520052)),
        ),
        const SizedBox(height: 10),
        if (reports.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('No reports found.')),
          )
        else
          ...reports.map((report) => _ReportCard(
                report: report,
                selected: report.id == _selectedReportId,
                onTap: () => _focusReport(report),
              )),
      ],
    );
  }

  Widget _buildExpandedLayout(List<ReportModel> reports) {
    final bottomCards = reports.take(3).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: _ReportsMap(
            reports: reports,
            selectedReportId: _selectedReportId,
            onMapCreated: (controller) => _mapController = controller,
            onMarkerTap: (id) => setState(() => _selectedReportId = id),
            expanded: true,
          ),
        ),
        Positioned(
          right: 14,
          bottom: 324,
          child: _RoundMapButton(
            icon: Icons.fullscreen_exit,
            onTap: () => setState(() => _mapExpanded = false),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 336,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF5F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 80,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF520052).withValues(alpha: 0.23),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Reports',
                    style:
                        AppTextStyles.h2.copyWith(color: const Color(0xFF520052)),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchAndFilterBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onTuneTap: () {},
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FilterRow(
                    selectedFilter: _selectedFilter,
                    filters: _filters,
                    onSelect: (value) => setState(() => _selectedFilter = value),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: bottomCards.isEmpty
                        ? const [
                            SizedBox(height: 60),
                            Center(child: Text('No reports found.')),
                          ]
                        : bottomCards
                            .map((report) => _ReportCard(
                                  report: report,
                                  compact: true,
                                  selected: report.id == _selectedReportId,
                                  onTap: () => _focusReport(report),
                                ))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _focusReport(ReportModel report) async {
    setState(() => _selectedReportId = report.id);
    if (report.latitude != null && report.longitude != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(report.latitude!, report.longitude!), 15.3),
      );
    }
  }
}

class _ReportsMap extends StatelessWidget {
  final List<ReportModel> reports;
  final String? selectedReportId;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<String> onMarkerTap;
  final bool expanded;

  const _ReportsMap({
    required this.reports,
    required this.selectedReportId,
    required this.onMapCreated,
    required this.onMarkerTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final markers = reports
        .where((report) => report.latitude != null && report.longitude != null)
        .map((report) {
      final visual = _reportVisual(report);
      final isSelected = report.id == selectedReportId;
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.latitude!, report.longitude!),
        infoWindow: InfoWindow(
          title: report.title,
          snippet: '${report.barangay}, ${report.city}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueRose : visual.hue,
        ),
        onTap: () => onMarkerTap(report.id),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(10.7202, 122.5621),
        zoom: 12.8,
      ),
      markers: markers,
      onMapCreated: onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: !expanded,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.onTap,
    this.compact = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _reportVisual(report);
    final urgent = _isUrgentReport(report);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFDF0B33) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (urgent && !compact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF88061E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.priority_high, size: 10, color: AppColors.white),
                  SizedBox(width: 4),
                  Text(
                    'URGENT',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [visual.color, visual.colorDark]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(visual.icon, color: AppColors.white, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h3.copyWith(
                          color: const Color(0xFF520052),
                          fontSize: compact ? 16 : 18,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _StatusChip(
                              text: report.status == ReportStatus.verified
                                  ? 'Verified'
                                  : 'Pending',
                              verified: report.status == ReportStatus.verified,
                            ),
                            _TagChip(label: report.categoryLabel),
                            _TagChip(label: report.hazardSubcategory, compact: true),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${report.barangay}, ${report.city}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 11, color: AppColors.primary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    'Posted ${_postedAgo(report.reportedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ]),
              if (!compact) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TagChip(label: report.hazardSubcategory),
                    if (report.description.isNotEmpty)
                      _TagChip(label: 'Hazard'),
                    if (report.upvotes > 0)
                      _TagChip(label: '+${report.upvotes > 9 ? 1 : 0}'),
                  ],
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTuneTap;

  const _SearchAndFilterBar({
    required this.controller,
    required this.onChanged,
    required this.onTuneTap,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search reports...',
                hintStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTuneTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF510152), Color(0xFFA6029E)],
              ),
            ),
            child: const Icon(Icons.tune, size: 17, color: AppColors.white),
          ),
        ),
      ]);
}

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.filters,
    required this.selectedFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((label) {
            final selected = label == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: () => onSelect(label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
                          )
                        : null,
                    color: selected ? null : AppColors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: selected
                        ? null
                        : Border.all(color: const Color(0xFFDF0B33)),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected ? AppColors.white : AppColors.textDark,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool compact;

  const _TagChip({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textDark,
            fontSize: compact ? 9 : 10,
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String text;
  final bool verified;

  const _StatusChip({required this.text, required this.verified});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: verified ? const Color(0xFFE6F5EA) : const Color(0xFFFFF0E0),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: verified ? AppColors.success : AppColors.warning,
          ),
        ),
      );
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundMapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF510152), Color(0xFFA6029E)],
            ),
          ),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
      );
}

_ReportVisual _reportVisual(ReportModel report) {
  final source = '${report.hazardSubcategory} ${report.title}'.toLowerCase();

  if (source.contains('electric') ||
      source.contains('power') ||
      source.contains('blackout')) {
    return const _ReportVisual(
      icon: Icons.bolt,
      color: Color(0xFFF9C30C),
      colorDark: Color(0xFFDF0B33),
      hue: BitmapDescriptor.hueOrange,
    );
  }

  if (source.contains('flood') || source.contains('storm surge')) {
    return const _ReportVisual(
      icon: Icons.flood,
      color: Color(0xFF2A74EA),
      colorDark: Color(0xFF4D52D8),
      hue: BitmapDescriptor.hueAzure,
    );
  }

  if (source.contains('landslide') || source.contains('erosion')) {
    return const _ReportVisual(
      icon: Icons.layers,
      color: Color(0xFF0F9C63),
      colorDark: Color(0xFF0A6B45),
      hue: BitmapDescriptor.hueGreen,
    );
  }

  if (source.contains('fire')) {
    return const _ReportVisual(
      icon: Icons.local_fire_department,
      color: Color(0xFFFF8A00),
      colorDark: Color(0xFFDF0B33),
      hue: BitmapDescriptor.hueRed,
    );
  }

  return const _ReportVisual(
    icon: Icons.warning_amber,
    color: Color(0xFFA3049F),
    colorDark: Color(0xFF520052),
    hue: BitmapDescriptor.hueViolet,
  );
}

bool _isUrgentReport(ReportModel report) {
  final source = '${report.hazardSubcategory} ${report.title}'.toLowerCase();
  return source.contains('electric') || source.contains('electrocution');
}

String _postedAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min. ago';
  if (diff.inDays < 1) return '${diff.inHours} hr. ago';
  return DateFormat('MMM d').format(date);
}

class _ReportVisual {
  final IconData icon;
  final Color color;
  final Color colorDark;
  final double hue;

  const _ReportVisual({
    required this.icon,
    required this.color,
    required this.colorDark,
    required this.hue,
  });
}

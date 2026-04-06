import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _showMap = false;

  Stream<List<ReportModel>> get _reportsStream => FirebaseFirestore.instance
      .collection('reports')
      .orderBy('reportedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ReportModel.fromFirestore).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Reports', style: AppTextStyles.h2),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => setState(() => _showMap = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: !_showMap ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('List', style: AppTextStyles.bodySmall.copyWith(color: !_showMap ? AppColors.white : AppColors.hintGrey, fontWeight: FontWeight.w600)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showMap = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showMap ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Map', style: AppTextStyles.bodySmall.copyWith(color: _showMap ? AppColors.white : AppColors.hintGrey, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ],
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports yet.'));
          }
          return _showMap
              ? _MapView(reports: reports)
              : _ListView(reports: reports);
        },
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final List<ReportModel> reports;
  const _MapView({required this.reports});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Map view coming soon – use OpenStreetMap integration', style: AppTextStyles.bodySmall));
  }
}

class _ListView extends StatefulWidget {
  final List<ReportModel> reports;
  const _ListView({required this.reports});

  @override
  State<_ListView> createState() => _ListViewState();
}

class _ListViewState extends State<_ListView> {
  String _selectedFilter = 'All';

  List<ReportModel> get _filtered {
    switch (_selectedFilter) {
      case 'Verified':
        return widget.reports.where((r) => r.status == ReportStatus.verified).toList();
      case 'Pending':
        return widget.reports.where((r) => r.status == ReportStatus.pending).toList();
      case 'Resolved':
        return widget.reports.where((r) => r.status == ReportStatus.resolved).toList();
      default:
        return widget.reports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.white,
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: ['All', 'Verified', 'Pending', 'Resolved'].map((label) {
            final isSelected = label == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = label),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.white : AppColors.textGrey,
                        fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _ReportCard(report: _filtered[i]),
        ),
      ),
    ]);
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final isVerified = report.status == ReportStatus.verified;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(report.title, style: AppTextStyles.h3, maxLines: 2, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isVerified ? 'Verified' : 'Pending', style: AppTextStyles.bodySmall.copyWith(color: isVerified ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.hintGrey),
          const SizedBox(width: 4),
          Text('${report.barangay}, ${report.city}', style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(DateFormat('MMM d • h:mma').format(report.reportedAt), style: AppTextStyles.bodySmall),
        ]),
        const SizedBox(height: 8),
        Text(report.description, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(20)),
            child: Text(report.hazardSubcategory, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 11)),
          ),
          const Spacer(),
          const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.hintGrey),
          const SizedBox(width: 3),
          Text('${report.upvotes}', style: AppTextStyles.bodySmall),
        ]),
      ]),
    );
  }
}
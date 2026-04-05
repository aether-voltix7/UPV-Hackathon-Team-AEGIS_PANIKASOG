import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/report_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
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
      .map((snap) {
        final liveReports = snap.docs.map(ReportModel.fromFirestore).toList();
        return [...liveReports, ...ReportModel.mockReports]; // ← merge both
      });

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
          decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () => setState(() => _showMap = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: !_showMap ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('List',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: !_showMap ? AppColors.white : AppColors.hintGrey,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showMap = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: _showMap ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Map',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: _showMap ? AppColors.white : AppColors.hintGrey,
                        fontWeight: FontWeight.w600)),
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

// ─── Map placeholder ───────────────────────────────────────────────────────────
class _MapView extends StatelessWidget {
  final List<ReportModel> reports;
  const _MapView({required this.reports});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        color: const Color(0xFFE8EAF6),
        child: const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.map_outlined, size: 80, color: AppColors.borderGrey),
          SizedBox(height: 12),
          Text('Google Maps will appear here\nafter adding your API key',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ])),
      ),
      // Report pins overlay
      ...reports.map((r) => Positioned(
            top: 80 + (reports.indexOf(r) * 60.0),
            left: 80 + (reports.indexOf(r) * 40.0),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: r.status == ReportStatus.verified
                      ? AppColors.success
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6)
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on,
                      color: AppColors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                      r.hazardSubcategory.length > 12
                          ? '${r.hazardSubcategory.substring(0, 12)}...'
                          : r.hazardSubcategory,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )),
    ]);
  }
}

// ─── List view ─────────────────────────────────────────────────────────────────
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
      // Filter chips
      Container(
        color: AppColors.white,
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: ['All', 'Verified', 'Pending', 'Resolved'].map((label) {
            final isSelected = label == _selectedFilter; // ← dynamic
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = label), // ← on tap
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
          itemCount: _filtered.length,        // ← use filtered
          itemBuilder: (_, i) => _ReportCard(report: _filtered[i]), // ← use filtered
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(report.title,
                  style: AppTextStyles.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isVerified ? 'Verified' : 'Pending',
                style: AppTextStyles.bodySmall.copyWith(
                    color: isVerified ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_outlined,
              size: 14, color: AppColors.hintGrey),
          const SizedBox(width: 4),
          Text('${report.barangay}, ${report.city}',
              style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(DateFormat('MMM d • h:mma').format(report.reportedAt),
              style: AppTextStyles.bodySmall),
        ]),
        const SizedBox(height: 8),
        Text(report.description,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(20)),
            child: Text(report.hazardSubcategory,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11)),
          ),
          const Spacer(),
          const Icon(Icons.arrow_upward_rounded,
              size: 14, color: AppColors.hintGrey),
          const SizedBox(width: 3),
          Text('${report.upvotes}', style: AppTextStyles.bodySmall),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE REPORT SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});
  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl =
      TextEditingController(text: '1. Data and Info (auto-detected)');
  final _locationCtrl = TextEditingController(text: 'La Paz, Iloilo City');
  final _timeCtrl = TextEditingController(
      text: DateFormat('MMM d, yyyy • h:mma').format(DateTime.now()));
  final _descCtrl = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategory;
  final List<File> _photos = []; // made final
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _timeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.primary, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.chipBg, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 12, color: AppColors.primary)),
          const SizedBox(width: 8),
          const Text('Create a Report', style: AppTextStyles.h2),
        ]),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Auto-detected fields
            const _AutoField(
                label: '1. Data & Info (auto-detected)',
                value: 'La Paz, Iloilo City • 3:45PM'),
            const SizedBox(height: 12),
            _AutoField(
                label: '2. Current Time (auto-detected)',
                value: _timeCtrl.text),
            const SizedBox(height: 12),
            _AutoField(
                label: '3. Location (auto-detected)',
                value: _locationCtrl.text),
            const SizedBox(height: 20),

            // Photo picker
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey)),
                child: _photos.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.camera_alt_outlined,
                                color: AppColors.hintGrey, size: 30),
                            SizedBox(height: 6),
                            Text('Take Photos',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: AppColors.hintGrey)),
                          ])
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: _photos.length,
                        itemBuilder: (_, i) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_photos[i], fit: BoxFit.cover)),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Hazard category picker
            const Text('Select Hazard Category', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...HazardCategory.all.map((cat) => _HazardCategoryTile(
                  category: cat,
                  selected: _selectedCategoryId == cat.id,
                  selectedSub: _selectedCategoryId == cat.id
                      ? _selectedSubcategory
                      : null,
                  onCategoryTap: () => setState(() {
                    _selectedCategoryId =
                        _selectedCategoryId == cat.id ? null : cat.id;
                    _selectedSubcategory = null;
                  }),
                  onSubTap: (sub) => setState(() => _selectedSubcategory = sub),
                )),
            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: AppTextStyles.inputText,
              decoration: const InputDecoration(
                  hintText: 'Describe the hazard or incident...'),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_submitting || _selectedSubcategory == null)
                    ? null
                    : () => _submit(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5)),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2.5))
                    : const Text('Create Report',
                        style: AppTextStyles.labelLarge),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
                child: Text(
                    '*By submitting, you confirm this is an accurate report of an emergency.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center)),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final f =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (f != null && mounted) setState(() => _photos.add(File(f.path)));
  }

  Future<void> _submit(BuildContext context) async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedCategoryId == null || _selectedSubcategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a hazard category.'),
        backgroundColor: AppColors.error));
    return;
  }
  setState(() => _submitting = true);

  try {
    final user = FirebaseAuth.instance.currentUser!;
        final locationParts = _locationCtrl.text.split(',');
        final barangay = locationParts.isNotEmpty ? locationParts[0].trim() : 'Unknown';
        final city = locationParts.length > 1 ? locationParts[1].trim() : 'Iloilo City';
        final report = ReportModel(
          id: '',
          reportedBy: user.uid,
          reporterUsername: user.displayName ?? 'Anonymous',
          reporterAvatarUrl: user.photoURL,
          title: '${_selectedSubcategory!} - $barangay',
          description: _descCtrl.text.trim(),
          hazardCategoryId: _selectedCategoryId!,
          hazardSubcategory: _selectedSubcategory!,
          barangay: barangay,
          city: city,
          reportedAt: DateTime.now(),
          status: ReportStatus.pending,
          imageUrls: const [],
          upvotes: 0,
    );

    await FirebaseFirestore.instance
        .collection('reports')
        .add(report.toFirestore());

  } catch (e) {
    setState(() => _submitting = false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit: $e'),
        backgroundColor: AppColors.error));
    return;
  }

  setState(() => _submitting = false);
  if (!context.mounted) return;
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Report submitted! Thank you. 🙏'),
      backgroundColor: AppColors.success));
}
}

class _AutoField extends StatelessWidget {
  final String label;
  final String value;
  const _AutoField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.hintGrey)),
              ])),
          const Icon(Icons.gps_fixed, color: AppColors.primary, size: 16),
        ]),
      );
}

class _HazardCategoryTile extends StatelessWidget {
  final HazardCategory category;
  final bool selected;
  final String? selectedSub;
  final VoidCallback onCategoryTap;
  final void Function(String) onSubTap;
  const _HazardCategoryTile(
      {required this.category,
      required this.selected,
      this.selectedSub,
      required this.onCategoryTap,
      required this.onSubTap});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onCategoryTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.chipBg : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderGrey),
          ),
          child: Row(children: [
            Text(category.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(category.label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600))),
            Icon(selected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.hintGrey),
          ]),
        ),
      ),
      if (selected)
        Container(
          margin: const EdgeInsets.only(left: 16, bottom: 8),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
              children: category.subcategories.map((sub) {
            final isSelected = sub == selectedSub;
            return GestureDetector(
              onTap: () => onSubTap(sub),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.chipBg : AppColors.white,
                  borderRadius: category.subcategories.indexOf(sub) == 0
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : category.subcategories.indexOf(sub) ==
                              category.subcategories.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(10))
                          : BorderRadius.zero,
                ),
                child: Row(children: [
                  Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          isSelected ? AppColors.primary : AppColors.hintGrey,
                      size: 18),
                  const SizedBox(width: 10),
                  Text(sub,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark)),
                ]),
              ),
            );
          }).toList()),
        ),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/prohibited_keywords.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});
  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'La Paz, Iloilo City');
  final _descCtrl = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  final List<File> _photos = [];
  bool _submitting = false;

  String _filterText(String text) {
    String result = text;
    for (String keyword in prohibitedKeywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    return result;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.chipBg, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 12, color: AppColors.primary)),
          const SizedBox(width: 8),
          const Text('Create a Report', style: AppTextStyles.h2),
        ]),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Photo picker
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: _photos.isEmpty
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.camera_alt_outlined, color: AppColors.hintGrey, size: 30),
                        SizedBox(height: 6),
                        Text('Take Photos', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.hintGrey)),
                      ])
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: _photos.length,
                        itemBuilder: (_, i) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_photos[i], fit: BoxFit.cover)),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text('Title', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              onChanged: (value) {
                String filtered = _filterText(value);
                if (filtered != value) {
                  _titleCtrl.text = filtered;
                  _titleCtrl.selection = TextSelection.collapsed(offset: filtered.length);
                }
              },
              decoration: const InputDecoration(hintText: 'e.g., Flooded Road - Brgy. Rizal'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
            ),
            const SizedBox(height: 16),

            // Hazard category
            const Text('Select Hazard Category', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...HazardCategory.all.map((cat) => _HazardCategoryTile(
                  category: cat,
                  selected: _selectedCategoryId == cat.id,
                  selectedSub: _selectedCategoryId == cat.id ? _selectedSubcategory : null,
                  onCategoryTap: () => setState(() {
                    _selectedCategoryId = _selectedCategoryId == cat.id ? null : cat.id;
                    _selectedSubcategory = null;
                  }),
                  onSubTap: (sub) => setState(() => _selectedSubcategory = sub),
                )),
            const SizedBox(height: 20),

            // Description
            const Text('Description', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              onChanged: (value) {
                String filtered = _filterText(value);
                if (filtered != value) {
                  _descCtrl.text = filtered;
                  _descCtrl.selection = TextSelection.collapsed(offset: filtered.length);
                }
              },
              decoration: const InputDecoration(hintText: 'Describe the hazard or incident...'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_submitting || _selectedSubcategory == null) ? null : () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
                    : const Text('Create Report', style: AppTextStyles.labelLarge),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (f != null && mounted) setState(() => _photos.add(File(f.path)));
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a hazard category.'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in'), backgroundColor: AppColors.error));
      return;
    }

    // Upload images
    List<String> imageUrls = [];
    for (final img in _photos) {
      final ref = FirebaseStorage.instance.ref().child('reports/${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');
      await ref.putFile(img);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    final report = ReportModel(
      id: '',
      reportedBy: user.uid,
      reporterUsername: user.username,
      reporterAvatarUrl: user.avatarUrl,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      hazardCategoryId: _selectedCategoryId!,
      hazardSubcategory: _selectedSubcategory!,
      barangay: _locationCtrl.text.split(',').first.trim(),
      city: _locationCtrl.text.contains(',') ? _locationCtrl.text.split(',').last.trim() : 'Iloilo City',
      reportedAt: DateTime.now(),
      imageUrls: imageUrls,
    );

    await FirebaseFirestore.instance.collection('reports').add(report.toFirestore());
    if (!mounted) return; // ADDED
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted! Thank you. 🙏'), backgroundColor: AppColors.success));
  }
}

class _HazardCategoryTile extends StatelessWidget {
  final HazardCategory category;
  final bool selected;
  final String? selectedSub;
  final VoidCallback onCategoryTap;
  final void Function(String) onSubTap;
  const _HazardCategoryTile({
    required this.category,
    required this.selected,
    this.selectedSub,
    required this.onCategoryTap,
    required this.onSubTap,
  });

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
            border: Border.all(color: selected ? AppColors.primary : AppColors.borderGrey),
          ),
          child: Row(children: [
            Text(category.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(category.label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
            Icon(selected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.hintGrey),
          ]),
        ),
      ),
      if (selected)
        Container(
          margin: const EdgeInsets.only(left: 16, bottom: 8),
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(10)),
          child: Column(children: category.subcategories.map((sub) {
            final isSelected = sub == selectedSub;
            return GestureDetector(
              onTap: () => onSubTap(sub),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.chipBg : AppColors.white,
                  borderRadius: category.subcategories.indexOf(sub) == 0
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : category.subcategories.indexOf(sub) == category.subcategories.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(10))
                          : BorderRadius.zero,
                ),
                child: Row(children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : AppColors.hintGrey, size: 18),
                  const SizedBox(width: 10),
                  Text(sub, style: AppTextStyles.bodyMedium.copyWith(color: isSelected ? AppColors.primary : AppColors.textDark)),
                ]),
              ),
            );
          }).toList()),
        ),
    ]);
  }
}
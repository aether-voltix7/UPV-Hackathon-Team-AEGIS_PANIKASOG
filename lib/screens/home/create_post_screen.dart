import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _locationFocus = FocusNode();

  GoogleMapController? _mapController;
  final _locationCtrl = TextEditingController(text: 'La Paz, Iloilo City');
  bool _showMap = false;

  final List<File> _selectedImages = [];
  PostCategory _selectedCategory = PostCategory.community;
  final List<String> _tags = []; // made final
  bool _isGeneratingCaption = false;

  static const _categories = [
    'Community',
    'Verified',
    'Tasks',
    'News',
    'Cleanup & Recovery',
    'Emergency Response',
    'Relief Distribution',
    'Preparedness',
  ];

  @override
  void initState() {
    super.initState();
    // 2. Listen for when the user clicks the text field
    _locationFocus.addListener(() {
      setState(() {
        _showMap = _locationFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    _categoryCtrl.dispose();
    _tagCtrl.dispose();
    _locationCtrl.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<List<XFile>?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(picker: picker),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _selectedImages.addAll(result.map((f) => File(f.path))));
    }
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags.add(t));
    _tagCtrl.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _simulateAutoCaption() {
    setState(() => _isGeneratingCaption = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isGeneratingCaption = false;
        _captionCtrl.text =
            'Our community cleanup drive was a huge success! 🌊 Thanks to all the amazing volunteers who pitched in to clear debris, sweep streets, and participated in our disaster preparedness community session. Your time and effort made a real difference—together, we\'re stronger and our community is cleaner and safer. 💪 #BrgyMainis #CleanupSuccess #DisasterReady';
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final post = await context.read<PostProvider>().createPost(
          authorId: user.uid,
          authorUsername: user.username,
          authorAvatarUrl: user.avatarUrl,
          authorIsVerified: false,
          barangay: _locationCtrl.text.split(',').first.trim(),
          city: _locationCtrl.text.contains(',')
              ? _locationCtrl.text.split(',').last.trim()
              : 'Iloilo City',
          title: _titleCtrl.text.trim(),
          caption: _captionCtrl.text.trim(),
          imageFile: _selectedImages.isNotEmpty ? _selectedImages.first : null,
          imageFiles: _selectedImages,
          tags: _tags,
          category: _selectedCategory,
        );

    if (post != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

// auto-detect current location
  Future<void> _handleLocationDetection() async {
    try {
      // 1. Check if GPS service is actually ON
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Prompt user to turn on GPS
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please enable location services in your settings.')),
        );
        return;
      }

      // 2. Handle Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) {
        // User has permanently denied, they'll need to go to app settings
        return;
      }

      // 3. Get Position
      _locationCtrl.text = "Detecting..."; // Show loading state
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Update UI
      setState(() {
        _locationCtrl.text =
            "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";

        // Update Map's camera to jump to the user's location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create a Post', style: AppTextStyles.h2),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo picker ───────────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, i) {
                            if (i == _selectedImages.length) {
                              return GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120, height: 200,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderGrey),
                                  ),
                                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.hintGrey, size: 32),
                                    SizedBox(height: 8),
                                    Text('Add More', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.hintGrey)),
                                  ]),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_selectedImages[i], width: 160, height: 200, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedImages.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ] else
                      Container(
                        width: double.infinity, height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.hintGrey, size: 32),
                          SizedBox(height: 8),
                          Text('Take Photos', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.hintGrey, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────────────────────
              AppTextField(
                label: 'Title',
                hint: 'e.g. Successful Cleanup Drive...',
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Caption + Auto-Caption ─────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Caption',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _captionCtrl,
                    maxLines: 5,
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Our community cleanup drive was a huge success...',
                      hintStyle: AppTextStyles.inputHint,
                      hintMaxLines: 3,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Caption is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Auto-Caption button
                  GestureDetector(
                    onTap: _simulateAutoCaption,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isGeneratingCaption
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome,
                                  color: AppColors.primary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _isGeneratingCaption
                                ? 'Generating...'
                                : '✦ Auto-Caption',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Category ───────────────────────────────────────────────────
              _CategoryDropdown(
                selected: _categoryCtrl.text,
                options: _categories,
                onSelected: (val) {
                  setState(() {
                    _categoryCtrl.text = val;
                    _selectedCategory = _categoryFromLabel(val);
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Tags ───────────────────────────────────────────────────────
              _TagsSection(
                tags: _tags,
                controller: _tagCtrl,
                onAdd: _addTag,
                onRemove: _removeTag,
              ),
              const SizedBox(height: 16),

              // ── Location ───────────────────────────────────────────────────

              AppTextField(
                focusNode: _locationFocus,
                label: 'Location (Auto-detected)',
                controller: _locationCtrl,
                readOnly: false,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.gps_fixed,
                      color: AppColors.primary, size: 18),
                  onPressed: _handleLocationDetection,
                ),
              ),

              const SizedBox(height: 10), // Reduced height to keep map close

              if (_showMap)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: ClipRRect(
                    // Rounds the corners of the map
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(10.7202, 122.5621),
                        zoom: 14,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),

              const SizedBox(height: 28), // Space after the map/field

              // ── Submit ─────────────────────────────────────────────────────
              AppButton(
                label: 'Create Post',
                onPressed: _submit,
                isLoading: postProvider.isCreatingPost,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PostCategory _categoryFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'verified':
        return PostCategory.verified;
      case 'tasks':
        return PostCategory.tasks;
      case 'news':
        return PostCategory.news;
      default:
        return PostCategory.community;
    }
  }
}

// ─── Category dropdown ─────────────────────────────────────────────────────────
class _CategoryDropdown extends StatefulWidget {
  final String selected;
  final List<String> options;
  final void Function(String) onSelected;
  const _CategoryDropdown(
      {required this.selected,
      required this.options,
      required this.onSelected});

  @override
  State<_CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<_CategoryDropdown> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Category',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
            children: [
              TextSpan(text: '*', style: TextStyle(color: AppColors.primary))
            ],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _open ? AppColors.primary : AppColors.borderGrey,
                  width: _open ? 1.5 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  widget.selected.isEmpty
                      ? 'Search category...'
                      : widget.selected,
                  style: widget.selected.isEmpty
                      ? AppTextStyles.inputHint
                      : AppTextStyles.inputText,
                ),
                const Spacer(),
                Icon(
                  _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.hintGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: widget.options.map((opt) {
                final isSelected = opt == widget.selected;
                return InkWell(
                  onTap: () {
                    widget.onSelected(opt);
                    setState(() => _open = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(opt, style: AppTextStyles.bodyMedium)),
                        if (isSelected)
                          const Icon(Icons.check,
                              color: AppColors.primary, size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        // Selected chip
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.selected,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary, fontSize: 12)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onSelected(''),
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Tags section ──────────────────────────────────────────────────────────────
class _TagsSection extends StatelessWidget {
  final List<String> tags;
  final TextEditingController controller;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const _TagsSection({
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: AppTextStyles.inputText,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: onAdd,
          decoration: InputDecoration(
            hintText: 'Enter tags...',
            hintStyle: AppTextStyles.inputHint,
            suffixIcon: GestureDetector(
              onTap: () => onAdd(controller.text),
              child: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(tag),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Image source picker ───────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final ImagePicker picker;
  const _ImageSourceSheet({required this.picker});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add Photo', style: AppTextStyles.h2),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () async {
                final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (!context.mounted) return;
                Navigator.pop(context, f != null ? [f] : null);
              },
              ),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () async {
                final files = await picker.pickMultiImage(imageQuality: 85);
                if (!context.mounted) return;
                Navigator.pop(context, files);
              },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.chipBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}

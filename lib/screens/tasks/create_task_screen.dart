import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/prohibited_keywords.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'La Paz, Iloilo City');
  TaskCategory _category = TaskCategory.emergencyResponse;
  final List<String> _tags = [];
  int _points = 100;
  int _volunteers = 5;
  bool _isUrgent = false;
  bool _submitting = false;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 2));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 6));

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
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyLocation() async {
    final address = _locationCtrl.text.trim();
    if (address.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final coords = await LocationService().getCoordinatesFromAddress(address);
    if (!mounted) return;
    if (coords == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Location not found. Please enter a valid address.'), backgroundColor: Colors.red),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Location verified!'), backgroundColor: AppColors.success),
      );
    }
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
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.chipBg, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 12, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text('Create a Task', style: AppTextStyles.h2),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _FieldLabel(label: 'Title'),
              TextFormField(
                controller: _titleCtrl,
                style: AppTextStyles.inputText,
                inputFormatters: const [ProhibitedKeywordFormatter()],
                decoration: const InputDecoration(hintText: 'e.g. Medical Assistance for Injured...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel(label: 'Description'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: AppTextStyles.inputText,
                inputFormatters: const [ProhibitedKeywordFormatter()],
                decoration: const InputDecoration(hintText: 'Describe the task in detail...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel(label: 'Category'),
              DropdownButtonFormField<TaskCategory>(
                initialValue: _category,
                style: AppTextStyles.inputText,
                decoration: const InputDecoration(),
                items: TaskCategory.values.map((c) {
                  final label = _categoryLabel(c);
                  return DropdownMenuItem(value: c, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              _FieldLabel(label: 'Tags'),
              TextFormField(
                controller: _tagCtrl,
                style: AppTextStyles.inputText,
                textInputAction: TextInputAction.done,
                inputFormatters: const [ProhibitedKeywordFormatter()],
                onFieldSubmitted: (v) {
                  final filtered = _filterText(v.trim());
                  if (filtered.isNotEmpty) {
                    setState(() {
                      _tags.add(filtered);
                      _tagCtrl.clear();
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Add a tag and press Enter',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: () {
                      final filtered = _filterText(_tagCtrl.text.trim());
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _tags.add(filtered);
                          _tagCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags.map((t) => _TagChip(label: t, onRemove: () => setState(() => _tags.remove(t)))).toList(),
                ),
              ],
              const SizedBox(height: 16),
              _FieldLabel(label: 'Location (Barangay, City)'),
              TextFormField(
                controller: _locationCtrl,
                style: AppTextStyles.inputText,
                onChanged: (value) {
                  String filtered = _filterText(value);
                  if (filtered != value) {
                    _locationCtrl.text = filtered;
                    _locationCtrl.selection = TextSelection.collapsed(offset: filtered.length);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'e.g., La Paz, Iloilo City',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: _verifyLocation,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Number of Volunteers'),
                        TextFormField(
                          initialValue: _volunteers.toString(),
                          style: AppTextStyles.inputText,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            String filtered = _filterText(value);
                            if (filtered != value) {
                              // For numbers, perhaps don't filter, but since it's text, filter anyway
                              // But to avoid issues, maybe skip for numbers
                            }
                            _volunteers = int.tryParse(filtered) ?? 1;
                          },
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Points'),
                        TextFormField(
                          initialValue: _points.toString(),
                          style: AppTextStyles.inputText,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            String filtered = _filterText(value);
                            if (filtered != value) {
                              // Skip filtering for numbers
                            }
                            _points = int.tryParse(filtered) ?? 100;
                          },
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DateField(label: 'Start Date/Time', date: _startDate, onTap: () => _pickDate(context, true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateField(label: 'End Date/Time', date: _endDate, onTap: () => _pickDate(context, false))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _isUrgent,
                    onChanged: (v) => setState(() => _isUrgent = v),
                    activeThumbColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Mark as Urgent', style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
                      : const Text('Create Task', style: AppTextStyles.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final buildContext = context;
    final picked = await showDatePicker(
      context: buildContext,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: buildContext,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;
    final newDateTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = newDateTime;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      } else {
        if (newDateTime.isAfter(_startDate)) {
          _endDate = newDateTime;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
        }
      }
    });
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final user = context.read<AuthProvider>().user;
    final locationParts = _locationCtrl.text.split(',');
    final taskProvider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await taskProvider.createTask(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          barangay: locationParts.first.trim(),
          city: locationParts.length > 1 ? locationParts.last.trim() : 'Iloilo City',
          category: _category,
          tags: _tags,
          points: _points,
          volunteersNeeded: _volunteers,
          scheduledStart: _startDate,
          scheduledEnd: _endDate,
          createdBy: user?.uid ?? '',
          isUrgent: _isUrgent,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success != null) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Task created! 🎉'), backgroundColor: AppColors.success));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Failed to create task'), backgroundColor: AppColors.error));
    }
  }

  String _categoryLabel(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.emergencyResponse: return 'Emergency Response';
      case TaskCategory.cleanupRecovery: return 'Cleanup & Recovery';
      case TaskCategory.reliefDistribution: return 'Relief Distribution';
      case TaskCategory.medicalAssistance: return 'Medical Assistance';
      case TaskCategory.preparedness: return 'Preparedness';
      default: return 'Other';
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: AppTextStyles.inputLabel),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel(label: label),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: Text(DateFormat('MMM d, yyyy\nh:mma').format(date), style: AppTextStyles.bodySmall)),
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.hintGrey),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECF3),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontSize: 12)),
              const SizedBox(width: 4),
              GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 13, color: AppColors.primary)),
            ],
          ),
        ),
      );
}
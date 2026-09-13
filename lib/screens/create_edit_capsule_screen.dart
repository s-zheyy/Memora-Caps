import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/capsule.dart';
import '../services/capsule_service.dart';
import '../theme.dart';

/// Creates a brand-new capsule. There is no "edit" mode here on purpose:
/// once a capsule is saved, its title/goal/reflection/unlock date become
/// permanent. That's what makes the locked → opened reveal meaningful —
/// what you read later is guaranteed to be exactly what you wrote then.
/// (Update capsules only happen via Add Reflection, which appends new
/// content without touching the original.)
class CreateEditCapsuleScreen extends StatefulWidget {
  const CreateEditCapsuleScreen({super.key});

  @override
  State<CreateEditCapsuleScreen> createState() => _CreateEditCapsuleScreenState();
}

class _CreateEditCapsuleScreenState extends State<CreateEditCapsuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CapsuleService();
  final _titleCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _reflectionCtrl = TextEditingController();

  // CHANGED ONLY FOR THE DROPDOWN
  String? _category;

  String _mood = 'motivated';
  DateTime _unlockDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _goalCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _unlockDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _unlockDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // One extra confirmation, since this content can never be edited again.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seal this capsule?'),
        content: Text(
          _unlockDate.isAfter(DateTime.now())
              ? 'Once saved, this capsule locks until ${DateFormat('MMM d, yyyy').format(_unlockDate)}. '
                  'You won\'t be able to edit the title, goal, or reflection after this — that\'s what keeps it an honest snapshot.'
              : 'Once saved, the title, goal, and reflection can\'t be edited — you\'ll only be able to add new reflections on top of it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seal It'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final capsule = Capsule(
        id: '',
        title: _titleCtrl.text.trim(),
        category: _category!,
        goal: _goalCtrl.text.trim(),
        originalReflection: _reflectionCtrl.text.trim(),
        mood: _mood,
        createdAt: DateTime.now(),
        unlockDate: _unlockDate,
      );
      await _service.createCapsule(capsule);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Capsule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'What you write below can\'t be edited once saved — write honestly, this is for future-you.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g., Improving My Study Habits',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),

              const SizedBox(height: 18),

              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // ONLY THE DROPDOWN WAS CHANGED
              DropdownButtonFormField<String>(
                value: _category,
                hint: const Text('Select a category'),
                items: kCapsuleCategories
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null
                    ? 'Please select a category'
                    : null,
              ),

              const SizedBox(height: 18),

              const Text(
                'Goal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _goalCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Write your goal for the future...',
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Reflection',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _reflectionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write your reflection...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Reflection is required'
                    : null,
              ),

              const SizedBox(height: 18),

              const Text(
                'How are you feeling today?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Row(
                children: kMoodEmojis.entries.map((entry) {
                  final selected = _mood == entry.key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _mood = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppColors.accentBlue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              const Text(
                'Unlock Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(_unlockDate),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Save Capsule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
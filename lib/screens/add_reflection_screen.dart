import 'package:flutter/material.dart';
import '../models/capsule.dart';
import '../services/capsule_service.dart';
import '../theme.dart';

class AddReflectionScreen extends StatefulWidget {
  final Capsule capsule;
  const AddReflectionScreen({super.key, required this.capsule});

  @override
  State<AddReflectionScreen> createState() => _AddReflectionScreenState();
}

class _AddReflectionScreenState extends State<AddReflectionScreen> {
  late TextEditingController _reflectionCtrl;
  late TextEditingController _lessonsCtrl;
  final _service = CapsuleService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reflectionCtrl = TextEditingController(text: widget.capsule.currentReflection);
    _lessonsCtrl = TextEditingController(text: widget.capsule.lessonsLearned);
  }

  @override
  void dispose() {
    _reflectionCtrl.dispose();
    _lessonsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reflectionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your current reflection.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.addReflection(
        capsuleId: widget.capsule.id,
        currentReflection: _reflectionCtrl.text.trim(),
        lessonsLearned: _lessonsCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reflection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Current Reflection', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _reflectionCtrl,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'What has changed since you wrote your original reflection?'),
            ),
            const SizedBox(height: 20),
            const Text('Lessons Learned', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _lessonsCtrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'What did you learn from this experience?'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Reflection'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

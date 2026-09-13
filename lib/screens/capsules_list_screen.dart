import 'package:flutter/material.dart';
import '../models/capsule.dart';
import '../services/capsule_service.dart';
import '../theme.dart';
import 'capsule_details_screen.dart';
import 'create_edit_capsule_screen.dart';

enum _Filter { all, locked, opened }

class CapsulesListScreen extends StatefulWidget {
  const CapsulesListScreen({super.key});

  @override
  State<CapsulesListScreen> createState() => _CapsulesListScreenState();
}

class _CapsulesListScreenState extends State<CapsulesListScreen> {
  final _service = CapsuleService();
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateEditCapsuleScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Capsule>>(
        stream: _service.watchCapsules(),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final lockedCount = all.where((c) => c.isLocked).length;
          final openedCount = all.length - lockedCount;

          var filtered = switch (_filter) {
            _Filter.all => all,
            _Filter.locked => all.where((c) => c.isLocked).toList(),
            _Filter.opened => all.where((c) => !c.isLocked).toList(),
          };
          if (_query.trim().isNotEmpty) {
            final q = _query.toLowerCase();
            filtered = filtered
                .where((c) => c.title.toLowerCase().contains(q) || c.category.toLowerCase().contains(q))
                .toList();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const Text('Memory Capsules', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search digital capsules...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _FilterChip(label: 'All (${all.length})', selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Locked ($lockedCount)', selected: _filter == _Filter.locked, onTap: () => setState(() => _filter = _Filter.locked)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Opened ($openedCount)', selected: _filter == _Filter.opened, onTap: () => setState(() => _filter = _Filter.opened)),
                ],
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('No capsules found.', style: TextStyle(color: AppColors.textMuted))),
                )
              else
                ...filtered.map((c) => _CapsuleCard(capsule: c, service: _service)),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.navy : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textDark)),
      ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  final Capsule capsule;
  final CapsuleService service;
  const _CapsuleCard({required this.capsule, required this.service});

  @override
  Widget build(BuildContext context) {
    final locked = capsule.isLocked;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CapsuleDetailsScreen(capsuleId: capsule.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(capsule.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  // Deliberately no "Edit" option: capsule content is
                  // sealed once created (locked = hidden, opened =
                  // permanently read-only). Delete is still available if
                  // the user wants to remove a capsule outright.
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete capsule?'),
                            content: Text('This will permanently delete "${capsule.title}". This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await service.deleteCapsule(capsule.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(capsule.category, style: const TextStyle(fontSize: 11, color: AppColors.accentBlue)),
              ),
              const SizedBox(height: 8),
              Text('Created ${_fmt(capsule.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    locked ? 'Unlocks ${_fmt(capsule.unlockDate)}' : 'Unlocked ${_fmt(capsule.unlockDate)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (locked ? AppColors.warning : AppColors.success).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(locked ? Icons.lock_outline : Icons.lock_open, size: 12, color: locked ? AppColors.warning : AppColors.success),
                      const SizedBox(width: 4),
                      Text(locked ? 'Locked' : 'Opened', style: TextStyle(fontSize: 11, color: locked ? AppColors.warning : AppColors.success)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';
  String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// screens/task_master_tab.dart — Tab 2: Add & manage tasks

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskMasterTab extends StatefulWidget {
  final List<dynamic> tasks;
  final VoidCallback onTaskAdded;
  final Function(String) onTaskCompleted;
  final Function(String) onTaskDeleted;

  const TaskMasterTab({
    super.key,
    required this.tasks,
    required this.onTaskAdded,
    required this.onTaskCompleted,
    required this.onTaskDeleted,
  });

  @override
  State<TaskMasterTab> createState() => _TaskMasterTabState();
}

class _TaskMasterTabState extends State<TaskMasterTab> {
  final _api         = ApiService();
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  DateTime? _deadline;
  double   _weight   = 0.2;
  int      _effort   = 3;
  String   _category = 'Academic';
  bool     _isAdding = false;

  Color _scoreColor(double score) {
    if (score >= 0.75) return const Color(0xFFFF4757);
    if (score >= 0.50) return const Color(0xFFFFB800);
    if (score >= 0.25) return const Color(0xFF6C63FF);
    return const Color(0xFF00D2A0);
  }

  String _scoreLabel(double score) {
    if (score >= 0.75) return 'Critical';
    if (score >= 0.50) return 'High';
    if (score >= 0.25) return 'Medium';
    return 'Low';
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    setState(() {
      _deadline = t == null
          ? d
          : DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _addTask() async {
    if (_nameCtrl.text.trim().isEmpty || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill task name and deadline'),
            backgroundColor: Color(0xFFFF4757)),
      );
      return;
    }
    setState(() => _isAdding = true);
    try {
      await _api.addTask(
        name:        _nameCtrl.text.trim(),
        deadline:    _deadline!,
        taskWeight:  _weight,
        effortLevel: _effort,
        category:    _category,
        // FIX 1: Ensure description is never null to avoid FastAPI 422 error
        description: _descCtrl.text.trim().isEmpty ? "" : _descCtrl.text.trim(),
      );
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() { _deadline = null; _weight = 0.2; _effort = 3; });
      widget.onTaskAdded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Task added & scored!'),
              backgroundColor: Color(0xFF00D2A0)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: const Color(0xFFFF4757)),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort pending tasks by score so highest is at the top
    final pending = widget.tasks.where((t) => t['status'] == 'Pending').toList();
    pending.sort((a, b) => (b['priority_score'] ?? 0).compareTo(a['priority_score'] ?? 0));
    
    final completed = widget.tasks.where((t) => t['status'] == 'Completed').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Add Task Form ─────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Task',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(color: Color(0xFF8888AA)),
                    prefixIcon: Icon(Icons.edit_note_rounded,
                        color: Color(0xFF6C63FF), size: 24),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Category chips
                Wrap(
                  spacing: 8,
                  children:
                      ['Academic', 'Personal', 'Extracurricular'].map((c) {
                    final selected = _category == c;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: const Color(0xFF6C63FF).withOpacity(0.8),
                      backgroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF8888AA),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selected ? const Color(0xFF6C63FF) : const Color(0xFF2A2A4A),
                          width: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Deadline picker
                GestureDetector(
                  onTap: _pickDeadline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2A2A4A), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF6C63FF), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _deadline == null
                              ? 'Pick deadline'
                              : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}  ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: _deadline == null
                                  ? const Color(0xFF8888AA)
                                  : Colors.white,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Task Weight slider
                Row(
                  children: [
                    const Text('Weight (Impact on Grade):',
                        style: TextStyle(
                            color: Color(0xFF8888AA), fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(
                      '${(_weight * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF6C63FF),
                    thumbColor: const Color(0xFF6C63FF),
                    inactiveTrackColor: const Color(0xFF2A2A4A),
                    overlayColor:
                        const Color(0xFF6C63FF).withOpacity(0.15),
                  ),
                  child: Slider(
                    value: _weight,
                    min: 0.05,
                    max: 0.50,
                    divisions: 9,
                    onChanged: (v) => setState(() => _weight = v),
                  ),
                ),

                // Effort level
                Row(
                  children: [
                    const Text('Difficulty/Effort:',
                        style: TextStyle(
                            color: Color(0xFF8888AA), fontSize: 13)),
                    const SizedBox(width: 8),
                    ...List.generate(
                      5,
                      (i) => GestureDetector(
                        onTap: () => setState(() => _effort = i + 1),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.bolt,
                            size: 22,
                            color: i < _effort
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF2A2A4A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isAdding ? null : _addTask,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_task, size: 18),
                    label: const Text('Score & Add Task',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Pending Tasks ─────────────────────────────────────────────
        if (pending.isNotEmpty) ...[
          Text(
            'Pending Tasks',
            style: const TextStyle(
                color: Color(0xFF8888AA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ...pending.map((task) => _TaskCard(
                task: task,
                scoreColor: _scoreColor(
                    (task['priority_score'] as num?)?.toDouble() ?? 0.0),
                scoreLabel: _scoreLabel(
                    (task['priority_score'] as num?)?.toDouble() ?? 0.0),
                onComplete: () => widget.onTaskCompleted(task['id'] as String),
                onDelete: () => widget.onTaskDeleted(task['id'] as String),
              )),
          const SizedBox(height: 16),
        ],

        // ── Completed Tasks ───────────────────────────────────────────
        if (completed.isNotEmpty) ...[
          Text(
            'Completed',
            style: const TextStyle(
                color: Color(0xFF8888AA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ...completed.map((task) => _TaskCard(
                task: task,
                scoreColor: const Color(0xFF00D2A0),
                scoreLabel: 'Done',
                onComplete: null,
                onDelete: () => widget.onTaskDeleted(task['id'] as String),
                isDone: true,
              )),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Color scoreColor;
  final String scoreLabel;
  final VoidCallback? onComplete;
  final VoidCallback onDelete;
  final bool isDone;

  const _TaskCard({
    required this.task,
    required this.scoreColor,
    required this.scoreLabel,
    required this.onComplete,
    required this.onDelete,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = (task['priority_score'] as num?)?.toDouble() ?? 0.0;
    final weight = (task['task_weight'] as num?)?.toDouble() ?? 0.0;
    final hours = (task['hours_remaining'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['name'] as String? ?? '',
                    style: TextStyle(
                      color: isDone ? const Color(0xFF8888AA) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: scoreColor.withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                        color: scoreColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${task['category']}  •  '
              '${(weight * 100).toStringAsFixed(0)}% weight  •  '
              '${hours.toStringAsFixed(0)}h left',
              style: const TextStyle(
                  color: Color(0xFF8888AA), fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Progress bar (priority score)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: const Color(0xFF2A2A4A),
                valueColor:
                    AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 4,
              ),
            ),
            if (task['nudge_message'] != null) ...[
              const SizedBox(height: 8),
              Text(
                task['nudge_message'] as String,
                style: const TextStyle(
                    color: Color(0xFF8888AA), fontSize: 11),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onComplete != null)
                  TextButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF00D2A0)),
                    label: const Text('Complete',
                        style: TextStyle(
                            color: Color(0xFF00D2A0), fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4)),
                  ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: Color(0xFFFF4757)),
                  label: const Text('Delete',
                      style: TextStyle(
                          color: Color(0xFFFF4757), fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
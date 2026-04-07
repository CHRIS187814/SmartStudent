// screens/dashboard_tab.dart — Tab 1: Smart Dashboard

import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, dynamic> dashboard;
  final List<dynamic> tasks;
  final VoidCallback onRefresh;

  const DashboardTab({
    super.key,
    required this.dashboard,
    required this.tasks,
    required this.onRefresh,
  });

  Color _scoreColor(double score) {
    if (score >= 0.75) return const Color(0xFFFF4757);
    if (score >= 0.50) return const Color(0xFFFFB800);
    if (score >= 0.25) return const Color(0xFF6C63FF);
    return const Color(0xFF00D2A0);
  }

  @override
  Widget build(BuildContext context) {
    final topTask   = dashboard['top_task'] as Map<String, dynamic>?;
    final weeklyLoad = (dashboard['weekly_load'] as Map<String, dynamic>?) ?? {};
    final pending   = tasks.where((t) => t['status'] != 'Completed').toList();

    return RefreshIndicator(
      color: const Color(0xFF6C63FF),
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Daily Focus Card ──────────────────────────────────────────
          if (topTask != null) ...[
            const Text(
              'Daily Focus',
              style: TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8A63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          topTask['category'] as String? ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Priority ${((topTask['priority_score'] as num?)?.toDouble() ?? 0.0 * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    topTask['name'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${((topTask['hours_remaining'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}h remaining  •  '
                    '${(((topTask['task_weight'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}% weight',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  // Nudge message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      topTask['nudge_message'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Weekly Load Heatmap ───────────────────────────────────────
          const Text(
            'Weekly Load',
            style: TextStyle(
                color: Color(0xFF8888AA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((day) {
                  final load =
                      (weeklyLoad[day] as num?)?.toDouble() ?? 0.0;
                  final intensity = (load / 3.0).clamp(0.0, 1.0);
                  return _HeatmapDay(
                      day: day, intensity: intensity, load: load);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Pending Tasks List ────────────────────────────────────────
          Text(
            'Prioritized Tasks (${pending.length})',
            style: const TextStyle(
                color: Color(0xFF8888AA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ...pending.take(5).map((task) {
            final score =
                (task['priority_score'] as num?)?.toDouble() ?? 0.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: _scoreColor(score).withOpacity(0.15),
                  child: Text(
                    '${(score * 100).toStringAsFixed(0)}',
                    style: TextStyle(
                        color: _scoreColor(score),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                title: Text(
                  task['name'] as String? ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
                subtitle: Text(
                  '${task['category']}  •  '
                  '${((task['hours_remaining'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}h left',
                  style: const TextStyle(
                      color: Color(0xFF8888AA), fontSize: 12),
                ),
                trailing: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _scoreColor(score),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeatmapDay extends StatelessWidget {
  final String day;
  final double intensity;
  final double load;

  const _HeatmapDay(
      {required this.day,
      required this.intensity,
      required this.load});

  @override
  Widget build(BuildContext context) {
    final color = intensity > 0.6
        ? const Color(0xFFFF4757)
        : intensity > 0.3
            ? const Color(0xFFFFB800)
            : const Color(0xFF00D2A0);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1 + intensity * 0.6),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(day,
            style: const TextStyle(
                color: Color(0xFF8888AA), fontSize: 11)),
      ],
    );
  }
}

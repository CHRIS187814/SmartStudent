// screens/analytics_tab.dart — Tab 3: Analytics & Reports

import 'package:flutter/material.dart';

class AnalyticsTab extends StatelessWidget {
  final List<dynamic> tasks;
  final Map<String, dynamic> dashboard;

  const AnalyticsTab({
    super.key,
    required this.tasks,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final total     = tasks.length;
    final completed = tasks.where((t) => t['status'] == 'Completed').length;
    final pending   = tasks.where((t) => t['status'] == 'Pending' || t['status'] == 'In Progress').length;
    final rate      = total > 0 ? completed / total : 0.0;

    // Category breakdown logic
    final catMap = <String, int>{};
    final catPriority = <String, double>{};
    final catCount    = <String, int>{};

    for (final t in tasks) {
      final c = t['category'] as String? ?? 'Other';
      final s = (t['priority_score'] as num?)?.toDouble() ?? 0.0;
      
      catMap[c] = (catMap[c] ?? 0) + 1;
      catPriority[c] = (catPriority[c] ?? 0) + s;
      catCount[c]    = (catCount[c] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Summary Cards ──────────────────────────────────────────────
        Row(
          children: [
            _StatCard(label: 'Total Tasks', value: total.toString(),
                color: const Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            _StatCard(label: 'Completed', value: completed.toString(),
                color: const Color(0xFF00D2A0)),
            const SizedBox(width: 12),
            _StatCard(label: 'Pending', value: pending.toString(),
                color: const Color(0xFFFFB800)),
          ],
        ),
        const SizedBox(height: 24),

        // ── Completion Rate ────────────────────────────────────────────
        Card(
          elevation: 0,
          color: const Color(0xFF1E1E30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GOAL PROGRESS',
                    style: TextStyle(
                        color: Color(0xFF8888AA),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: rate,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFF2A2A4A),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00D2A0)),
                          ),
                          Center(
                            child: Text(
                              '${(rate * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendItem(color: const Color(0xFF00D2A0), label: 'Finished'),
                          const SizedBox(height: 12),
                          _LegendItem(color: const Color(0xFFFFB800), label: 'On Deck'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── High Priority ML Alerts ───────────────────────────────────────
        Builder(builder: (context) {
          final critical = tasks.where((t) {
            final score = (t['priority_score'] as num?)?.toDouble() ?? 0.0;
            final isDone = t['status'] == 'Completed';
            return score >= 0.75 && !isDone;
          }).toList();

          if (critical.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CRITICAL ALERTS (AI PRIORITIZED)',
                style: TextStyle(
                    color: Color(0xFFFF4757),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              ...critical.map((t) => _CriticalAlertItem(task: t)),
              const SizedBox(height: 20),
            ],
          );
        }),

        // ── Category Breakdown ──────────────────────────────────────────
        if (catMap.isNotEmpty) ...[
          const Text('TASK DISTRIBUTION',
              style: TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ...catMap.entries.map((e) {
            final pct = e.value / total;
            final avgScore = catCount[e.key]! > 0
                ? (catPriority[e.key]! / catCount[e.key]!)
                : 0.0;
            
            return _CategoryBar(
              label: e.key,
              percent: pct,
              avgScore: avgScore,
            );
          }),
        ],
      ],
    );
  }
}

// ── Supporting Widgets ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8888AA), fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: Color(0xFFBBBBCC), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _CriticalAlertItem extends StatelessWidget {
  final dynamic task;
  const _CriticalAlertItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFFFF4757), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['name'] ?? 'Unnamed Task',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task['nudge_message'] ?? 'High impact on your grade!',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double percent;
  final double avgScore;

  const _CategoryBar({required this.label, required this.percent, required this.avgScore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('Avg Priority: ${(avgScore * 100).toStringAsFixed(0)}%', 
                style: const TextStyle(color: Color(0xFF8888AA), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFF2A2A4A),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}
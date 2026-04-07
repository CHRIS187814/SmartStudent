// screens/home_screen.dart — 3-tab Home: Dashboard, Task Master, Analytics

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dashboard_tab.dart';
import 'task_master_tab.dart';
import 'analytics_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Shared state: tasks list + dashboard data
  List<dynamic> _tasks     = [];
  Map<String, dynamic> _dashboard = {};
  bool _isLoading = true;

  final _api  = ApiService();
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final dash = await _api.getDashboard();
      setState(() {
        _dashboard = dash;
        _tasks     = dash['tasks'] as List? ?? [];
      });
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(
        dashboard: _dashboard,
        tasks: _tasks,
        onRefresh: _loadAll,
      ),
      TaskMasterTab(
        tasks: _tasks,
        onTaskAdded: _loadAll,
        onTaskCompleted: (id) async {
          await _api.completeTask(id);
          await _loadAll();
        },
        onTaskDeleted: (id) async {
          await _api.deleteTask(id);
          await _loadAll();
        },
      ),
      AnalyticsTab(
        tasks: _tasks,
        dashboard: _dashboard,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.psychology_rounded,
                color: Color(0xFF6C63FF), size: 26),
            const SizedBox(width: 8),
            const Text(
              'Smart Student',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8888AA)),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF8888AA)),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: Color(0xFF2A2A4A), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: const Color(0xFF0F0F1A),
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: const Color(0xFF8888AA),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Task Master',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:panikasog/services/task_service.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/post_provider.dart';
import '../providers/task_provider.dart';
import '../services/post_service.dart';
import 'home/home_screen.dart';
import 'home/create_post_screen.dart';
import 'tasks/tasks_screen.dart';
import 'tasks/task_detail_screen.dart';
import 'reports/reports_screen.dart';
import 'rankings/rankings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _fabMenuOpen = false;
  late AnimationController _fabAnimCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fabScale = CurvedAnimation(parent: _fabAnimCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() { _fabAnimCtrl.dispose(); super.dispose(); }

  void _toggleFab() {
    setState(() => _fabMenuOpen = !_fabMenuOpen);
    _fabMenuOpen ? _fabAnimCtrl.forward() : _fabAnimCtrl.reverse();
  }

  void _closeFab() {
    if (_fabMenuOpen) { setState(() => _fabMenuOpen = false); _fabAnimCtrl.reverse(); }
  }

  static const _screens = [
    HomeScreen(),
    TasksScreen(),
    SizedBox.shrink(),
    ReportsScreen(),
    RankingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider(PostService())),
        ChangeNotifierProvider(create: (_) => TaskProvider(TaskService())),
      ],
      child: Builder(builder: (ctx) => Scaffold(
        backgroundColor: AppColors.lightGrey,
        body: Stack(children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          if (_fabMenuOpen)
            GestureDetector(
              onTap: _closeFab,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ScaleTransition(
                      scale: _fabScale,
                      child: _FabMenu(
                        onClose: _closeFab,
                        onCreatePost: () { _closeFab(); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreatePostScreen())); },
                        onCreateTask: () { _closeFab(); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreateTaskScreen())); },
                        onCreateReport: () { _closeFab(); Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreateReportScreen())); },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]),
        bottomNavigationBar: _BottomBar(
          selectedIndex: _selectedIndex,
          fabOpen: _fabMenuOpen,
          onTap: (i) {
            if (i == 2) { _toggleFab(); }
            else { _closeFab(); setState(() => _selectedIndex = i); }
          },
        ),
      )),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedIndex; final bool fabOpen; final void Function(int) onTap;
  const _BottomBar({required this.selectedIndex, required this.fabOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: SafeArea(top: false, child: SizedBox(height: 64, child: Row(children: [
        _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', isActive: selectedIndex == 0, onTap: () => onTap(0)),
        _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Tasks', isActive: selectedIndex == 1, onTap: () => onTap(1)),
        Expanded(child: GestureDetector(
          onTap: () => onTap(2),
          child: Center(child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: fabOpen ? [const Color(0xFF7B003A), AppColors.primary] : AppColors.fabGradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: fabOpen ? 18 : 10, offset: const Offset(0, 4))],
            ),
            child: AnimatedRotation(
              turns: fabOpen ? 0.125 : 0, duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add, color: AppColors.white, size: 28),
            ),
          )),
        )),
        _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Reports', isActive: selectedIndex == 3, onTap: () => onTap(3)),
        _NavItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: 'Rankings', isActive: selectedIndex == 4, onTap: () => onTap(4)),
      ]))),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon; final String label; final bool isActive; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.hintGrey, size: 22),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? AppColors.primary : AppColors.hintGrey)),
    ]),
  ));
}

class _FabMenu extends StatelessWidget {
  final VoidCallback onClose, onCreateTask, onCreatePost, onCreateReport;
  const _FabMenu({required this.onClose, required this.onCreateTask, required this.onCreatePost, required this.onCreateReport});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      _FabMenuItem(icon: Icons.assignment_add, label: 'Create Task', onTap: onCreateTask),
      const SizedBox(width: 24),
      _FabMenuItem(icon: Icons.post_add, label: 'Create Post', onTap: onCreatePost),
      const SizedBox(width: 24),
      _FabMenuItem(icon: Icons.report_gmailerrorred_outlined, label: 'Create Report', onTap: onCreateReport),
    ],
  );
}

class _FabMenuItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _FabMenuItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 62, height: 62,
        decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))]),
        child: Icon(icon, color: AppColors.primary, size: 28)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.white)),
    ]),
  );
}
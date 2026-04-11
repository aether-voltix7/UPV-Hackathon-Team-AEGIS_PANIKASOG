import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import 'home/home_screen.dart';
import 'home/create_post_screen.dart';
import 'tasks/tasks_screen.dart';
import 'tasks/task_detail_screen.dart' show CreateTaskScreen;
import 'reports/reports_screen.dart';
import 'reports/create_report_screen.dart';
import 'rankings/rankings_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

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
    _fabAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fabScale =
        CurvedAnimation(parent: _fabAnimCtrl, curve: Curves.easeOutBack);

    // Sync current user into TaskProvider so myTasks filters correctly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<TaskProvider>().setCurrentUser(uid);
      }
    });
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabMenuOpen = !_fabMenuOpen);
    _fabMenuOpen ? _fabAnimCtrl.forward() : _fabAnimCtrl.reverse();
  }

  void _closeFab() {
    if (_fabMenuOpen) {
      setState(() => _fabMenuOpen = false);
      _fabAnimCtrl.reverse();
    }
  }

  static const _screens = [
    HomeScreen(),
    TasksScreen(),
    SizedBox.shrink(), // FAB placeholder
    ReportsScreen(),
    RankingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ⚠️  FIX: Do NOT wrap in another MultiProvider here.
    //     The root MultiProvider in main.dart already owns these instances.
    //     Creating new ones here caused every screen to use isolated,
    //     unshared state — data loaded in one screen was invisible to another.
    return Scaffold(
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
                  padding: const EdgeInsets.only(bottom: 90),
                  child: ScaleTransition(
                    scale: _fabScale,
                    child: _FabMenu(
                      onClose: _closeFab,
                      onCreatePost: () {
                        _closeFab();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreatePostScreen()));
                      },
                      onCreateTask: () {
                        _closeFab();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateTaskScreen()));
                      },
                      onCreateReport: () {
                        _closeFab();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateReportScreen()));
                      },
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
          if (i == 2) {
            _toggleFab();
          } else {
            _closeFab();
            setState(() => _selectedIndex = i);
          }
        },
      ),
    );
  }
}

// ─── Bottom Bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool fabOpen;
  final void Function(int) onTap;
  const _BottomBar(
      {required this.selectedIndex,
      required this.fabOpen,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, -6),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 69,
          child: Row(children: [
            _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: selectedIndex == 0,
                isLeftEdge: true,
                onTap: () => onTap(0)),
            _NavItem(
                icon: Icons.task_alt_outlined,
                activeIcon: Icons.task_alt,
                label: 'Tasks',
                isActive: selectedIndex == 1,
                onTap: () => onTap(1)),
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -7),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 69,
                      height: 69,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC10058),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC10058).withValues(alpha: 0.35),
                          blurRadius: fabOpen ? 18 : 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Reports',
                isActive: selectedIndex == 3,
                onTap: () => onTap(3)),
            _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Rankings',
                isActive: selectedIndex == 4,
                isRightEdge: true,
                onTap: () => onTap(4)),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final bool isLeftEdge;
  final bool isRightEdge;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.isActive,
      this.isLeftEdge = false,
      this.isRightEdge = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: isActive
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft:
                          isLeftEdge ? const Radius.circular(20) : Radius.zero,
                      topRight:
                          isRightEdge ? const Radius.circular(20) : Radius.zero,
                    ),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.white : Colors.black,
                  size: 31,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? AppColors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FabMenu extends StatelessWidget {
  final VoidCallback onClose, onCreateTask, onCreatePost, onCreateReport;
  const _FabMenu(
      {required this.onClose,
      required this.onCreateTask,
      required this.onCreatePost,
      required this.onCreateReport});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FabMenuItem(
              icon: Icons.assignment_add,
              label: 'Create Task',
              onTap: onCreateTask),
          const SizedBox(width: 24),
          _FabMenuItem(
              icon: Icons.post_add,
              label: 'Create Post',
              onTap: onCreatePost),
          const SizedBox(width: 24),
          _FabMenuItem(
              icon: Icons.report_gmailerrorred_outlined,
              label: 'Create Report',
              onTap: onCreateReport),
        ],
      );
}

class _FabMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FabMenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white)),
        ]),
      );
}
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../inspection/presentation/map_route_screen.dart';
import '../inspection/presentation/orders_list_screen.dart';
import '../inspection/presentation/seal_scanner_screen.dart';
import '../profile/presentation/inspector_profile_screen.dart';

class InspectorShellScreen extends StatefulWidget {
  const InspectorShellScreen({super.key});

  @override
  State<InspectorShellScreen> createState() => _InspectorShellScreenState();
}

class _InspectorShellScreenState extends State<InspectorShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    OrdersListScreen(),
    MapRouteScreen(),
    SealScannerScreen(),
    InspectorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryContainer,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: AppColors.primaryDark),
              label: 'Nhiệm vụ',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppColors.primaryDark),
              label: 'Bản đồ di chuyển',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primaryDark),
              label: 'Quét Tem',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge, color: AppColors.primaryDark),
              label: 'Hồ sơ KTV',
            ),
          ],
        ),
      ),
    );
  }
}

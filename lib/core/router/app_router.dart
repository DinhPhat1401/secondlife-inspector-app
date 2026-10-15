import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/inspector_shell_screen.dart';
import '../../features/inspection/models/inspection_order.dart';
import '../../features/inspection/presentation/checklist_execution_screen.dart';
import '../../features/inspection/presentation/order_detail_screen.dart';
import '../../features/inspection/presentation/seal_scanner_screen.dart';
import '../../features/inspection/presentation/seal_verification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const InspectorShellScreen(),
      ),
      GoRoute(
        path: '/order-detail',
        builder: (context, state) => OrderDetailScreen(
          order: state.extra as InspectionOrder?,
        ),
      ),
      GoRoute(
        path: '/checklist-execution',
        builder: (context, state) => ChecklistExecutionScreen(
          order: state.extra as InspectionOrder?,
        ),
      ),
      GoRoute(
        path: '/seal-scanner',
        builder: (context, state) => const SealScannerScreen(),
      ),
      GoRoute(
        path: '/seal-verification',
        builder: (context, state) => SealVerificationScreen(
          tamperSealId: state.extra as String?,
        ),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/dashboard/inspector_shell_screen.dart';
import '../../features/inspection/models/inspection_order.dart';
import '../../features/inspection/presentation/checklist_execution_screen.dart';
import '../../features/inspection/presentation/order_detail_screen.dart';
import '../../features/inspection/presentation/seal_scanner_screen.dart';
import '../../features/inspection/presentation/seal_verification_screen.dart';
import '../../features/inspection/presentation/inspector_payouts_screen.dart';
import '../../features/notifications/presentation/inspector_notifications_screen.dart';
import '../../features/chat/presentation/inspector_chat_center_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    if (state.matchedLocation == '/splash') {
      return null;
    }

    final authState = _ref.read(authProvider);
    final isLoggedIn = authState.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login';

    if (authState.isLoading) {
      return null;
    }

    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    if (isLoggedIn && isLoggingIn) {
      return '/dashboard';
    }
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
        builder: (context, state) {
          if (state.extra is InspectionOrder) {
            return OrderDetailScreen(order: state.extra as InspectionOrder);
          } else if (state.extra is String) {
            return OrderDetailScreen(orderId: state.extra as String);
          }
          return const OrderDetailScreen();
        },
      ),
      GoRoute(
        path: '/payouts',
        builder: (context, state) => const InspectorPayoutsScreen(),
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const InspectorNotificationsScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const InspectorChatCenterScreen(),
      ),
    ],
  );
});

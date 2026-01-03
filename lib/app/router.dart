import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/emergency/emergency_screen.dart';
import '../features/friends/friend_detail_screen.dart';
import '../features/logs/log_detail_screen.dart';
import '../features/logs/logs_screen.dart';
import '../features/settings/settings_screen.dart';
import 'boot_screen.dart';
import 'root_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/boot',
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => const BootScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const RootShell(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'logs',
            builder: (context, state) => const LogsScreen(),
          ),
          GoRoute(
            path: 'logs/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return LogDetailScreen(eventId: id ?? -1);
            },
          ),
          GoRoute(
            path: 'friends/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return FriendDetailScreen(friendId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/emergency',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            fullscreenDialog: true,
            barrierDismissible: false,
            child: const EmergencyScreen(),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
    ],
  );
});

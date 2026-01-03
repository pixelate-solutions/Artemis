import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/tab_controller.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/device/device_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_bottom_nav.dart';
import '../widgets/keep_alive.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  late final PageController _pageController;
  ProviderSubscription<int>? _tabSubscription;
  bool _isAnimating = false;
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(tabIndexProvider);
    _targetIndex = initialIndex;
    _pageController = PageController(initialPage: initialIndex);
    _tabSubscription = ref.listenManual<int>(tabIndexProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      final currentPage = _pageController.hasClients
          ? _pageController.page?.round()
          : null;
      if (currentPage == next) {
        _targetIndex = next;
        return;
      }
      _animateTo(next);
    });
  }

  @override
  void dispose() {
    _tabSubscription?.close();
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == ref.read(tabIndexProvider)) {
      return;
    }
    HapticFeedback.lightImpact();
    ref.read(tabIndexProvider.notifier).state = index;
  }

  void _animateTo(int index) {
    if (!_pageController.hasClients) {
      _targetIndex = index;
      return;
    }
    _isAnimating = true;
    _targetIndex = index;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (!mounted) {
            return;
          }
          _isAnimating = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(tabIndexProvider);
    return AppScaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (_isAnimating && index != _targetIndex) {
            return;
          }
          final wasAnimating = _isAnimating;
          _isAnimating = false;
          _targetIndex = index;
          if (!wasAnimating) {
            HapticFeedback.lightImpact();
          }
          ref.read(tabIndexProvider.notifier).state = index;
        },
        children: const [
          KeepAliveWrapper(child: ContactsScreen()),
          KeepAliveWrapper(child: DeviceScreen()),
          KeepAliveWrapper(child: HomeScreen()),
          KeepAliveWrapper(child: FriendsScreen()),
          KeepAliveWrapper(child: SettingsScreen()),
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        items: const [
          NavItem(icon: Icons.people_alt_rounded, label: 'Contacts'),
          NavItem(icon: Icons.bluetooth, label: 'Device'),
          NavItem(icon: Icons.home_filled, label: 'Home'),
          NavItem(icon: Icons.shield_rounded, label: 'Friends'),
          NavItem(icon: Icons.settings, label: 'Settings'),
        ],
        currentIndex: index,
        onTap: _onTap,
      ),
    );
  }
}

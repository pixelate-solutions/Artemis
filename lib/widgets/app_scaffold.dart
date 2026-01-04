import 'package:flutter/material.dart';

import '../app/constants.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final navHeight = bottomNavigationBar == null ? 0.0 : 80 + bottomInset;
    final bottomPadding = bottomNavigationBar == null || keyboardOpen ? 0.0 : navHeight;
    final navFillColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.96);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkBackground,
                  AppColors.darkSurface.withOpacity(0.95),
                ]
              : [
                  AppColors.lightBackground,
                  AppColors.primary.withOpacity(0.22),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (bottomNavigationBar != null && !keyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: navHeight,
              child: IgnorePointer(
                child: Container(
                  color: navFillColor,
                ),
              ),
            ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: body,
            ),
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            extendBody: true,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/feature_flags.dart';
import '../widgets/custom_bottom_bar.dart';
import 'challenges/challenges.dart';
import 'home_dashboard/home_dashboard_tab.dart';
import 'personal_analytics/personal_analytics.dart';
import 'plunge_timer/plunge_timer.dart';

/// Main navigation scaffold with IndexedStack to preserve tab state
/// This prevents unnecessary rebuilds and data refetches when switching tabs
class MainNavigationScaffold extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold>
    with AutomaticKeepAliveClientMixin {
  late int _currentIndex;

  // Keep all tab widgets alive to preserve state
  late final List<Widget> _tabs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Initialize all tabs once
    _tabs = [
      const HomeDashboardTab(),
      const PlungeTimer(),
      if (kEnableChallenges) const Challenges(),
      const PersonalAnalytics(),
    ];
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      // Use IndexedStack to keep all tabs alive and preserve state
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

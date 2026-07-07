import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_bottom_nav_tab.dart';
import '../../navigation/app_navigation_state.dart';

const double kAppBottomNavigationBarHeight = 76;

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationState = context.watch<AppNavigationState>();
    final currentTab = navigationState.selectedTab;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: kAppBottomNavigationBarHeight + bottomPadding,
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF040707),
        border: Border(
          top: BorderSide(
            color: Color(0xFF616161),
            width: 1.0,
          ),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppBottomNavTab.valuesList
              .map(
                (tab) => _BottomNavigationItem(
                  tab: tab,
                  isSelected: currentTab == tab,
                  onTap: () => navigationState.setSelectedTab(tab),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFF4F4F4)
        : const Color(0xFFBDBDBD);

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SvgPicture.asset(
            tab.assetPath,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}

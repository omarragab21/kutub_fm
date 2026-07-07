enum AppBottomNavTab {
  community(tabIndex: 0, label: 'المجتمع', assetPath: 'assets/nav_community.svg'),
  radio(tabIndex: 1, label: 'الإذاعة', assetPath: 'assets/nav_radio.svg'),
  home(tabIndex: 2, label: 'الرئيسية', assetPath: 'assets/nav_home.svg'),
  library(tabIndex: 3, label: 'المكتبة', assetPath: 'assets/nav_books.svg'),
  reels(tabIndex: 4, label: 'الريلز', assetPath: 'assets/nav_reels.svg');

  const AppBottomNavTab({
    required this.tabIndex,
    required this.label,
    required this.assetPath,
  });

  final int tabIndex;
  final String label;
  final String assetPath;

  static const List<AppBottomNavTab> valuesList = values;

  static AppBottomNavTab fromIndex(int index) {
    return values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => AppBottomNavTab.home,
    );
  }
}

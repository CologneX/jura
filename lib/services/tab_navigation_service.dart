import 'dart:async';

class TabNavigationService {
  final _tabController = StreamController<int>.broadcast();
  Stream<int> get onTabChanged => _tabController.stream;

  void switchTab(int index) {
    _tabController.add(index);
  }

  void dispose() {
    _tabController.close();
  }
}

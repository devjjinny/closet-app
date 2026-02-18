import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: '옷장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny),
            label: '오늘 코디',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '기록',
          ),
        ],
      ),
    );
  }
}

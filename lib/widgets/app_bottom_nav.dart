import 'package:flutter/material.dart';
import 'package:tbc_app/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppBottomNav
//
//  Widget bottom navigation bar yang bisa dipakai ulang di semua halaman.
//
//  Cara pakai:
//    bottomNavigationBar: AppBottomNav(
//      currentIndex: _currentIndex,
//      onTap: (i) => setState(() => _currentIndex = i),
//    ),
//
//  Letakkan file ini di:  lib/widgets/app_bottom_nav.dart
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(icon: Icons.home_rounded, label: 'Beranda'),
    _NavItemData(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    _NavItemData(icon: Icons.bar_chart_rounded, label: 'Statistik'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: List.generate(
          _items.length,
          (i) => Expanded(
            child: _NavItem(
              data: _items[i],
              isActive: currentIndex == i,
              onTap: () => onTap(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            child: Text(data.label),
          ),
        ],
      ),
    );
  }
}
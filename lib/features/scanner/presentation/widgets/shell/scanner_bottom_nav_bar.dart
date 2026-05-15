import 'package:flutter/material.dart';

import '../../../../../core/theme/motion_tokens.dart';
import '../../../state/scanner_state.dart';
import 'scanner_shell_colors.dart';

class ScannerBottomNavBar extends StatelessWidget {
  const ScannerBottomNavBar({
    super.key,
    required this.state,
    required this.motion,
  });

  final ScannerState state;
  final MotionTokens motion;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 0,
      elevation: 10,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      child: Row(
        children: [
          _BottomItem(
            motion: motion,
            icon: Icons.home_outlined,
            label: 'Home',
            selected: state.activeMenu == AppMenu.home,
            onTap: () => state.setActiveMenu(AppMenu.home),
          ),
          _BottomItem(
            motion: motion,
            icon: Icons.sensors_rounded,
            label: 'Checking',
            selected: state.activeMenu == AppMenu.history,
            onTap: () => state.setActiveMenu(AppMenu.history),
          ),
          const SizedBox(width: 72),
          _BottomItem(
            motion: motion,
            icon: Icons.settings_outlined,
            label: 'Settings',
            selected: state.activeMenu == AppMenu.settings,
            onTap: () => state.setActiveMenu(AppMenu.settings),
          ),
          _BottomItem(
            motion: motion,
            icon: Icons.person_outline,
            label: 'Profile',
            selected: state.activeMenu == AppMenu.profile,
            onTap: () => state.setActiveMenu(AppMenu.profile),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.motion,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MotionTokens motion;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? ScannerShellColors.primaryBlue
        : ScannerShellColors.inactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: motion.medium,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: motion.short,
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: motion.medium,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0x143155FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
              ),
              const SizedBox(height: 0),
              AnimatedDefaultTextStyle(
                duration: motion.short,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: selected ? 9.5 : 9,
                  height: 1,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedContainer(
                duration: motion.short,
                width: selected ? 16 : 0,
                height: selected ? 2 : 0,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: ScannerShellColors.primaryBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

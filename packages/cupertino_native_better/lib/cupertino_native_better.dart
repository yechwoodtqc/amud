import 'package:flutter/material.dart';

/// The API surface Amud uses from cupertino_native_better. This Android 6
/// build uses Flutter widgets instead of iOS 26 native controls.
class PlatformVersion {
  static bool get isIOS26OrLater => false;
}

class CNTabBarRouteObserver extends NavigatorObserver {}

class CNTabBarItem {
  final String? label;
  final Widget icon;
  final Widget activeIcon;

  const CNTabBarItem({
    this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class CNTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? tint;
  final double iconSize;
  final List<CNTabBarItem> items;

  const CNTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.tint,
    this.iconSize = 24,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: tint,
        type: BottomNavigationBarType.fixed,
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              icon: item.icon,
              activeIcon: item.activeIcon,
              label: item.label ?? '',
            ),
        ],
      );
}

/// A small SF Symbol fallback. The Android build uses Material icons.
Widget CNSymbol(String name, {double size = 24}) {
  final n = name.toLowerCase();
  final IconData icon = n.contains('house') || n.contains('home')
      ? Icons.home_outlined
      : n.contains('book') || n.contains('text')
          ? Icons.menu_book_outlined
          : n.contains('clock') || n.contains('sun')
              ? Icons.access_time
              : n.contains('gear') || n.contains('setting')
                  ? Icons.settings_outlined
                  : n.contains('calendar')
                      ? Icons.calendar_month_outlined
                      : Icons.circle_outlined;
  return Icon(icon, size: size);
}

class CNAlertAction<T> {
  final String label;
  final T value;
  final bool isCancel;
  final bool isDefault;

  const CNAlertAction({
    required this.label,
    required this.value,
    this.isCancel = false,
    this.isDefault = false,
  });
}

class CNAlertResult<T> {
  final T value;
  const CNAlertResult(this.value);
}

class CNAlert {
  static Future<CNAlertResult<T>?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<CNAlertAction<T>> actions,
  }) async {
    final value = await showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: title == null ? null : Text(title),
        content: message == null ? null : Text(message),
        actions: [
          for (final action in actions)
            TextButton(
              onPressed: () => Navigator.pop(ctx, action.value),
              child: Text(action.label),
            ),
        ],
      ),
    );
    return value == null ? null : CNAlertResult<T>(value);
  }
}

class CNActionSheetAction<T> {
  final String label;
  final T value;

  const CNActionSheetAction({required this.label, required this.value});
}

class CNActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    Rect? anchorRect,
    String? title,
    String? cancelLabel,
    required List<CNActionSheetAction<T>> actions,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                ),
              for (final action in actions)
                ListTile(
                  title: Text(action.label),
                  onTap: () => Navigator.pop(ctx, action.value),
                ),
              if (cancelLabel != null)
                ListTile(
                  title: Text(cancelLabel),
                  onTap: () => Navigator.pop(ctx),
                ),
            ],
          ),
        ),
      );
}

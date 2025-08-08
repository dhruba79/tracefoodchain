import 'package:flutter/material.dart';

/// A safe alternative to PopupMenuButton that doesn't use LayoutBuilder
/// and prevents the "Looking up a deactivated widget's ancestor is unsafe" error
class SafePopupMenuButton<T> extends StatefulWidget {
  final Widget? icon;
  final Color? surfaceTintColor;
  final String? tooltip;
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final void Function(T)? onSelected;

  const SafePopupMenuButton({
    super.key,
    this.icon,
    this.surfaceTintColor,
    this.tooltip,
    required this.itemBuilder,
    this.onSelected,
  });

  @override
  State<SafePopupMenuButton<T>> createState() => _SafePopupMenuButtonState<T>();
}

class _SafePopupMenuButtonState<T> extends State<SafePopupMenuButton<T>> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    return GestureDetector(
      key: _buttonKey,
      onTap: _showMenu,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: widget.icon ?? const Icon(Icons.more_vert),
      ),
    );
  }

  void _showMenu() {
    if (!mounted) return;

    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _MenuOverlay<T>(
        position: position + Offset(size.width, 0),
        items: widget.itemBuilder(context),
        onSelected: (value) {
          _closeMenu();
          widget.onSelected?.call(value);
        },
        onDismiss: _closeMenu,
        surfaceTintColor: widget.surfaceTintColor,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }
}

class _MenuOverlay<T> extends StatelessWidget {
  final Offset position;
  final List<PopupMenuEntry<T>> items;
  final void Function(T) onSelected;
  final VoidCallback onDismiss;
  final Color? surfaceTintColor;

  const _MenuOverlay({
    required this.position,
    required this.items,
    required this.onSelected,
    required this.onDismiss,
    this.surfaceTintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible barrier to detect taps outside
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
          ),
        ),
        // The actual menu
        Positioned(
          left: position.dx - 200, // Adjust position as needed
          top: position.dy,
          child: Material(
            elevation: 8,
            color: surfaceTintColor ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  if (item is PopupMenuItem<T>) {
                    return InkWell(
                      onTap: () {
                        if (item.value != null) {
                          onSelected(item.value!);
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 200),
                        child: item.child,
                      ),
                    );
                  }
                  return item;
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

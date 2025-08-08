import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugValueListenableBuilder<T> extends StatefulWidget {
  const DebugValueListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.builder,
    this.child,
    required this.debugName,
  });

  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;
  final String debugName;

  @override
  State<DebugValueListenableBuilder<T>> createState() =>
      _DebugValueListenableBuilderState<T>();
}

class _DebugValueListenableBuilderState<T>
    extends State<DebugValueListenableBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
    debugPrint(
        "🎯 DebugValueListenableBuilder '${widget.debugName}' initialized");
  }

  @override
  void didUpdateWidget(DebugValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
      debugPrint(
          "🔄 DebugValueListenableBuilder '${widget.debugName}' updated");
    }
  }

  @override
  void dispose() {
    debugPrint(
        "🗑️ DebugValueListenableBuilder '${widget.debugName}' disposing");
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    debugPrint(
        "🔔 DebugValueListenableBuilder '${widget.debugName}' value changed, mounted: $mounted");

    if (!mounted) {
      debugPrint(
          "❌ DebugValueListenableBuilder '${widget.debugName}' received value change but is not mounted!");
      return;
    }

    setState(() {
      value = widget.valueListenable.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "🏗️ DebugValueListenableBuilder '${widget.debugName}' building, mounted: $mounted");

    if (!mounted) {
      debugPrint(
          "❌ DebugValueListenableBuilder '${widget.debugName}' building but not mounted!");
      return Container();
    }

    return widget.builder(context, value, widget.child);
  }
}

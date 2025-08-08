import 'package:flutter/foundation.dart';

/// Wrapper für ValueNotifier der alle Listener trackt
class TrackedValueNotifier<T> extends ValueNotifier<T> {
  final String name;
  final Set<VoidCallback> _trackedListeners = {};

  TrackedValueNotifier(super.value, this.name);

  @override
  void addListener(VoidCallback listener) {
    debugPrint(
        "➕ Adding listener to '$name'. Total: ${_trackedListeners.length + 1}");
    _trackedListeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    debugPrint(
        "➖ Removing listener from '$name'. Total: ${_trackedListeners.length - 1}");
    _trackedListeners.remove(listener);
    super.removeListener(listener);
  }

  @override
  void notifyListeners() {
    debugPrint("🔔 '$name' notifying ${_trackedListeners.length} listeners");
    try {
      super.notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("❌ Error notifying listeners for '$name': $e");
      debugPrint("Stack trace:");
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  @override
  set value(T newValue) {
    debugPrint("🔄 '$name' value changing from $value to $newValue");
    super.value = newValue;
  }

  @override
  void dispose() {
    debugPrint(
        "🗑️ '$name' disposing with ${_trackedListeners.length} listeners");
    _trackedListeners.clear();
    super.dispose();
  }
}

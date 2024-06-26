import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:proxima/views/helpers/types/future_void_callback.dart";

/// An async capable button that displays a [CircularProgressIndicator] once it is pressed
/// and until the future of the callback function completes.
class LoadingIconButton extends HookWidget {
  static const _defaultIconSize = 26.0;
  static const _containerSide = 40.0;

  final FutureVoidCallback onClick;
  final IconData icon;
  final double iconSize;

  const LoadingIconButton({
    super.key,
    required this.onClick,
    required this.icon,
    this.iconSize = _defaultIconSize,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(LoadingState.still);

    final stillIconButton = IconButton(
      icon: Icon(icon, size: iconSize),
      onPressed: () async {
        isLoading.value = LoadingState.pending;
        await onClick();
        // Check that the widget was not already disposed
        if (context.mounted) {
          isLoading.value = LoadingState.completed;
        }
      },
    );

    final loading = Center(
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: const CircularProgressIndicator(),
      ),
    );

    final checkButton = IconButton(
      icon: Icon(Icons.check, size: iconSize),
      onPressed: null,
    );

    return SizedBox(
      width: _containerSide,
      height: _containerSide,
      child: switch (isLoading.value) {
        LoadingState.still => stillIconButton,
        LoadingState.pending => loading,
        LoadingState.completed => checkButton,
      },
    );
  }
}

class DeleteButton extends LoadingIconButton {
  const DeleteButton({super.key, required super.onClick})
      : super(icon: Icons.delete);
}

enum LoadingState {
  still,
  pending,
  completed,
}

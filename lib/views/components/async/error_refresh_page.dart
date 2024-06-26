import "package:flutter/material.dart";

/// A widget that displays an error message and a refresh button. On clicking the
/// refresh button, the [onRefresh] function is called.
class ErrorRefreshPage extends StatelessWidget {
  final void Function() onRefresh;

  static const refreshButtonKey = Key("refreshButton");
  static const errorText = "An error occurred.";
  static const refreshText = "Refresh";

  const ErrorRefreshPage({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final refreshButton = ElevatedButton(
      key: refreshButtonKey,
      onPressed: onRefresh,
      child: const Text(refreshText),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(errorText),
          const SizedBox(height: 10),
          refreshButton,
        ],
      ),
    );
  }
}

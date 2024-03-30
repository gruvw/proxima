import "package:flutter/material.dart";

/// This widget defines the style of the cards in the profile page,
/// such as badges, posts and comments
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}

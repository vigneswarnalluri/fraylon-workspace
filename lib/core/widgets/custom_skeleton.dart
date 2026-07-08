import 'package:flutter/material.dart';

class CustomSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shape;

  const CustomSkeleton({
    super.key,
    this.width,
    this.height,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
  });

  const CustomSkeleton.avatar({
    super.key,
    double size = 40,
  })  : width = size,
        height = size,
        shape = const CircleBorder();

  const CustomSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
  }) : shape = const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        );

  const CustomSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  }) : shape = const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);

    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.1, 0.5, 0.9],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
        ),
      ),
    );
  }
}

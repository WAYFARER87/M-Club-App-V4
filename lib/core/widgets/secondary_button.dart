import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
  });

  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ButtonStyle style = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      minimumSize: const Size(48, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
    ).copyWith(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return colorScheme.surfaceVariant;
        }
        return colorScheme.secondaryContainer;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return colorScheme.onSurface.withOpacity(0.38);
        }
        return colorScheme.onSecondaryContainer;
      }),
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return colorScheme.secondary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.hovered) ||
            states.contains(MaterialState.focused)) {
          return colorScheme.secondary.withOpacity(0.08);
        }
        return null;
      }),
    );

    if (icon != null) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 20),
        label: Text(text),
      );
    }

    return FilledButton.tonal(
      onPressed: onPressed,
      style: style,
      child: Text(text),
    );
  }
}

import 'package:flutter/material.dart';

DropdownMenuItem<String> customDropdownItem({
  required BuildContext context,
  required String title,
  required String value,
  required IconData icon,
}) {
  return DropdownMenuItem<String>(
    value: value,
    alignment: AlignmentDirectional.centerStart,
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

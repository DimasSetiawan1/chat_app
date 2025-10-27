import 'package:flutter/material.dart';

class CustomAutocomplete<T extends Object> extends StatelessWidget {
  const CustomAutocomplete({
    super.key,
    required this.labelText,
    required this.optionsBuilder,
    required this.onSelected,
    required this.displayStringForOption,
  });

  final String labelText;
  final Future<List<T>> Function(TextEditingValue) optionsBuilder;
  final void Function(T) onSelected;
  final String Function(T) displayStringForOption;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>( 
      displayStringForOption: displayStringForOption,
      optionsBuilder: optionsBuilder,
      onSelected: onSelected,
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldTextEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
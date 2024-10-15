// custom_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trace_foodchain_app/main.dart';

class CustomTextField extends StatelessWidget {
  final String? title;
  final Color? textColor;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final String? hintText;
  final bool obscureText;
  final bool isPasswordField;
  final bool centerText;
  final int maxLines;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.title,
    this.textColor,
    this.validator,
    this.suffixIcon,
    this.hintText,
    this.obscureText = false,
    this.isPasswordField = false,
    this.centerText = false,
    this.maxLines = 1,
    this.onTap,
    this.onFieldSubmitted,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: customTheme,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
            ],
            TextFormField(
              controller: controller,
              validator: validator,
              obscureText: obscureText,
              textAlign: centerText ? TextAlign.center : TextAlign.start,
              maxLines: maxLines,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              focusNode: focusNode,
              onTap: onTap,
              inputFormatters: inputFormatters,
              style: TextStyle(
                fontSize: 16,
                color: textColor ?? Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
                errorText: errorText,
                isDense: true,
                contentPadding: EdgeInsets.all(suffixIcon != null ? 10 : 15),
                border: _border(),
                focusedBorder: _border(),
                enabledBorder: _border(),
                suffixIcon: suffixIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputBorder _border() => const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      );
}
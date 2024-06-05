import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  CustomTextField({
    required this.controller,
    required this.label,
    this.obscureText = false, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: TextField(
        keyboardType: keyboardType,
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/login_view_model.dart';
import 'package:flutter/services.dart';

class PasswordInputField extends StatelessWidget {
  const PasswordInputField({super.key, required this.isWeb});
  final bool isWeb;

  static const int maxPasswordLength = 25;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);
    return TextField(
      controller: viewModel.passwordController,
      obscureText: viewModel.isObscure,
      enableInteractiveSelection: false,
      contextMenuBuilder: (context, editableTextState) {
        return const SizedBox.shrink();
      },

      // --- max length enforcement ---
      maxLength: maxPasswordLength,
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxPasswordLength),
      ],

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        border: isWeb ? const OutlineInputBorder() : null,
        icon: Icon(Icons.lock_outline, color: isWeb ? Colors.black : Colors.white),
        labelText: 'Password',
        labelStyle: const TextStyle(color: Colors.black),
        suffixIcon: IconButton(
          icon: Icon(viewModel.isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.black87),
          onPressed: viewModel.onIsObscureChanged,
        ),
        counterText: '', // hides the "x/20" counter Flutter shows by default with maxLength
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}
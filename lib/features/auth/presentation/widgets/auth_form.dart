import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';

class AuthForm extends StatefulWidget {
  final Function(String email, String password) onSubmit;
  final String submitButtonText;
  final bool showForgotPassword;
  final bool isRegistration;

  const AuthForm({
    Key? key,
    required this.onSubmit,
    this.submitButtonText = 'Submit',
    this.showForgotPassword = false,
    this.isRegistration = false,
  }) : super(key: key);

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: widget.isRegistration
                  ? 'Create a strong password'
                  : 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            obscureText: !_isPasswordVisible,
            validator: widget.isRegistration
                ? Validators
                    .validateStrongPassword // Use strong password validation for registration
                : Validators.validatePassword, // Use basic validation for login
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          if (widget.isRegistration)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Password must have 8+ characters with uppercase, lowercase, number and special character',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          if (widget.showForgotPassword)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password functionality
                },
                child: const Text('Forgot Password?'),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(widget.submitButtonText),
          ),
        ],
      ),
    );
  }
}

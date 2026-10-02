import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: AppColors.darkNavyBlue,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavyBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Login to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email';
                      if (!value.contains('@'))
                        return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    onSuffixTap: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your password';
                      if (value.length < 8)
                        return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return AppButton(
                        text: 'Login',
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  final success = await auth.login(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/customer',
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          auth.errorMessage ?? 'Login failed',
                                        ),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                }
                              },
                      );
                    },
                  ),
                  if (context.watch<AuthProvider>().errorMessage != null &&
                      !context.watch<AuthProvider>().isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        context.watch<AuthProvider>().errorMessage!,
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: AppColors.secondaryNavyBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkNavyBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavyBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Join the Homecare Platform',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your first name';
                      if (value.length < 2)
                        return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your last name';
                      if (value.length < 2)
                        return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email';
                      if (!value.contains('@'))
                        return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your phone number';
                      if (value.length < 7)
                        return 'Phone number must be at least 7 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    onSuffixTap: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a password';
                      if (value.length < 8)
                        return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    onSuffixTap: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please confirm your password';
                      if (value != _passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return AppButton(
                        text: 'Register',
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  final success = await auth.register(
                                    firstName: _firstNameController.text.trim(),
                                    lastName: _lastNameController.text.trim(),
                                    email: _emailController.text.trim(),
                                    phoneNumber: _phoneController.text.trim(),
                                    password: _passwordController.text,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/customer',
                                      (route) => false,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          auth.errorMessage ??
                                              'Registration failed',
                                        ),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                }
                              },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: AppColors.secondaryNavyBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, AppRoutes.initial);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back!'),
            backgroundColor: AppTheme.successLight,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sign in failed: ${error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    Navigator.pushNamed(context, AppRoutes.signUpScreen);
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    try {
      await AuthService.instance.resetPassword(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email'),
            backgroundColor: AppTheme.successLight,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to send reset link: ${error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),

              // Logo and Title
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'ac_unit',
                  size: 60,
                  color: AppTheme.accentLight,
                ),
              ),

              SizedBox(height: 3.h),

              Text(
                'ColdPlunge Pro',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 1.h),

              Text(
                'Transform your wellness journey',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              SizedBox(height: 6.h),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: CustomIconWidget(
                          iconName: 'email',
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: CustomIconWidget(
                          iconName: 'lock',
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: CustomIconWidget(
                            iconName: _obscurePassword
                                ? 'visibility'
                                : 'visibility_off',
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Demo Credentials Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'info',
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Demo Credentials',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          _buildDemoCredential(
                            'Admin User',
                            'admin@coldplunge.com',
                            'password123',
                            theme,
                          ),
                          SizedBox(height: 1.h),
                          _buildDemoCredential(
                            'Sarah Johnson',
                            'sarah@example.com',
                            'password123',
                            theme,
                          ),
                          SizedBox(height: 1.h),
                          _buildDemoCredential(
                            'Mike Rodriguez',
                            'mike@example.com',
                            'password123',
                            theme,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 6.h),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: _signUp,
                          child: Text(
                            'Sign Up',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredential(
    String name,
    String email,
    String password,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        _emailController.text = email;
        _passwordController.text = password;
        _signIn();
      },
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '$email / $password',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'login',
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

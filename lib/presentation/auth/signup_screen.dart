import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );

      if (response.user != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Account created successfully! Please check your email to verify your account.'),
            backgroundColor: AppTheme.successLight,
          ),
        );

        // Navigate back to login
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sign up failed: ${error.toString().replaceAll('Exception: ', '')}'),
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

  void _navigateToSignIn() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _navigateToSignIn,
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 4.h),

              // Logo and Title
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'ac_unit',
                  size: 48,
                  color: AppTheme.accentLight,
                ),
              ),

              SizedBox(height: 3.h),

              Text(
                'Create Account',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 1.h),

              Text(
                'Join the cold plunge community',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              SizedBox(height: 4.h),

              // Sign Up Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: CustomIconWidget(
                          iconName: 'person',
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

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
                      textInputAction: TextInputAction.next,
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
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signUp(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
                        prefixIcon: CustomIconWidget(
                          iconName: 'lock',
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          icon: CustomIconWidget(
                            iconName: _obscureConfirmPassword
                                ? 'visibility'
                                : 'visibility_off',
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Terms and Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) =>
                              setState(() => _acceptTerms = value ?? false),
                          activeColor: AppTheme.accentLight,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _acceptTerms = !_acceptTerms),
                            child: Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
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
                                'Create Account',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToSignIn,
                          child: Text(
                            'Sign In',
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
}

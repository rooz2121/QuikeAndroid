import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import '../../services/supabase_service.dart';
import '../main_chat_page..dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _acceptedTerms = true;
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: Colors.pinkAccent.withOpacity(0.4),
                spawnMinSpeed: 5.0,
                spawnMaxSpeed: 20.0,
                spawnMinRadius: 1.0,
                spawnMaxRadius: 2.0,
                particleCount: 80,
                image: null,
              ),
            ),
            vsync: this,
            child: Container(),
          ),
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.pinkAccent.withOpacity(0.7), width: 2),
                        ),
                        child: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.18),
                            radius: 40,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        'Quike AI',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.pinkAccent.withOpacity(0.5), offset: const Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Name field
                      _glowingTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_outline,
                        obscureText: false,
                        glowColor: Colors.pinkAccent,
                      ),
                      const SizedBox(height: 16),
                      
                      // Email field
                      _glowingTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        obscureText: false,
                        glowColor: Colors.pinkAccent,
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
                      _glowingTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        glowColor: Colors.pinkAccent,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm Password field
                      _glowingTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        glowColor: Colors.pinkAccent,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Terms and conditions
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value ?? true;
                                });
                              },
                              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                return Colors.pinkAccent;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[300], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[300], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // Sign up button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            // Validate inputs
                            if (_nameController.text.isEmpty ||
                                _emailController.text.isEmpty ||
                                _passwordController.text.isEmpty ||
                                _confirmPasswordController.text.isEmpty) {
                              setState(() {
                                _errorMessage = 'Please fill in all fields';
                              });
                              return;
                            }
                            
                            // Validate password match
                            if (_passwordController.text != _confirmPasswordController.text) {
                              setState(() {
                                _errorMessage = 'Passwords do not match. Please make sure both passwords are identical.';
                              });
                              return;
                            }
                            
                            // Validate password strength
                            if (_passwordController.text.length < 8) {
                              setState(() {
                                _errorMessage = 'Password must be at least 8 characters long.';
                              });
                              return;
                            }
                            
                            if (!_acceptedTerms) {
                              setState(() {
                                _errorMessage = 'You must accept the Terms of Service';
                              });
                              return;
                            }
                            
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            
                            try {
                              final response = await _supabaseService.signUp(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                                fullName: _nameController.text.trim(),
                              );
                              
                              if (response.user != null) {
                                // Show success notification
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Account created successfully!'),
                                      backgroundColor: Colors.green[700],
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // Navigate to chat page after a short delay to allow notification to be seen
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ChatPage()),
                                      );
                                    }
                                  });
                                }
                              } else {
                                setState(() {
                                  _isLoading = false;
                                  
                                  // Get error message from the response
                                  final errorMsg = 'Failed to create account';
                                  
                                  if (errorMsg.contains('already registered')) {
                                    _errorMessage = 'This email is already registered. Please try logging in instead.';
                                  } else if (errorMsg.contains('password')) {
                                    _errorMessage = 'Password is too weak. Please use at least 8 characters with numbers and special characters.';
                                  } else if (errorMsg.contains('email')) {
                                    _errorMessage = 'Please enter a valid email address.';
                                  } else {
                                    _errorMessage = 'Signup failed: $errorMsg';
                                  }
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                                final errorMsg = e.toString();
                                
                                // Handle common error messages
                                if (errorMsg.contains('already registered') || errorMsg.contains('already exists')) {
                                  _errorMessage = 'This email is already registered. Please try logging in instead.';
                                } else if (errorMsg.contains('network')) {
                                  _errorMessage = 'Network error. Please check your internet connection and try again.';
                                } else {
                                  _errorMessage = 'Error: $e';
                                }
                              });
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Colors.pinkAccent.withOpacity(0.5),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate back to login page
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Glowing text field widget
  Widget _glowingTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required Color glowColor,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: glowColor),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[850]?.withOpacity(0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glowColor.withOpacity(0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glowColor.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glowColor, width: 2),
        ),
      ),
    );
  }
}

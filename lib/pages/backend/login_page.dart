import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import '../../services/supabase_service.dart';
import '../main_chat_page..dart' as main_chat;
import '../trial_chat_page.dart' as trial_chat;
import '../home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final _supabaseService = SupabaseService();
  
  // Animation controller for error shake effect
  late final AnimationController _shakeController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  late final Animation<Offset> _shakeAnimation = Tween<Offset>(
    begin: const Offset(0, 0),
    end: const Offset(0.05, 0),
  ).animate(CurvedAnimation(
    parent: _shakeController,
    curve: Curves.elasticIn,
  ));

  @override
  void dispose() {
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Method to animate error shake effect
  void _animateErrorShake() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }
  
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
                baseColor: Colors.blueAccent.withOpacity(0.4),
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
                          color: Colors.blueAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.7), width: 2),
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
                            Shadow(blurRadius: 10, color: Colors.blueAccent.withOpacity(0.5), offset: const Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Email field
                      SlideTransition(
                        position: _shakeAnimation,
                        child: _glowingTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          icon: Icons.email_outlined,
                          obscureText: false,
                          glowColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
                      SlideTransition(
                        position: _shakeAnimation,
                        child: _glowingTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          glowColor: Colors.blueAccent,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[400],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            // Show forgot password dialog
                            final emailController = TextEditingController();
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text('Reset Password', style: TextStyle(color: Colors.white)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Enter your email to receive a password reset link',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    const SizedBox(height: 16),
                                    _glowingTextField(
                                      controller: emailController,
                                      hintText: 'Email',
                                      icon: Icons.email_outlined,
                                      obscureText: false,
                                      glowColor: Colors.blueAccent,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Send Link', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (result == true && emailController.text.isNotEmpty) {
                              try {
                                await _supabaseService.resetPassword(emailController.text.trim());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Password reset link sent to your email'),
                                      backgroundColor: Colors.green[700],
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red[700],
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ),
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
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            // Validate inputs
                            if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                              setState(() {
                                _errorMessage = 'Please enter both email and password';
                              });
                              return;
                            }
                            
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            
                            try {
                              final response = await _supabaseService.signIn(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );
                              
                              if (response.user != null) {
                                // Show success notification
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Login successful!'),
                                      backgroundColor: Colors.green[700],
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // Navigate to chat page after a short delay to allow notification to be seen
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const main_chat.ChatPage()),
                                      );
                                    }
                                  });
                                }
                              } else {
                                setState(() {
                                  _isLoading = false;
                                  
                                  // Get error message from the response
                                  final errorMsg = 'Invalid login credentials';
                                  
                                  // Handle specific error cases with user-friendly messages
                                  if (errorMsg.contains('Invalid login credentials')) {
                                    _errorMessage = 'Invalid email or password. Please check your credentials and try again.';
                                  } else if (errorMsg.contains('Email not confirmed')) {
                                    _errorMessage = 'Please verify your email address before logging in.';
                                  } else if (errorMsg.contains('rate limit')) {
                                    _errorMessage = 'Too many login attempts. Please try again later.';
                                  } else if (errorMsg.contains('User already registered')) {
                                    _errorMessage = 'This email is already registered. Try logging in instead.';
                                  } else {
                                    _errorMessage = errorMsg;
                                  }
                                });
                                
                                // Vibrate the input fields to indicate error
                                _animateErrorShake();
                              }
                            } catch (e) {
                              setState(() {
                                _errorMessage = 'Error: ${e.toString()}';
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
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Colors.blueAccent.withOpacity(0.5),
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
                                'Login',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to sign up page
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupPage()),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Try without login button
                      TextButton(
                        onPressed: () {
                          // Navigate to trial chat page as demo user
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const trial_chat.ChatPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Text(
                          'Try Quike AI without login',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      
                      // Home page link
                      TextButton(
                        onPressed: () {
                          // Navigate to home page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const TrialChatPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Text(
                          'Home',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
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

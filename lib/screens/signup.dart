import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstapp/screens/homepage/homepage.dart';
import 'package:firstapp/service/google_signin_service.dart';
import 'package:firstapp/service/authservice.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _topRightController;
  late AnimationController _topRightSmallController;
  late AnimationController _bottomLeftController;
  late AnimationController _bottomLeftSmallController;
  late AnimationController _bottomRightController;
  
  late Animation<Offset> _topRightAnimation;
  late Animation<Offset> _topRightSmallAnimation;
  late Animation<Offset> _bottomLeftAnimation;
  late Animation<Offset> _bottomLeftSmallAnimation;
  late Animation<Offset> _bottomRightAnimation;

  final GoogleSignInService _googleSignInService = GoogleSignInService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  @override
  void initState() {
    super.initState();
    
    _topRightController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _topRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-15, 10),
    ).animate(CurvedAnimation(parent: _topRightController, curve: Curves.easeInOut));
    
    _topRightSmallController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _topRightSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(10, -15),
    ).animate(CurvedAnimation(parent: _topRightSmallController, curve: Curves.easeInOut));
    
    _bottomLeftController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(12, -18),
    ).animate(CurvedAnimation(parent: _bottomLeftController, curve: Curves.easeInOut));
    
    _bottomLeftSmallController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-8, 12),
    ).animate(CurvedAnimation(parent: _bottomLeftSmallController, curve: Curves.easeInOut));
    
    _bottomRightController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    _bottomRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-12, -15),
    ).animate(CurvedAnimation(parent: _bottomRightController, curve: Curves.easeInOut));
  }

  Future<void> _handleEmailPasswordSignUp() async {
    if (_isLoading || _isProcessing) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _isProcessing = true;
    });

    try {
      final userCredential = await _authService.signUp(email, password);
      
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
      }
      
      if (!mounted) return;
      
      _showSuccessSnackBar('Account created successfully!');
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use. Please login instead.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else {
        message = 'Sign up failed. Please try again.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isProcessing) return;

    setState(() {
      _isGoogleLoading = true;
      _isProcessing = true;
    });

    try {
      final UserCredential? userCredential = await _googleSignInService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential == null) {
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
            _isProcessing = false;
          });
        }
        return;
      }

      if (userCredential.user != null) {
        _showSuccessSnackBar('Welcome ${userCredential.user!.displayName ?? "User"}!');
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isFacebookLoading = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isFacebookLoading = false;
      });
      _showErrorSnackBar('Facebook sign-in coming soon!');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _topRightAnimation,
              builder: (context, child) {
                return Positioned(
                  top: -30 + _topRightAnimation.value.dy,
                  right: -20 + _topRightAnimation.value.dx,
                  child: _buildBlob(120, Colors.cyan.shade300),
                );
              },
            ),
            
            AnimatedBuilder(
              animation: _topRightSmallAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 80 + _topRightSmallAnimation.value.dy,
                  right: 80 + _topRightSmallAnimation.value.dx,
                  child: _buildBlob(80, Colors.blue.shade400),
                );
              },
            ),
            
            AnimatedBuilder(
              animation: _bottomLeftAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: -40 + _bottomLeftAnimation.value.dy,
                  left: -60 + _bottomLeftAnimation.value.dx,
                  child: _buildBlob(180, Colors.cyan.shade200),
                );
              },
            ),
            
            AnimatedBuilder(
              animation: _bottomLeftSmallAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: 80 + _bottomLeftSmallAnimation.value.dy,
                  left: 80 + _bottomLeftSmallAnimation.value.dx,
                  child: _buildBlob(100, Colors.blue.shade300),
                );
              },
            ),
            
            AnimatedBuilder(
              animation: _bottomRightAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: 150 + _bottomRightAnimation.value.dy,
                  right: -30 + _bottomRightAnimation.value.dx,
                  child: _buildBlob(140, Colors.blue.shade400),
                );
              },
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back_ios, size: 20),
                            SizedBox(width: 5),
                            Text(
                              'Create\nAccount',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      TextField(
                        controller: _nameController,
                        enabled: !_isLoading && !_isProcessing,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading && !_isProcessing,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        enabled: !_isLoading && !_isProcessing,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          InkWell(
                            onTap: (_isLoading || _isProcessing) ? null : () {
                              FocusScope.of(context).unfocus();
                              _handleEmailPasswordSignUp();
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: (_isLoading || _isProcessing) 
                                    ? Colors.grey.shade400 
                                    : Colors.grey.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      TextButton(
                        onPressed: (_isLoading || _isProcessing) ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              onTap: _isProcessing ? () {} : _handleGoogleSignIn,
                              icon: Icons.g_mobiledata,
                              label: 'Google',
                              color: Colors.red.shade400,
                              isLoading: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSocialButton(
                              onTap: _isProcessing ? () {} : _handleFacebookSignIn,
                              icon: Icons.facebook,
                              label: 'Facebook',
                              color: Colors.blue.shade700,
                              isLoading: _isFacebookLoading,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
            
            if ((_isLoading || _isGoogleLoading) && !_isFacebookLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isLoading ? 'Signing up...' : 'Connecting...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2.5,
                ),
              )
            else
              Icon(
                icon,
                color: color,
                size: 26,
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _topRightController.dispose();
    _topRightSmallController.dispose();
    _bottomLeftController.dispose();
    _bottomLeftSmallController.dispose();
    _bottomRightController.dispose();
    super.dispose();
  }
}

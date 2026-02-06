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

  // Animation controllers for blobs
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

  @override
  void initState() {
    super.initState();
    
    // Top right large blob
    _topRightController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _topRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-15, 10),
    ).animate(CurvedAnimation(parent: _topRightController, curve: Curves.easeInOut));
    
    // Top right small blob
    _topRightSmallController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _topRightSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(10, -15),
    ).animate(CurvedAnimation(parent: _topRightSmallController, curve: Curves.easeInOut));
    
    // Bottom left large blob
    _bottomLeftController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(12, -18),
    ).animate(CurvedAnimation(parent: _bottomLeftController, curve: Curves.easeInOut));
    
    // Bottom left small blob
    _bottomLeftSmallController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-8, 12),
    ).animate(CurvedAnimation(parent: _bottomLeftSmallController, curve: Curves.easeInOut));
    
    // Bottom right blob
    _bottomRightController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    _bottomRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-12, -15),
    ).animate(CurvedAnimation(parent: _bottomRightController, curve: Curves.easeInOut));
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
            // Animated top right large blob
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
            
            // Animated top right small blob
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
            
            // Animated bottom left large blob
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
            
            // Animated bottom left small blob
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
            
            // Animated bottom right blob
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
            
            // Main content - Wrapped in SingleChildScrollView
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Back button with title
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
                      
                      // Name field
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Sign up button with arrow
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
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              // Handle sign up logic here
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
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
                      
                      // Sign in link
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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
                      // Or continue with text
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
                      
                      // Social authentication buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              onTap: () {
                                print('Google sign up');
                              },
                              icon: Icons.g_mobiledata,
                              label: 'Google',
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSocialButton(
                              onTap: () {
                                print('Facebook sign up');
                              },
                              icon: Icons.facebook,
                              label: 'Facebook',
                              color: Colors.blue.shade700,
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
  }) {
    return InkWell(
      onTap: onTap,
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
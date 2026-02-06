import 'package:firstapp/screens/Menu/main_menu.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstapp/service/google_signin_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Animation controllers for blobs
  late AnimationController _topRightController;
  late AnimationController _topRightSmallController;
  late AnimationController _bottomLeftController;
  late AnimationController _bottomLeftSmallController;
  late AnimationController _bottomRightController;
  late AnimationController _centerController;

  late Animation<Offset> _topRightAnimation;
  late Animation<Offset> _topRightSmallAnimation;
  late Animation<Offset> _bottomLeftAnimation;
  late Animation<Offset> _bottomLeftSmallAnimation;
  late Animation<Offset> _bottomRightAnimation;
  late Animation<Offset> _centerAnimation;

  // Donation status
  bool isDonationAvailable = true;

  // Get user info
  final GoogleSignInService _authService = GoogleSignInService();

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
    ).animate(
        CurvedAnimation(parent: _topRightController, curve: Curves.easeInOut));

    // Top right small blob
    _topRightSmallController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _topRightSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(10, -15),
    ).animate(CurvedAnimation(
        parent: _topRightSmallController, curve: Curves.easeInOut));

    // Bottom left large blob
    _bottomLeftController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(12, -18),
    ).animate(CurvedAnimation(
        parent: _bottomLeftController, curve: Curves.easeInOut));

    // Bottom left small blob
    _bottomLeftSmallController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-8, 12),
    ).animate(CurvedAnimation(
        parent: _bottomLeftSmallController, curve: Curves.easeInOut));

    // Bottom right blob
    _bottomRightController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    _bottomRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-12, -15),
    ).animate(CurvedAnimation(
        parent: _bottomRightController, curve: Curves.easeInOut));

    // Center blob
    _centerController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _centerAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(20, -25),
    ).animate(
        CurvedAnimation(parent: _centerController, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _authService.currentUser;
    final String userName = currentUser?.displayName ?? 'Guest User';
    final String bloodType = 'O+';

    return Scaffold(
      drawer: const SlideDrawer(),
      backgroundColor: Colors.white,
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

          // Animated center blob
          AnimatedBuilder(
            animation: _centerAnimation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.35 +
                    _centerAnimation.value.dy,
                right: MediaQuery.of(context).size.width * 0.3 +
                    _centerAnimation.value.dx,
                child: _buildBlob(150, Colors.blue.shade300),
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

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Glass morphic app bar with rounded corners
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Menu icon
                              Builder(
                                builder: (context) {
                                  return InkWell(
                                    onTap: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.menu_rounded,
                                        size: 28,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 15),
                              // Home text
                              const Text(
                                'Home',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  print('Notification tapped');
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    size: 26,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Welcome Card with Red Background
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.teal.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Welcome back,',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Blood type badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.water_drop,
                                              color: Colors.red.shade600,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              bloodType,
                                              style: TextStyle(
                                                color: Colors.red.shade600,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Donation Status Row
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: BackdropFilter(
                                      filter:
                                          ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.water_drop,
                                                color: Colors.red.shade600,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Donation Status',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    isDonationAvailable
                                                        ? 'Available for donation'
                                                        : 'Not available',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: isDonationAvailable,
                                              onChanged: (value) {
                                                setState(() {
                                                  isDonationAvailable = value;
                                                });
                                              },
                                              activeColor: Colors.green,
                                              activeTrackColor:
                                                  Colors.green.shade200,
                                              inactiveThumbColor: Colors.grey,
                                              inactiveTrackColor:
                                                  Colors.grey.shade300,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Donation Cooldown Card
                        _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.orange.shade600,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Donation Cooldown',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Next eligible donation in 60 days',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: 0.4,
                                          backgroundColor:
                                              Colors.orange.shade100,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.orange.shade600,
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.water_drop,
                                value: '5',
                                label: 'Donations',
                                color: Colors.blue.shade400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.star_rounded,
                                value: '250',
                                label: 'Points',
                                color: Colors.purple.shade400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.favorite_rounded,
                                value: '12',
                                label: 'Lives Saved',
                                color: Colors.green.shade400,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Your Impact Card
                        _buildGlassCard(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.shade600,
                              Colors.purple.shade700,
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Your Impact',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.trending_up_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You\'re making a real difference!',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '5',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Emergency responses',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '15L',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Blood donated',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Quick Actions Header
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Quick Action Buttons
                        _buildQuickActionButton(
                          icon: Icons.add_circle_outline,
                          title: 'Schedule Donation',
                          subtitle: 'Book your next appointment',
                          color: Colors.red.shade400,
                          onTap: () {
                            // Navigate to schedule donation
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionButton(
                          icon: Icons.location_on_outlined,
                          title: 'Find Blood Banks',
                          subtitle: 'Locate nearby donation centers',
                          color: Colors.blue.shade400,
                          onTap: () {
                            // Navigate to blood banks
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionButton(
                          icon: Icons.history_rounded,
                          title: 'Donation History',
                          subtitle: 'View your past donations',
                          color: Colors.green.shade400,
                          onTap: () {
                            // Navigate to history
                          },
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildGlassCard({
    required Widget child,
    Gradient? gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? Colors.white.withOpacity(0.7)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _buildGlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topRightController.dispose();
    _topRightSmallController.dispose();
    _bottomLeftController.dispose();
    _bottomLeftSmallController.dispose();
    _bottomRightController.dispose();
    _centerController.dispose();
    super.dispose();
  }
}
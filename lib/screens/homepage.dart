import 'package:firstapp/screens/Menu/main_menu.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

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
    return Scaffold(
      drawer: const SlideDrawer(),
      backgroundColor: Colors.white,
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
                          color: Colors.white.withOpacity(0.3),
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
                              // Menu icon - WRAPPED IN BUILDER
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
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              // Profile/notification icons (optional)
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
                        const SizedBox(height: 20),
                        
                        // Welcome section
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore your dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Grid of cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          children: [
                            _buildDashboardCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Wallet',
                              subtitle: '\$2,450.00',
                              color: Colors.blue.shade400,
                            ),
                            _buildDashboardCard(
                              icon: Icons.trending_up_rounded,
                              title: 'Analytics',
                              subtitle: '+12.5%',
                              color: Colors.green.shade400,
                            ),
                            _buildDashboardCard(
                              icon: Icons.shopping_bag_outlined,
                              title: 'Orders',
                              subtitle: '24 Active',
                              color: Colors.orange.shade400,
                            ),
                            _buildDashboardCard(
                              icon: Icons.person_outline,
                              title: 'Profile',
                              subtitle: 'View Details',
                              color: Colors.purple.shade400,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Recent Activity section
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Activity list
                        _buildActivityItem(
                          icon: Icons.arrow_upward_rounded,
                          title: 'Payment Sent',
                          subtitle: 'To John Doe',
                          amount: '-\$120.00',
                          isPositive: false,
                        ),
                        _buildActivityItem(
                          icon: Icons.arrow_downward_rounded,
                          title: 'Payment Received',
                          subtitle: 'From Jane Smith',
                          amount: '+\$350.00',
                          isPositive: true,
                        ),
                        _buildActivityItem(
                          icon: Icons.shopping_cart_outlined,
                          title: 'Purchase',
                          subtitle: 'Online Store',
                          amount: '-\$89.99',
                          isPositive: false,
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ),
        ],
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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login.dart';
import 'screens/homepage/homepage.dart';
import 'service/notification_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    print('Notification service initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If there's an error, go to login
          if (snapshot.hasError) {
            print('Auth error: ${snapshot.error}');
            return const LoginScreen();
          }
          
          // While waiting for auth state (show splash while connecting)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // Connection established - check user state
          if (snapshot.connectionState == ConnectionState.active) {
            // User is logged in
            if (snapshot.hasData && snapshot.data != null) {
              print('User logged in: ${snapshot.data?.email}');
              return const HomePage();
            }
            
            // No user logged in
            print('No user logged in');
            return const LoginScreen();
          }
          
          // Default to login
          return const LoginScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background blobs (if you want them)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

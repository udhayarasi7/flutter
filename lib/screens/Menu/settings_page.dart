import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/google_signin_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Account',
            children: [
              _buildTile(
                icon: Icons.person,
                title: 'Profile',
                subtitle: user?.displayName ?? 'User',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.email,
                title: 'Email',
                subtitle: user?.email ?? 'Not set',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Notifications',
            children: [
              _buildTile(
                icon: Icons.notifications,
                title: 'Push Notifications',
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              _buildTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Privacy',
            children: [
              _buildTile(
                icon: Icons.location_on,
                title: 'Location Services',
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              _buildTile(
                icon: Icons.visibility,
                title: 'Profile Visibility',
                subtitle: 'Public',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'About',
            children: [
              _buildTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              _buildTile(
                icon: Icons.description,
                title: 'Terms & Conditions',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Actions',
            children: [
              _buildTile(
                icon: Icons.logout,
                title: 'Logout',
                titleColor: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await GoogleSignInService().signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? Colors.blue.shade700),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingL,
        vertical: AppStyles.paddingM,
      ),
      child: Row(
        children: [
          // Logo
          Image.asset('assets/images/logo.png', height: 40),
          
          const SizedBox(width: AppStyles.paddingL),
          
          // Navigation Links
          if (!_isMobile(context))
            const Row(
              children: [
                _NavLink(title: 'Home'),
                _NavLink(title: 'Listings'),
                _NavLink(title: 'About Us'),
                _NavLink(title: 'Contact Us'),
              ],
            ),
          
          const Spacer(),
          
          // Auth Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Sign In'),
              ),
              const SizedBox(width: AppStyles.paddingM),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Sign Up'),
              ),
            ],
          ),
          
          // Mobile Menu
          if (_isMobile(context))
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _showMobileMenu(context),
            ),
        ],
      ),
    );
  }

  bool _isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 768;

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _MobileMenu(),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String title;
  
  const _NavLink({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingM),
      child: TextButton(
        onPressed: () {},
        child: Text(title),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu();
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: const [
        ListTile(title: Text('Home')),
        ListTile(title: Text('Listings')),
        ListTile(title: Text('About Us')),
        ListTile(title: Text('Contact Us')),
      ],
    );
  }
}

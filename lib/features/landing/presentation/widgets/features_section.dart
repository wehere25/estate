import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingL),
      child: Column(
        children: [
          Text(
            'Why Choose Us',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppStyles.paddingL),
          Wrap(
            spacing: AppStyles.paddingL,
            runSpacing: AppStyles.paddingL,
            children: const [
              _FeatureCard(
                icon: Icons.verified,
                title: 'Verified Listings',
                description: 'All our properties are verified by our expert team',
              ),
              _FeatureCard(
                icon: Icons.attach_money,
                title: 'Affordable Prices',
                description: 'Find properties that fit your budget',
              ),
              _FeatureCard(
                icon: Icons.support_agent,
                title: '24/7 Support',
                description: 'Our support team is always ready to help',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppStyles.paddingM),
      decoration: BoxDecoration(
        borderRadius: AppStyles.borderRadiusM,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(height: AppStyles.paddingM),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppStyles.paddingS),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

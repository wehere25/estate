import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';

class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Find Your Dream Home?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.paddingM),
          Text(
            'Browse our exclusive listings or contact our support team for assistance',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.paddingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('View Listings'),
              ),
              const SizedBox(width: AppStyles.paddingM),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Contact Support'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

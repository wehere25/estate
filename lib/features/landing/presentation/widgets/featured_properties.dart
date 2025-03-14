import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';

class FeaturedPropertiesSection extends StatelessWidget {
  const FeaturedPropertiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppStyles.paddingL),
          child: Text(
            'Featured Properties',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SizedBox(
          height: 400,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingL),
            itemBuilder: (context, index) => _PropertyCard(index: index),
          ),
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final int index;

  const _PropertyCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppStyles.paddingM),
      decoration: BoxDecoration(
        borderRadius: AppStyles.borderRadiusM,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            child: Image.network(
              'https://picsum.photos/300/200?random=$index',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppStyles.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modern Villa $index',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppStyles.paddingS),
                Text(
                  '\$${500000 + (index * 100000)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: AppStyles.paddingS),
                Text(
                  'Location $index',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

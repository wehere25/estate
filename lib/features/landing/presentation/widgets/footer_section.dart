import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingL),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FooterColumn(
                  title: 'Company',
                  items: const ['About Us', 'Careers', 'Contact Us'],
                ),
              ),
              Expanded(
                child: _FooterColumn(
                  title: 'Quick Links',
                  items: const ['Properties', 'Agents', 'Blog'],
                ),
              ),
              Expanded(
                child: _FooterColumn(
                  title: 'Legal',
                  items: const ['Privacy Policy', 'Terms of Service'],
                ),
              ),
            ],
          ),
          const Divider(height: AppStyles.paddingL),
          Text(
            '© 2024 Real Estate App. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppStyles.paddingM),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppStyles.paddingS),
          child: InkWell(
            onTap: () {},
            child: Text(item),
          ),
        )),
      ],
    );
  }
}

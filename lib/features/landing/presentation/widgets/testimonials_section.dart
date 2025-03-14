import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../core/constants/app_styles.dart';

class TestimonialsSection extends HookWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);

    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingL),
      child: Column(
        children: [
          Text(
            'What Our Clients Say',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppStyles.paddingL),
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) => currentPage.value = index,
              itemCount: 3,
              itemBuilder: (context, index) => _TestimonialCard(index: index),
            ),
          ),
          const SizedBox(height: AppStyles.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => 
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentPage.value == index 
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final int index;

  const _TestimonialCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingM,
        vertical: AppStyles.paddingS,
      ),
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: BoxDecoration(
        borderRadius: AppStyles.borderRadiusM,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=${index + 1}',
            ),
          ),
          const SizedBox(height: AppStyles.paddingM),
          Text(
            'John Doe $index',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppStyles.paddingS),
          Text(
            '"Amazing experience finding my dream home through this platform!"',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

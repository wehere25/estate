import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../widgets/header_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/featured_properties.dart';
import '../widgets/features_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/footer_section.dart';

class LandingPage extends HookWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final isScrolled = useState(false);

    useEffect(() {
      void onScroll() {
        isScrolled.value = scrollController.offset > 50;
      }
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: isScrolled.value ? 4 : 0,
            backgroundColor: isScrolled.value 
                ? Theme.of(context).colorScheme.surface 
                : Colors.transparent,
            flexibleSpace: const HeaderSection(),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const HeroSection(),
                const FeaturedPropertiesSection(),
                const FeaturesSection(),
                const TestimonialsSection(),
                const CTASection(),
                const FooterSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

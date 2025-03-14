import 'package:flutter/material.dart';
import 'dart:async';

class CarouselSlider extends StatefulWidget {
  final List<Widget> items;
  final CarouselOptions options;

  const CarouselSlider({
    Key? key,
    required this.items,
    required this.options,
  }) : super(key: key);

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class CarouselOptions {
  final bool autoPlay;
  final double aspectRatio;
  final bool enlargeCenterPage;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final ScrollPhysics scrollPhysics;
  final bool enableInfiniteScroll;
  final Function(int index)? onPageChanged;

  CarouselOptions({
    this.autoPlay = false,
    this.aspectRatio = 16 / 9,
    this.enlargeCenterPage = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.scrollPhysics = const PageScrollPhysics(),
    this.enableInfiniteScroll = true,
    this.onPageChanged,
  });
}

class _CarouselSliderState extends State<CarouselSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: widget.options.enlargeCenterPage ? 0.9 : 1.0);
    
    if (widget.options.autoPlay) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(
      widget.options.autoPlayInterval,
      (Timer timer) {
        if (_pageController.hasClients) {
          if (_currentPage < widget.items.length - 1) {
            _pageController.nextPage(
              duration: widget.options.autoPlayAnimationDuration,
              curve: Curves.easeIn,
            );
          } else if (widget.options.enableInfiniteScroll) {
            _pageController.animateToPage(
              0,
              duration: widget.options.autoPlayAnimationDuration,
              curve: Curves.easeIn,
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.options.aspectRatio,
          child: PageView.builder(
            controller: _pageController,
            physics: widget.options.scrollPhysics,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              
              if (widget.options.onPageChanged != null) {
                widget.options.onPageChanged!(index);
              }
            },
            itemBuilder: (context, index) {
              return Transform.scale(
                scale: widget.options.enlargeCenterPage
                    ? (_currentPage == index ? 1.0 : 0.9)
                    : 1.0,
                child: widget.items[index],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (index) => Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

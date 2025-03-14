import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/constants/app_styles.dart';

class ImageCarouselItem {
  final String imageUrl;
  final String title;
  final String description;
  
  const ImageCarouselItem({
    required this.imageUrl,
    required this.title,
    required this.description,
  });
}

class ImageCarousel extends StatefulWidget {
  final List<Widget> items;
  final Function(int)? onTap;
  final double height;
  final bool showIndicator;
  final bool autoPlay;
  final bool enlargeCenterItem;

  const ImageCarousel({
    Key? key,
    required this.items,
    this.onTap,
    this.height = 300.0,
    this.showIndicator = true,
    this.autoPlay = false,
    this.enlargeCenterItem = false,
  }) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;
  // Controller to manage the carousel
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: Text('No images available'),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          // Remove carouselController parameter completely as it doesn't exist or isn't compatible
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: widget.enlargeCenterItem ? 0.85 : 1.0,
            enlargeCenterPage: widget.enlargeCenterItem,
            autoPlay: widget.autoPlay,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: widget.items.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    if (widget.onTap != null) {
                      widget.onTap!(_currentIndex);
                    }
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: item,
                  ),
                );
              },
            );
          }).toList(),
        ),
        if (widget.showIndicator && widget.items.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.items.asMap().entries.map((entry) {
                return GestureDetector(
                  // Replace with a direct tap that uses the index
                  onTap: () {
                    // Instead of trying to use controller methods that don't exist
                    // Simply update the state and let the carousel adjust
                    setState(() {
                      _currentIndex = entry.key;
                    });
                  },
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(
                        _currentIndex == entry.key ? 230 : 102,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// Widget to create interactive carousels with item data
class InteractiveCarousel extends StatelessWidget {
  final List<Widget> items;
  final double height;
  final Function(int)? onTap;

  const InteractiveCarousel({
    super.key,
    required this.items,
    this.height = 300,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ImageCarousel(
      items: items,
      height: height,
      onTap: onTap,
    );
  }
}

// For backward compatibility - converts ImageCarouselItems to widgets
List<Widget> convertItemsToWidgets(List<ImageCarouselItem> items) {
  return items.map((item) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(179),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12.0),
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 14.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }).toList();
}

class FullScreenGallery extends StatelessWidget {
  final List<Widget> items;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ImageCarousel(
            items: items,
            autoPlay: false,
            height: double.infinity,
          ),
          Positioned(
            top: AppStyles.paddingL,
            right: AppStyles.paddingM,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

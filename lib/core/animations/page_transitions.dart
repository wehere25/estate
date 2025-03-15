import 'package:flutter/material.dart';

class CustomPageTransition extends PageRouteBuilder {
  final Widget child;
  final String? heroTag;

  CustomPageTransition({
    required this.child,
    this.heroTag,
  }) : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class SharedAxisPageTransition extends PageRouteBuilder {
  final Widget child;
  final SharedAxisTransitionType type;

  SharedAxisPageTransition({
    required this.child,
    this.type = SharedAxisTransitionType.horizontal,
  }) : super(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case SharedAxisTransitionType.horizontal:
                return _buildHorizontalTransition(animation, child);
              case SharedAxisTransitionType.vertical:
                return _buildVerticalTransition(animation, child);
              case SharedAxisTransitionType.scaled:
                return _buildScaledTransition(animation, child);
            }
          },
        );

  static Widget _buildHorizontalTransition(
      Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget _buildVerticalTransition(
      Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget _buildScaledTransition(
      Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

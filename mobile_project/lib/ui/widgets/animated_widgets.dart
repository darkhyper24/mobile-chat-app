import 'package:flutter/material.dart';

/// A widget that provides tap feedback animation using AnimatedScale.
/// Shrinks on tap down and restores on release.
class AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final Curve curve;

  const AnimatedTapButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<AnimatedTapButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = widget.scaleDown);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// A swipeable card that can be dismissed horizontally
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double swipeThreshold;
  final Duration duration;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeThreshold = 100.0,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  double _offsetX = 0.0;
  double _opacity = 1.0;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX += details.delta.dx;
      // Calculate opacity based on swipe distance
      _opacity = 1.0 - (_offsetX.abs() / 300).clamp(0.0, 0.5);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_offsetX.abs() > widget.swipeThreshold) {
      // Swipe accepted
      if (_offsetX > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
    }
    // Return to original position
    setState(() {
      _offsetX = 0.0;
      _opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_offsetX, 0, 0),
        child: AnimatedOpacity(
          duration: widget.duration,
          opacity: _opacity,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A list item that animates in with a staggered fade and slide effect
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Stagger the animation based on index
    Future.delayed(
      Duration(milliseconds: widget.delay.inMilliseconds * widget.index),
      () {
        if (mounted) {
          setState(() => _isVisible = true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      opacity: _isVisible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_isVisible ? 0 : 30, 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// Custom page route with combined fade and slide transitions
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  FadeSlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 250),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Determine slide offset based on direction
           Offset beginOffset;
           switch (direction) {
             case SlideDirection.right:
               beginOffset = const Offset(1.0, 0.0);
               break;
             case SlideDirection.left:
               beginOffset = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.up:
               beginOffset = const Offset(0.0, 1.0);
               break;
             case SlideDirection.down:
               beginOffset = const Offset(0.0, -1.0);
               break;
           }

           // Curved animations for smoother feel
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
           );

           // Combine fade and slide
           return FadeTransition(
             opacity: curvedAnimation,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: beginOffset,
                 end: Offset.zero,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

enum SlideDirection { right, left, up, down }

/// A container that animates its properties smoothly
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final bool isPressed;
  final Duration duration;
  final double elevation;
  final BorderRadius borderRadius;
  final Color? color;

  const AnimatedCard({
    super.key,
    required this.child,
    this.isPressed = false,
    this.duration = const Duration(milliseconds: 150),
    this.elevation = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPressed ? 0.05 : 0.1),
            blurRadius: isPressed ? 4 : elevation * 4,
            offset: Offset(0, isPressed ? 1 : elevation),
          ),
        ],
      ),
      transform: Matrix4.identity()..scale(isPressed ? 0.98 : 1.0),
      child: child,
    );
  }
}

/// Animated floating action button with scale on press
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: FloatingActionButton(
          onPressed: null, // Handled by GestureDetector
          backgroundColor: widget.backgroundColor ?? const Color(0xFF6750A4),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hero wrapper for easy hero animations between screens
class HeroImage extends StatelessWidget {
  final String tag;
  final Widget child;

  const HeroImage({super.key, required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Animated icon button with scale feedback
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Icon(widget.icon, color: widget.color, size: widget.size),
      ),
    );
  }
}

/// Shimmer loading placeholder with animation
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

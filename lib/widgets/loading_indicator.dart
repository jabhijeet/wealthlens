import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WealthLoadingIndicator extends StatelessWidget {
  const WealthLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.message,
  });

  final double size;
  final Color? color;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // Spinning arc
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: 1.5.seconds,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: 0.25,
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  );
                },
                onEnd:
                    () {}, // Handled by repeat in a real scenario, but TweenAnimationBuilder is simple
              ).animate(onPlay: (c) => c.repeat()),

              // Pulsing center dot
              Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 800.ms,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
                  message!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 1.seconds),
          ],
        ],
      ),
    );
  }
}

/// A full-screen loading overlay
class WealthLoadingOverlay extends StatelessWidget {
  const WealthLoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
      child: WealthLoadingIndicator(message: message),
    );
  }
}

import 'package:flutter/material.dart';

/// Soft shimmer that sweeps across placeholder shapes while content loads. Respects the
/// system "reduce motion" setting by showing the placeholders without the sweep.
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final base = light ? const Color(0xFFEAE6DD) : const Color(0xFF232926);
    final shine = light ? const Color(0xFFF8F6F1) : const Color(0xFF2F3632);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value * 3 - 1; // sweep from left of the box to past its right edge
            return LinearGradient(
              colors: [base, shine, base],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 + t, -0.3),
              end: Alignment(1 + t, 0.3),
            ).createShader(bounds);
          },
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A placeholder block. Must be inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 10, this.aspectRatio});
  final double? width;
  final double height;
  final double radius;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
    );
    if (aspectRatio != null) return AspectRatio(aspectRatio: aspectRatio!, child: box);
    return SizedBox(width: width, height: height, child: box);
  }
}

/// Feed-style placeholders: a big photo card with caption lines.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24)});
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: 3,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(aspectRatio: 4 / 3.6, radius: 28),
            SizedBox(height: 14),
            Row(
              children: [
                SkeletonBox(width: 30, height: 30, radius: 15),
                SizedBox(width: 10),
                SkeletonBox(width: 140),
                Spacer(),
                SkeletonBox(width: 70, height: 36, radius: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Rows of avatar + two lines (notifications, leaderboard, lists).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 8, this.padding = const EdgeInsets.all(20)});
  final int rows;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: rows,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            const SkeletonBox(width: 46, height: 46, radius: 23),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(widthFactor: i.isEven ? 0.8 : 0.6, child: const SkeletonBox(height: 15)),
                  const SizedBox(height: 8),
                  const FractionallySizedBox(widthFactor: 0.4, child: SkeletonBox(height: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Report detail: hero photo, title lines and a panel.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        SkeletonBox(aspectRatio: 4 / 3, radius: 0),
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 110, height: 28, radius: 14),
                  SizedBox(width: 8),
                  SkeletonBox(width: 90, height: 28, radius: 14),
                ],
              ),
              SizedBox(height: 18),
              SkeletonBox(height: 22),
              SizedBox(height: 10),
              FractionallySizedBox(widthFactor: 0.7, child: SkeletonBox(height: 22)),
              SizedBox(height: 18),
              FractionallySizedBox(widthFactor: 0.5, child: SkeletonBox()),
              SizedBox(height: 28),
              SkeletonBox(height: 56, radius: 18),
              SizedBox(height: 24),
              SkeletonBox(height: 110, radius: 24),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Profile-style hero card plus a strip of tiles.
class HeroSkeleton extends StatelessWidget {
  const HeroSkeleton({super.key, this.height = 330});
  final double height;

  @override
  Widget build(BuildContext context) => Shimmer(child: SkeletonBox(height: height, radius: 32));
}

/// Badge grid placeholders.
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.count = 8});
  final int count;

  @override
  Widget build(BuildContext context) => Shimmer(
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisExtent: 142,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const SkeletonBox(height: double.infinity, radius: 18),
    ),
  );
}

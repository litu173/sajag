import 'package:flutter/widgets.dart';

/// Fades and lifts a page's content into place whenever the page comes into view: when it is first
/// opened, when the person switches to its tab, and when they come back to it from another page.
///
/// It keys off [TickerMode]: Flutter turns tickers off for pages covered by another full-screen
/// page and for inactive tabs, but not for pages under a bottom sheet, dialog, menu or tooltip — so
/// closing those never replays the animation.
class PageEntrance extends StatefulWidget {
  const PageEntrance({required this.child, super.key});
  final Widget child;

  @override
  State<PageEntrance> createState() => _PageEntranceState();
}

class _PageEntranceState extends State<PageEntrance> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  bool? _visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (!visible) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(offset: Offset(0, 22 * (1 - _curve.value)), child: child),
    ),
    child: widget.child,
  );
}

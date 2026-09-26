import 'dart:async';

import 'package:dadafinanza/l10n/localized_material.dart';

/// Small, one-shot entrance motion used across DadaFinanza.
///
/// Inspired by the soft scale/fade language used by modern finance apps:
/// content remains readable without motion and animation never blocks input.
class DadaReveal extends StatefulWidget {
  const DadaReveal({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, .035),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<DadaReveal> createState() => _DadaRevealState();
}

class _DadaRevealState extends State<DadaReveal> {
  Timer? _timer;
  var _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.offset,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _visible ? 1 : .985,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

import 'package:balyn/l10n/localized_material.dart';

/// Cross-fades between permanent tab subtrees without remounting the app
/// backdrop or losing form, filter and scroll state on inactive tabs.
///
/// Only the incoming and outgoing pages paint during the short transition.
/// All other sections stay offstage with their tickers disabled.
class SmoothIndexedPages extends StatefulWidget {
  const SmoothIndexedPages({
    required this.index,
    required this.children,
    super.key,
  }) : assert(index >= 0);

  final int index;
  final List<Widget> children;

  @override
  State<SmoothIndexedPages> createState() => _SmoothIndexedPagesState();
}

class _SmoothIndexedPagesState extends State<SmoothIndexedPages>
    with SingleTickerProviderStateMixin {
  static const transitionDuration = Duration(milliseconds: 220);

  late final AnimationController _controller;
  late final Animation<double> _incoming;
  late final Animation<double> _outgoing;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: transitionDuration,
      value: 1,
    )..addStatusListener(_onStatusChanged);
    // Fade-through avoids doubled labels, chart layers and visual ghosting.
    // The persistent liquid background remains underneath both phases.
    _outgoing = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 60),
    ]).animate(_controller);
    _incoming = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      setState(() => _previousIndex = null);
    }
  }

  @override
  void didUpdateWidget(covariant SmoothIndexedPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.index < widget.children.length);
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.index < widget.children.length);

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Positioned.fill(
            child: Offstage(
              offstage: i != widget.index && i != _previousIndex,
              child: TickerMode(
                enabled: i == widget.index,
                child: IgnorePointer(
                  ignoring: i != widget.index,
                  child: ExcludeSemantics(
                    excluding: i != widget.index,
                    child: FadeTransition(
                      opacity: i == widget.index ? _incoming : _outgoing,
                      child: RepaintBoundary(child: widget.children[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:balyn/l10n/localized_material.dart';
import 'package:cue/cue.dart';

/// Cue-style expanding pill selector. The highlighted capsule is synchronized
/// with the actual fractional PageView position, including mid-drag frames.
class BalynCueSectionBar extends StatelessWidget {
  const BalynCueSectionBar({
    required this.selectedTab,
    required this.page,
    required this.onSelected,
    super.key,
  });

  final int selectedTab;
  final double page;
  final ValueChanged<int> onSelected;

  static const tabs = <(String, IconData)>[
    ('Panoramica', Icons.space_dashboard_rounded),
    ('Conti', Icons.account_balance_wallet_outlined),
    ('Attività', Icons.receipt_long_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final progress = page.clamp(0.0, 2.0);
    return Container(
      key: const ValueKey('cue-home-sections'),
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF16151C),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Three collapsed items take 3 units; the selected item gets one
          // extra unit. The distribution continuously follows PageView.
          final unit = constraints.maxWidth / (tabs.length + 1);
          final weight = List<double>.generate(
            tabs.length,
            (i) => (1.0 - (progress - i).abs()).clamp(0.0, 1.0),
          );
          return Stack(
            children: [
              Positioned(
                left: unit * progress,
                top: 0,
                bottom: 0,
                width: unit * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8FB),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    SizedBox(
                      width: unit * (1 + weight[i]),
                      height: double.infinity,
                      child: Semantics(
                        button: true,
                        selected: selectedTab == i,
                        label: tabs[i].$1,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          child: InkWell(
                            key: ValueKey('home-segment-$i'),
                            borderRadius: BorderRadius.circular(26),
                            onTap: () => onSelected(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Cue.onToggle(
                                    toggled: selectedTab == i,
                                    motion: .smooth(),
                                    acts: [.scale(from: .88)],
                                    child: Icon(
                                      tabs[i].$2,
                                      size: 19,
                                      color: Color.lerp(
                                        Colors.white70,
                                        const Color(0xFF17151F),
                                        weight[i],
                                      ),
                                    ),
                                  ),
                                  // The text opens with the sliding pill, rather
                                  // than popping in after the drag is released.
                                  Flexible(
                                    child: ClipRect(
                                      child: SizedBox(
                                        width: weight[i] * 88,
                                        child: Opacity(
                                          opacity: reduced
                                              ? (selectedTab == i ? 1 : 0)
                                              : weight[i],
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: Text(
                                              tabs[i].$1,
                                              maxLines: 1,
                                              overflow: TextOverflow.fade,
                                              softWrap: false,
                                              style: const TextStyle(
                                                color: Color(0xFF17151F),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

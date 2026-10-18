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
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 1 - weight[i],
                                    child: Icon(
                                      tabs[i].$2,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: weight[i],
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Cue.onToggle(
                                          toggled: selectedTab == i,
                                          motion: .smooth(),
                                          acts: [.scale(from: .93)],
                                          child: Icon(
                                            tabs[i].$2,
                                            size: 20,
                                            color: const Color(0xFF17151F),
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          tabs[i].$1,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: const TextStyle(
                                            color: Color(0xFF17151F),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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

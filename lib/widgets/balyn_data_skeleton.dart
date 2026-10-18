import 'package:balyn/l10n/localized_material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Reusable skeletons for actual finance-data loading only. Empty accounts,
/// empty transaction histories, and zero-value charts must never shimmer.
class BalynDataSkeletonView extends StatelessWidget {
  const BalynDataSkeletonView({this.section = 0, super.key});

  /// 0: overview, 1: activity, 2: advances, 3: planning.
  final int section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Skeletonizer.zone(
        child: ListView(
          key: const ValueKey('balyn-data-skeleton'),
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 85),
          children: [
            Row(
              children: [
                const Bone.circle(size: 38),
                const SizedBox(width: 12),
                Expanded(child: Bone.text(words: section == 0 ? 2 : 3)),
                const Bone.circle(size: 30),
              ],
            ),
            const SizedBox(height: 29),
            if (section == 0) ...[
              Center(child: Bone.text(words: 2, fontSize: 14)),
              const SizedBox(height: 13),
              Center(child: Bone.text(words: 2, fontSize: 34)),
              const SizedBox(height: 12),
              Center(child: Bone.text(words: 3)),
              const SizedBox(height: 26),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Bone.circle(size: 52),
                  Bone.circle(size: 52),
                  Bone.circle(size: 52),
                  Bone.circle(size: 52),
                ],
              ),
              const SizedBox(height: 33),
            ],
            const Bone(
              height: 19,
              width: 152,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            const SizedBox(height: 14),
            Bone(
              height: section == 1 ? 95 : 154,
              width: double.infinity,
              borderRadius: BorderRadius.circular(22),
            ),
            const SizedBox(height: 27),
            const Bone(
              height: 19,
              width: 180,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < (section == 1 ? 5 : 3); i++) ...[
              Row(
                children: [
                  const Bone.circle(size: 43),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 3),
                        SizedBox(height: 8),
                        Bone.text(words: 2, fontSize: 11),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Bone(width: 65, height: 16),
                ],
              ),
              const SizedBox(height: 19),
            ],
            if (section != 1) ...[
              const SizedBox(height: 7),
              Bone(
                height: 120,
                width: double.infinity,
                borderRadius: BorderRadius.circular(22),
              ),
            ],
            // Skeletonizer only paints neutral placeholders, never real amounts.
            Text(' ', style: TextStyle(color: scheme.surface)),
          ],
        ),
      ),
    );
  }
}

/// First frame while local database, preferences and shaders initialize.
/// Does not require AppState or a database connection.
class BalynBootstrapLoadingApp extends StatelessWidget {
  const BalynBootstrapLoadingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Balyn',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    themeMode: ThemeMode.system,
    home: const Scaffold(body: BalynDataSkeletonView()),
  );
}

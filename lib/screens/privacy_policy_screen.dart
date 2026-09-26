import 'package:dadafinanza/l10n/localized_material.dart';

import '../widgets/ui_helpers.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy e dati')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text(
          'Ultimo aggiornamento: 23 settembre 2026',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        const SectionTitle('Principio di base'),
        const Text(
          'DadaFinanza è progettata local-first. Movimenti, conti, categorie, '
          'note, obiettivi, budget, regole e Smart Suggestions vengono '
          'memorizzati sul dispositivo e non vengono inviati a server '
          'DadaFinanza.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Permessi'),
        const _PolicyItem(
          icon: Icons.camera_alt_outlined,
          title: 'Fotocamera',
          text:
              'Usata solo quando scegli di acquisire una foto o ricevuta da '
              'allegare a un movimento.',
        ),
        const _PolicyItem(
          icon: Icons.mic_none_rounded,
          title: 'Microfono',
          text:
              'Usato solo per l’inserimento vocale. Il parser DadaFinanza è '
              'locale. Se abiliti il recognizer di sistema, audio o testo '
              'possono essere trattati dal servizio vocale configurato su '
              'Android secondo le regole di quel fornitore.',
        ),
        const _PolicyItem(
          icon: Icons.fingerprint_rounded,
          title: 'Biometria',
          text:
              'Usata per sbloccare l’app tramite le API di sistema. '
              'DadaFinanza non riceve né memorizza dati biometrici.',
        ),
        const _PolicyItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifiche',
          text:
              'Usate per promemoria e avvisi locali configurati da te. '
              'Le notifiche possono essere disattivate in qualsiasi momento.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Backup, import ed export'),
        const Text(
          'Backup, CSV e allegati vengono esportati solo quando avvii '
          'esplicitamente l’operazione e scegli una destinazione. I backup '
          'possono essere protetti con password; se scegli un backup senza '
          'password, il file non è cifrato da DadaFinanza.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Eliminazione'),
        const Text(
          'Puoi cancellare i dati finanziari locali dalle impostazioni. '
          'Disinstallando l’app vengono rimossi i dati conservati nello '
          'spazio privato dell’app; eventuali backup o CSV esportati restano '
          'nella destinazione scelta da te.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Account, pubblicità e tracciamento'),
        const Text(
          'DadaFinanza non richiede un account e non integra pubblicità, '
          'profilazione pubblicitaria o analytics di terze parti.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Contatti'),
        const Text(
          'Sviluppatore: DDone. Per richieste relative a privacy o supporto '
          'usa i contatti pubblicati su www.ddone.it.',
        ),
      ],
    ),
  );
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 10,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(text),
  );
}

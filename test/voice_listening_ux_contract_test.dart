import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'voice modal keeps transcript and exposes restart, close and waveform',
    () async {
      final source = await File(
        'lib/screens/quick_add_page.dart',
      ).readAsString();
      final modalStart = source.indexOf('class _VoiceListeningSheet ');
      final modalEnd = source.indexOf('class _VoiceWaveform ');
      expect(modalStart, greaterThanOrEqualTo(0));
      expect(modalEnd, greaterThan(modalStart));
      // Quick Add also has unrelated actions, such as unlinking an advance.
      final modalSource = source.substring(modalStart, modalEnd);
      expect(modalSource, contains('Icons.restart_alt_rounded'));
      expect(modalSource, contains('Icons.close_rounded'));
      expect(modalSource, contains('_VoiceWaveform'));
      expect(
        modalSource,
        contains('const _silenceWindow = Duration(seconds: 1)'),
      );
      expect(modalSource, contains("label: const Text('Usa questo')"));
      expect(modalSource, isNot(contains("Text('Annulla')")));
      expect(modalSource, isNot(contains("label: Text('Sul dispositivo')")));
    },
  );

  test(
    'voice service keeps recognition session alive after short pauses',
    () async {
      final source = await File(
        'lib/services/voice_input_service.dart',
      ).readAsString();
      expect(source, contains('onSoundLevelChange: onSoundLevel'));
      expect(source, contains('listenMode: ListenMode.dictation'));
      expect(source, contains('pauseFor: const Duration(seconds: 30)'));
    },
  );

  test('transfer type is available in the compact movement picker', () async {
    final source = await File('lib/screens/quick_add_page.dart').readAsString();
    expect(source, contains('TransactionType.transfer'));
    expect(source, contains('_pickMovementType()'));
    expect(source, contains('TransactionType.values'));
  });
}

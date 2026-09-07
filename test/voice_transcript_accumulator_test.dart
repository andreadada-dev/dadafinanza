import 'package:dadafinanza/services/voice_input_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a more complete coherent partial when final is shorter', () {
    final accumulator = VoiceTranscriptAccumulator();
    expect(accumulator.update('segna 1:46', finalResult: false), 'segna 1:46');
    expect(accumulator.update('segna 1', finalResult: true), 'segna 1:46');
  });

  test('uses a genuinely more complete final transcript', () {
    final accumulator = VoiceTranscriptAccumulator();
    accumulator.update('segna 1', finalResult: false);
    expect(accumulator.update('segna 1:46', finalResult: true), 'segna 1:46');
  });

  test(
    'unrelated final result replaces stale partial instead of inventing text',
    () {
      final accumulator = VoiceTranscriptAccumulator();
      accumulator.update('monster', finalResult: false);
      expect(
        accumulator.update('nota pranzo', finalResult: true),
        'nota pranzo',
      );
    },
  );

  test('reset removes previous recognition state', () {
    final accumulator = VoiceTranscriptAccumulator();
    accumulator.update('segna 1:46', finalResult: false);
    accumulator.reset();
    expect(accumulator.value, isEmpty);
    expect(accumulator.update('monster', finalResult: true), 'monster');
  });
}

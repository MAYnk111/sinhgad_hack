import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/domain/services/garbha_sanskar_audio_service.dart';

final garbhaSanskarAudioServiceProvider =
    Provider.autoDispose<GarbhaSanskarAudioService>((ref) {
  final service = GarbhaSanskarAudioService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

import 'package:flutter/services.dart';

import 'features/pressure/data/lembretes_pressao.dart';

/// Versão **sem plugin** (web/preview): não agenda nada, só informa que o
/// alarme existe no app Android.
class LembretesPressaoAndroid implements LembretesPressao {
  @override
  bool get disponivel => false;

  @override
  Future<bool> ligar(List<String> horarios) async {
    await HapticFeedback.selectionClick();
    return false;
  }

  @override
  Future<void> desligar() async {}
}

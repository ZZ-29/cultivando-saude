import 'features/medications/data/alarmes_remedios.dart';
import 'features/medications/data/lembretes_remedios.dart';

/// Versão **sem plugin** (web/preview): não agenda nada, só informa que o
/// alarme existe no app Android.
class LembretesRemediosAndroid implements LembretesRemedios {
  @override
  bool get disponivel => false;

  @override
  Future<bool> sincronizar(List<AlarmeDose> alarmes) async => false;

  @override
  Future<void> desligar() async {}
}

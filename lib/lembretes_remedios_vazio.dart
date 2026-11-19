import 'features/medications/data/alarmes_remedios.dart';
import 'features/medications/data/lembretes_remedios.dart';

/// Versão **sem plugin** (web/preview): não agenda nada.
class LembretesRemediosAndroid implements LembretesRemedios {
  @override
  bool get disponivel => false;

  @override
  Future<bool> sincronizar(List<AlarmeDose> alarmes) async => false;

  @override
  Future<void> desligar() async {}

  @override
  Future<String?> testar({int segundos = 60}) async =>
      'O alarme toca no app Android; aqui não é possível testar.';

  @override
  Future<bool> notificacoesPermitidas() async => false;
}

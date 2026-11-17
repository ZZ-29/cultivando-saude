import 'features/agenda/domain/compromisso.dart';
import 'features/agenda/data/notificacoes.dart';

/// Versão **sem plugin** usada quando o app roda na web (preview).
///
/// O `flutter_local_notifications` não existe em navegador; em vez de quebrar
/// o build, esta classe entra no lugar e não faz nada. No Android vale
/// `notificacoes_android.dart`.
class NotificacoesAndroid implements NotificacoesCompromissos {
  @override
  bool get disponivel => false;

  @override
  Future<void> agendar(Compromisso compromisso) async {}

  @override
  Future<void> cancelar(Compromisso compromisso) async {}
}

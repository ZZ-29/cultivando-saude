import '../domain/compromisso.dart';

/// Agendamento dos avisos de compromisso no sistema do celular.
///
/// A interface fica aqui (Dart puro); a implementação real usa
/// `flutter_local_notifications` e só existe no app Android. Na prévia esta
/// interface fica indisponível — a tela continua mostrando os horários dos
/// avisos, que é o dado que o alarme usa.
abstract class NotificacoesCompromissos {
  bool get disponivel;

  /// Agenda os dois avisos (1h e 30min antes). Substitui os anteriores.
  Future<void> agendar(Compromisso compromisso);

  /// Cancela os avisos do compromisso (ao remover ou ao editar).
  Future<void> cancelar(Compromisso compromisso);
}

class NotificacoesIndisponiveis implements NotificacoesCompromissos {
  @override
  bool get disponivel => false;

  @override
  Future<void> agendar(Compromisso compromisso) async {}

  @override
  Future<void> cancelar(Compromisso compromisso) async {}
}

/// Implementação ativa nesta execução.
NotificacoesCompromissos notificacoesCompromissos =
    NotificacoesIndisponiveis();

/// Troca a implementação (chamado uma vez, na inicialização do app).
void usarNotificacoesCompromissos(NotificacoesCompromissos nova) =>
    notificacoesCompromissos = nova;

/// Identificadores das notificações: dois por compromisso.
int idAviso(int compromissoId, int minutosAntes) =>
    compromissoId * 10 + (minutosAntes == 60 ? 1 : 2);

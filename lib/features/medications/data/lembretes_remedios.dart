import 'alarmes_remedios.dart';

/// Liga e desliga os alarmes das doses de remédio.
///
/// Interface em Dart puro; a implementação real usa as notificações do Android
/// e só existe lá. Na prévia o ajuste é salvo e a tela avisa que o alarme toca
/// no celular.
abstract class LembretesRemedios {
  bool get disponivel;

  /// (Re)agenda todos os alarmes, cancelando os anteriores.
  /// Devolve `false` se o sistema recusou o alarme exato.
  Future<bool> sincronizar(List<AlarmeDose> alarmes);

  Future<void> desligar();

  /// Agenda **um** alarme para daqui a [segundos] segundos.
  ///
  /// Serve para a pessoa ver o alarme tocar agora, em vez de esperar até o
  /// horário real. Devolve o erro, quando falha — mensagem vazia = deu certo.
  Future<String?> testar({int segundos = 60});

  /// As notificações do app estão permitidas no sistema?
  Future<bool> notificacoesPermitidas();
}

class LembretesRemediosIndisponiveis implements LembretesRemedios {
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

/// Implementação ativa nesta execução.
LembretesRemedios lembretesRemedios = LembretesRemediosIndisponiveis();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarLembretesRemedios(LembretesRemedios novo) => lembretesRemedios = novo;

/// Chave de configuração: alarmes de remédio ligados?
const String chaveLembretesRemedios = 'lembretes_remedios_ligados';

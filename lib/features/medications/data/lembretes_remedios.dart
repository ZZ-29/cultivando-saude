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
}

class LembretesRemediosIndisponiveis implements LembretesRemedios {
  @override
  bool get disponivel => false;

  @override
  Future<bool> sincronizar(List<AlarmeDose> alarmes) async => false;

  @override
  Future<void> desligar() async {}
}

/// Implementação ativa nesta execução.
LembretesRemedios lembretesRemedios = LembretesRemediosIndisponiveis();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarLembretesRemedios(LembretesRemedios novo) => lembretesRemedios = novo;

/// Chave de configuração: alarmes de remédio ligados?
const String chaveLembretesRemedios = 'lembretes_remedios_ligados';

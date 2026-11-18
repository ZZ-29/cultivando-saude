/// Lembretes para medir a pressão — manhã, tarde e noite.
///
/// A médica pediu três medidas por dia; o app lembra nos horários combinados.
/// A interface fica em Dart puro; a implementação real usa as notificações do
/// Android e só existe lá. Na prévia, o ajuste é salvo e a tela avisa que o
/// alarme toca no celular.
abstract class LembretesPressao {
  bool get disponivel;

  /// Liga os alarmes nos horários `HH:MM` informados.
  /// Devolve `false` se o sistema recusou (permissão de alarme exato).
  Future<bool> ligar(List<String> horarios);

  Future<void> desligar();
}

class LembretesIndisponiveis implements LembretesPressao {
  @override
  bool get disponivel => false;

  @override
  Future<bool> ligar(List<String> horarios) async => false;

  @override
  Future<void> desligar() async {}
}

/// Implementação ativa nesta execução.
LembretesPressao lembretesPressao = LembretesIndisponiveis();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarLembretesPressao(LembretesPressao novo) => lembretesPressao = novo;

/// Horários padrão, os que a rotina pede.
const List<String> horariosPadraoPressao = <String>['07:00', '13:00', '19:00'];

/// Nome do período de um horário: manhã, tarde ou noite.
String periodoDoHorario(String hhmm) {
  final int hora = int.tryParse(hhmm.split(':').first) ?? 8;
  if (hora < 12) return 'Manhã';
  if (hora < 18) return 'Tarde';
  return 'Noite';
}

/// Identificadores fixos das três notificações (uma por período).
int idLembretePressao(String hhmm) {
  final List<String> padrao = horariosPadraoPressao;
  final int indice = padrao.indexOf(hhmm);
  return 9100 + (indice >= 0 ? indice : 9);
}

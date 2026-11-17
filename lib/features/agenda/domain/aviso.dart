import '../domain/compromisso.dart';

/// Avisos de um compromisso: **1 hora antes** e **30 minutos antes**.
///
/// Dois toques de alerta, não um: o de 1h é para se organizar (banho, carona,
/// documento); o de 30min é o "saia agora". Compromisso que já passou não gera
/// aviso.
class Aviso {
  const Aviso({required this.quando, required this.minutosAntes});

  final DateTime quando;
  final int minutosAntes;

  bool get ehFuturo => quando.isAfter(DateTime.now());

  /// "1 hora antes" / "30 minutos antes"
  String get rotulo => minutosAntes >= 60
      ? '${minutosAntes ~/ 60} hora antes'
      : '$minutosAntes minutos antes';
}

/// Os dois avisos de um compromisso, do mais distante para o mais próximo.
List<Aviso> avisosDo(Compromisso compromisso) {
  const List<int> antecedencias = <int>[60, 30];
  final List<Aviso> saida = <Aviso>[];
  for (final int minutos in antecedencias) {
    saida.add(
      Aviso(
        quando: compromisso.quando.subtract(Duration(minutes: minutos)),
        minutosAntes: minutos,
      ),
    );
  }
  return saida;
}

/// Só os avisos que ainda vão acontecer (para agendar de verdade).
List<Aviso> avisosFuturosDo(Compromisso compromisso) =>
    avisosDo(compromisso).where((Aviso a) => a.ehFuturo).toList();

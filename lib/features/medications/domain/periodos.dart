import 'medicamento.dart';
import 'motor.dart';

/// Períodos do dia, como no modelo Hermes: a tela agrupa as doses por
/// madrugada / manhã / tarde / noite, e o período atual abre já expandido.
enum PeriodoDia { madrugada, manha, tarde, noite }

extension PeriodoDiaInfo on PeriodoDia {
  String get nome => switch (this) {
        PeriodoDia.madrugada => 'Madrugada',
        PeriodoDia.manha => 'Manhã',
        PeriodoDia.tarde => 'Tarde',
        PeriodoDia.noite => 'Noite',
      };

  String get emoji => switch (this) {
        PeriodoDia.madrugada => '🌙',
        PeriodoDia.manha => '🌅',
        PeriodoDia.tarde => '☀️',
        PeriodoDia.noite => '🌆',
      };

  int get horaInicio => switch (this) {
        PeriodoDia.madrugada => 0,
        PeriodoDia.manha => 6,
        PeriodoDia.tarde => 12,
        PeriodoDia.noite => 18,
      };

  int get horaFim => switch (this) {
        PeriodoDia.madrugada => 5,
        PeriodoDia.manha => 11,
        PeriodoDia.tarde => 17,
        PeriodoDia.noite => 23,
      };

  String get faixa => switch (this) {
        PeriodoDia.madrugada => '00:00 às 05:59',
        PeriodoDia.manha => '06:00 às 11:59',
        PeriodoDia.tarde => '12:00 às 17:59',
        PeriodoDia.noite => '18:00 às 23:59',
      };
}

/// Período a que pertence uma hora do dia.
PeriodoDia periodoDaHora(int hora) {
  if (hora < 6) return PeriodoDia.madrugada;
  if (hora < 12) return PeriodoDia.manha;
  if (hora < 18) return PeriodoDia.tarde;
  return PeriodoDia.noite;
}

PeriodoDia periodoDe(DateTime quando) => periodoDaHora(quando.hour);

/// Uma dose do dia, já com o remédio de origem.
class DoseDoDia {
  const DoseDoDia({
    required this.remedio,
    required this.ocorrencia,
    required this.estado,
    required this.primeiraDoDia,
  });

  final Medicamento remedio;
  final Ocorrencia ocorrencia;
  final EstadoDose estado;

  /// Como no Hermes: só a primeira dose do remédio no dia mostra as fases.
  final bool primeiraDoDia;

  int get hora => ocorrencia.quando.hour;
  String get horaTexto =>
      '${ocorrencia.quando.hour.toString().padLeft(2, '0')}:'
      '${ocorrencia.quando.minute.toString().padLeft(2, '0')}';
}

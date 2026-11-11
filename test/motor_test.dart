// Testes do motor de remédios — as regras do "Hermes" em Dart puro.
//
// Rodam com `flutter test`, sem aparelho, sem banco, sem PDF.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/medications/domain/medicamento.dart';
import 'package:cultivando_saude/features/medications/domain/motor.dart';

Medicamento _med({
  required Frequencia freq,
  TipoDuracao duracao = TipoDuracao.continuo,
  int? dias,
  int? cicloDias,
  int? cicloPausa,
  DateTime? inicio,
  int? duracaoFase,
}) {
  final DateTime ini = inicio ?? DateTime(2026, 11, 10);
  return Medicamento(
    nome: 'Teste',
    duracao: duracao,
    diasTratamento: dias,
    cicloDias: cicloDias,
    cicloPausa: cicloPausa,
    fases: <Fase>[
      Fase(frequencia: freq, inicio: ini, duracaoDias: duracaoFase),
    ],
    criadoEm: ini,
  );
}

void main() {
  group('frequências', () {
    test('1x ao dia gera uma dose no horário', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>['08:00'],
        ),
      );
      final List<Ocorrencia> o =
          MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 12));

      expect(o.length, 1);
      expect(o.first.quando, DateTime(2026, 11, 12, 8));
    });

    test('múltiplas vezes gera uma dose por horário', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.variasAoDia,
          horarios: <String>['08:00', '14:00', '20:00'],
        ),
      );
      final List<Ocorrencia> o =
          MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 12));

      expect(o.map((Ocorrencia x) => hhmm(x.quando)).toList(),
          <String>['08:00', '14:00', '20:00']);
    });

    test('de 8 em 8h rola entre dias: 08/16 no 1º dia, 00/08/16 no 2º', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.intervaloHoras,
          intervaloHoras: 8,
          primeiraDose: '08:00',
        ),
        inicio: DateTime(2026, 11, 10),
      );

      final List<Ocorrencia> dia1 =
          MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 10));
      final List<Ocorrencia> dia2 =
          MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 11));

      expect(dia1.map((Ocorrencia x) => hhmm(x.quando)).toList(),
          <String>['08:00', '16:00']);
      expect(dia2.map((Ocorrencia x) => hhmm(x.quando)).toList(),
          <String>['00:00', '08:00', '16:00']);
    });

    test('dias específicos só nos dias marcados', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.diasSemana,
          horarios: <String>['09:00'],
          diasSemana: <int>[1, 3, 5], // seg, qua, sex
        ),
      );

      // 2026-11-10 é terça-feira.
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 10)),
          isEmpty);
      expect(
        MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 11)).length,
        1,
      );
    });

    test('1x por semana só no dia escolhido', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.semanal,
          horarios: <String>['10:00'],
          diaSemana: 1,
        ),
      );
      expect(
        MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 9)).length,
        1,
        reason: '2026-11-09 é segunda',
      );
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 10)),
          isEmpty);
    });

    test('1x por mês só no dia do mês', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.mensal,
          horarios: <String>['10:00'],
          diaMes: 15,
        ),
      );
      expect(
        MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 15)).length,
        1,
      );
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 16)),
          isEmpty);
    });

    test('SOS não gera dose prevista', () {
      final Medicamento med = _med(
        freq: const Frequencia(tipo: TipoFrequencia.sos),
        duracao: TipoDuracao.sos,
      );
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 10)),
          isEmpty);
    });
  });

  group('duração', () {
    test('temporário para depois dos dias combinados', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>['08:00'],
        ),
        duracao: TipoDuracao.temporario,
        dias: 3,
        duracaoFase: 3,
        inicio: DateTime(2026, 11, 10),
      );

      expect(
        MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 12)).length,
        1,
        reason: '3º dia ainda vale',
      );
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 13)),
          isEmpty);
    });

    test('ciclo respeita os dias de pausa', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>['08:00'],
        ),
        duracao: TipoDuracao.ciclo,
        cicloDias: 2,
        cicloPausa: 2,
        inicio: DateTime(2026, 11, 10),
      );

      // dias 0 e 1 tomando; 2 e 3 de pausa; 4 e 5 tomando
      expect(
        MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 11)).length,
        1,
      );
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 12)),
          isEmpty);
      expect(MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 13)),
          isEmpty);
      expect(
        MotorRemedios.ocorrenciasDoDia(med, DateTime(2026, 11, 14)).length,
        1,
      );
    });
  });

  group('estados da dose', () {
    test('tomado, atrasado e agendado', () {
      final Ocorrencia o = Ocorrencia(
        quando: DateTime(2026, 11, 10, 14),
        faseIndex: 0,
      );

      expect(
        MotorRemedios.estadoDe(o, DateTime(2026, 11, 10, 13), <String>{}),
        EstadoDose.agendado,
      );
      expect(
        MotorRemedios.estadoDe(o, DateTime(2026, 11, 10, 15), <String>{}),
        EstadoDose.atrasado,
      );
      expect(
        MotorRemedios.estadoDe(
          o,
          DateTime(2026, 11, 10, 15),
          <String>{o.chave},
        ),
        EstadoDose.tomado,
      );
    });
  });

  group('fase nova', () {
    test('começa depois da última dose, usando o intervalo da frequência nova',
        () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>['22:00'],
        ),
        duracao: TipoDuracao.temporario,
        dias: 1,
        duracaoFase: 1,
        inicio: DateTime(2026, 11, 10),
      );

      // 1x ao dia = 24h depois da última dose (10/11 22:00) → 11/11 22:00
      final CalculoNovaFase calculo = MotorRemedios.calcularNovaFase(
        med,
        const Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>['22:00'],
        ),
      );

      expect(calculo.inicio, DateTime(2026, 11, 11, 22));
      expect(calculo.caiuDeMadrugada, isFalse);
    });

    test('cai de madrugada e sugere 06:00', () {
      final Medicamento med = _med(
        freq: const Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>['22:00'],
        ),
        duracao: TipoDuracao.temporario,
        dias: 1,
        duracaoFase: 1,
        inicio: DateTime(2026, 11, 10),
      );

      // +6h a partir das 22:00 → 04:00 (madrugada)
      final CalculoNovaFase calculo = MotorRemedios.calcularNovaFase(
        med,
        const Frequencia(
          tipo: TipoFrequencia.intervaloHoras,
          intervaloHoras: 6,
          primeiraDose: '08:00',
        ),
      );

      expect(calculo.inicio, DateTime(2026, 11, 11, 4));
      expect(calculo.caiuDeMadrugada, isTrue);
      expect(calculo.sugestao, DateTime(2026, 11, 11, 6));
      expect(calculo.sugestaoHora, '06:00');
    });
  });

  group('tabela de intervalos (do app anterior)', () {
    test('cada frequência tem o intervalo certo em minutos', () {
      expect(
        MotorRemedios.intervaloDaFrequencia(
          const Frequencia(tipo: TipoFrequencia.umaAoDia),
        ),
        1440,
      );
      expect(
        MotorRemedios.intervaloDaFrequencia(
          const Frequencia(tipo: TipoFrequencia.intervaloHoras, intervaloHoras: 8),
        ),
        480,
      );
      expect(
        MotorRemedios.intervaloDaFrequencia(
          const Frequencia(tipo: TipoFrequencia.semanal),
        ),
        10080,
      );
      expect(
        MotorRemedios.intervaloDaFrequencia(
          const Frequencia(tipo: TipoFrequencia.mensal),
        ),
        43200,
      );
      expect(
        MotorRemedios.intervaloDaFrequencia(
          const Frequencia(
            tipo: TipoFrequencia.variasAoDia,
            horarios: <String>['08:00', '20:00'],
          ),
        ),
        720,
      );
    });
  });
}

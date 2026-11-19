// Alarmes das doses: cada horário de cada remédio vira um alarme repetido.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/medications/data/alarmes_remedios.dart';
import 'package:cultivando_saude/features/medications/domain/medicamento.dart';

Medicamento _med({
  required int id,
  required String nome,
  required TipoFrequencia tipo,
  List<String> horarios = const <String>[],
  int? intervalo,
  String primeira = '08:00',
  List<int> diasSemana = const <int>[],
  int? diaMes,
  TipoDuracao duracao = TipoDuracao.continuo,
}) {
  return Medicamento(
    id: id,
    nome: nome,
    dosagem: '50 mg',
    duracao: duracao,
    fases: <Fase>[
      Fase(
        frequencia: Frequencia(
          tipo: tipo,
          horarios: horarios,
          intervaloHoras: intervalo,
          primeiraDose: primeira,
          diasSemana: diasSemana,
          diaMes: diaMes,
        ),
        inicio: DateTime(2026, 11, 1),
      ),
    ],
    criadoEm: DateTime(2026, 11, 1),
  );
}

void main() {
  test('um horário por dia vira um alarme', () {
    final List<AlarmeDose> alarmes = alarmesDe(<Medicamento>[
      _med(
        id: 1,
        nome: 'Losartana',
        tipo: TipoFrequencia.umaAoDia,
        horarios: <String>['08:00'],
      ),
    ]);
    expect(alarmes.length, 1);
    expect(alarmes.first.hhmm, '08:00');
    expect(alarmes.first.nome, 'Losartana');
  });

  test('três horários viram três alarmes', () {
    final List<AlarmeDose> alarmes = alarmesDe(<Medicamento>[
      _med(
        id: 2,
        nome: 'Metformina',
        tipo: TipoFrequencia.variasAoDia,
        horarios: <String>['08:00', '13:00', '19:00'],
      ),
    ]);
    expect(alarmes.length, 3);
    expect(alarmes.map((AlarmeDose a) => a.hhmm).toList(),
        <String>['08:00', '13:00', '19:00']);
  });

  test('intervalo de 12h a partir das 20:00 cobre o dia', () {
    final List<AlarmeDose> alarmes = alarmesDe(<Medicamento>[
      _med(
        id: 3,
        nome: 'Antibiótico',
        tipo: TipoFrequencia.intervaloHoras,
        intervalo: 12,
        primeira: '20:00',
      ),
    ]);
    final List<String> horas =
        alarmes.map((AlarmeDose a) => a.hhmm).toList();
    expect(horas, contains('08:00'));
    expect(horas, contains('20:00'));
  });

  test('SOS não gera alarme', () {
    final List<AlarmeDose> alarmes = alarmesDe(<Medicamento>[
      _med(
        id: 4,
        nome: 'Dipirona',
        tipo: TipoFrequencia.sos,
        duracao: TipoDuracao.sos,
      ),
    ]);
    expect(alarmes, isEmpty);
  });

  test('dias da semana são preservados no alarme', () {
    final List<AlarmeDose> alarmes = alarmesDe(<Medicamento>[
      _med(
        id: 5,
        nome: 'Semanal',
        tipo: TipoFrequencia.diasSemana,
        horarios: <String>['09:00'],
        diasSemana: <int>[1, 3, 5],
      ),
    ]);
    expect(alarmes.single.diasSemana, <int>[1, 3, 5]);
  });

  test('cada alarme tem id único', () {
    final List<AlarmeDose> alarmes = alarmesDe(<Medicamento>[
      _med(
        id: 6,
        nome: 'A',
        tipo: TipoFrequencia.variasAoDia,
        horarios: <String>['08:00', '12:00'],
      ),
      _med(
        id: 7,
        nome: 'B',
        tipo: TipoFrequencia.variasAoDia,
        horarios: <String>['08:00', '12:00'],
      ),
    ]);
    final Set<int> ids = alarmes.map((AlarmeDose a) => a.id).toSet();
    expect(ids.length, alarmes.length);
  });
}

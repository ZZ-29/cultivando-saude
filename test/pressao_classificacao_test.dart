// Faixas de pressão: cada limite precisa cair do lado certo.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/pressure/domain/medicao.dart';

Medicao m(int s, int d) =>
    Medicao(sistolica: s, diastolica: d, quando: DateTime(2026, 11, 12));

void main() {
  test('normal: abaixo de 120/80', () {
    expect(m(110, 70).classificacao, ClassificacaoPressao.normal);
    expect(m(119, 79).classificacao, ClassificacaoPressao.normal);
  });

  test('no limite: 120–139 / 80–89', () {
    expect(m(120, 80).classificacao, ClassificacaoPressao.limite);
    expect(m(130, 85).classificacao, ClassificacaoPressao.limite);
    expect(m(139, 89).classificacao, ClassificacaoPressao.limite);
  });

  test('atenção: 140–159 / 90–99', () {
    expect(m(140, 90).classificacao, ClassificacaoPressao.atencao);
    expect(m(150, 95).classificacao, ClassificacaoPressao.atencao);
    expect(m(159, 99).classificacao, ClassificacaoPressao.atencao);
  });

  test('alerta: 160/100 ou mais', () {
    expect(m(160, 100).classificacao, ClassificacaoPressao.alerta);
    expect(m(175, 105).classificacao, ClassificacaoPressao.alerta);
  });

  test('vale o pior dos dois números', () {
    expect(m(118, 95).classificacao, ClassificacaoPressao.atencao);
    expect(m(170, 78).classificacao, ClassificacaoPressao.alerta);
  });

  test('crise hipertensiva a partir de 180/120', () {
    expect(m(180, 110).criseHipertensiva, isTrue);
    expect(m(175, 120).criseHipertensiva, isTrue);
    expect(m(159, 99).criseHipertensiva, isFalse);
  });
}

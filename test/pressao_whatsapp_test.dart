// Texto das medidas para o WhatsApp: data, período do dia, valor e média.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/pressure/domain/medicao.dart';
import 'package:cultivando_saude/features/pressure/domain/texto_pressao.dart';

Medicao _m(int s, int d, DateTime quando, {int? pulso}) => Medicao(
      sistolica: s,
      diastolica: d,
      quando: quando,
      pulso: pulso,
    );

void main() {
  test('monta a mensagem com data, período do dia e pulso', () {
    final DateTime ref = DateTime(2026, 11, 18, 20);
    final String texto = textoPressaoParaWhatsapp(
      <Medicao>[
        _m(132, 84, DateTime(2026, 11, 18, 7), pulso: 72),
        _m(128, 80, DateTime(2026, 11, 18, 13), pulso: 70),
        _m(140, 88, DateTime(2026, 11, 18, 19)),
      ],
      nome: 'Jorge',
      referencia: ref,
    );

    expect(texto, contains('Jorge'));
    expect(texto, contains('18/11 manhã: 132/84 · pulso 72'));
    expect(texto, contains('18/11 tarde: 128/80 · pulso 70'));
    expect(texto, contains('18/11 noite: 140/88'));
    // Média das três medidas
    expect(texto, contains('Média das 3 medidas: 133/84'));
    expect(texto, contains('Cultivando Saúde'));
  });

  test('ordena por horário e ignora medida futura', () {
    final DateTime ref = DateTime(2026, 11, 18, 12);
    final String texto = textoPressaoParaWhatsapp(
      <Medicao>[
        _m(150, 95, DateTime(2026, 11, 18, 20)), // futura
        _m(120, 78, DateTime(2026, 11, 18, 8)),
      ],
      referencia: ref,
    );

    expect(texto, isNot(contains('150/95')));
    expect(texto, contains('120/78'));
    expect(texto, contains('Média das 1 medidas'));
  });
}

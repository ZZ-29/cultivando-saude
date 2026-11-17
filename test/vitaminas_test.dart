// Histórico e estoque das vitaminas.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/vitamins/domain/vitamina.dart';

void main() {
  final DateTime hoje = DateTime(2026, 11, 13, 10);

  test('tomar baixa o estoque e entra no histórico', () {
    final Vitamina v = Vitamina(nome: 'Vitamina D', estoque: 30);
    expect(v.estoqueAposTomar, 29);
    expect(v.tomadaHoje, isFalse);
  });

  test('tomada de hoje é reconhecida', () {
    final Vitamina antiga = Vitamina(
      nome: 'Vitamina D',
      tomadas: <DateTime>[DateTime(2026, 1, 5, 8, 30)],
    );
    expect(antiga.tomadaHoje, isFalse);

    final Vitamina agora = antiga.copiarCom(
      tomadas: <DateTime>[DateTime.now()],
    );
    expect(agora.tomadaHoje, isTrue);
  });

  test('diasTomados conta dias distintos nos últimos 7', () {
    final Vitamina v = Vitamina(
      nome: 'Vitamina D',
      tomadas: <DateTime>[
        DateTime(2026, 11, 6, 8), // fora da janela (7 dias = 7 a 13)
        DateTime(2026, 11, 10, 8),
        DateTime(2026, 11, 11, 8),
        DateTime(2026, 11, 11, 20), // mesmo dia, conta uma vez
      ],
    );
    expect(v.diasTomados(7, referencia: hoje), 2);
  });

  test('acabando quando o estoque é 5 ou menos', () {
    expect(const Vitamina(nome: 'C', estoque: 5).acabando, isTrue);
    expect(const Vitamina(nome: 'C', estoque: 6).acabando, isFalse);
    expect(const Vitamina(nome: 'C').acabando, isFalse);
  });

  test('desfazer devolve ao estoque e sai do histórico de hoje', () {
    final Vitamina v = Vitamina(
      nome: 'Vitamina D',
      estoque: 29,
      tomadas: <DateTime>[DateTime.now()],
    );
    final Vitamina depois = v.desfazerHoje();
    expect(depois.tomadaHoje, isFalse);
    expect(depois.estoque, 30);
  });

  test('JSON leva e traz histórico e estoque', () {
    final Vitamina v = Vitamina(
      nome: 'Vitamina D',
      horario: '08:00',
      estoque: 12,
      tomadas: <DateTime>[DateTime(2026, 11, 12, 8)],
    );
    final Vitamina copia = Vitamina.doJson(v.paraJson());
    expect(copia.nome, 'Vitamina D');
    expect(copia.estoque, 12);
    expect(copia.tomadas.length, 1);
  });
}

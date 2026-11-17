// Calorias por MET (Compendium of Physical Activities).

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/sports/domain/atividade.dart';

Atividade a(TipoAtividade tipo, Intensidade intensidade, int minutos) =>
    Atividade(
      tipo: tipo,
      intensidade: intensidade,
      minutos: minutos,
      quando: DateTime(2026, 11, 14, 8),
    );

void main() {
  test('caminhada moderada 30 min a 70 kg ≈ 140 kcal', () {
    final double? kcal = a(
      TipoAtividade.caminhada,
      Intensidade.moderada,
      30,
    ).calorias(70);
    // 3,8 × 3,5 × 70 ÷ 200 × 30 = 139,65
    expect(kcal!.round(), 140);
  });

  test('corrida leve gasta bem mais que caminhada forte', () {
    final double corrida =
        a(TipoAtividade.corrida, Intensidade.leve, 30).calorias(70)!;
    final double caminhada =
        a(TipoAtividade.caminhada, Intensidade.forte, 30).calorias(70)!;
    expect(corrida, greaterThan(caminhada));
  });

  test('intensidade muda o gasto no mesmo tipo e tempo', () {
    final double leve =
        a(TipoAtividade.caminhada, Intensidade.leve, 30).calorias(70)!;
    final double forte =
        a(TipoAtividade.caminhada, Intensidade.forte, 30).calorias(70)!;
    expect(forte, greaterThan(leve * 1.5));
  });

  test('sem peso informado, não inventa calorias', () {
    expect(
      a(TipoAtividade.caminhada, Intensidade.moderada, 30).calorias(null),
      isNull,
    );
    expect(
      a(TipoAtividade.caminhada, Intensidade.moderada, 30).calorias(0),
      isNull,
    );
  });

  test('resumo semanal soma minutos, kcal e dias ativos', () {
    final DateTime ref = DateTime(2026, 11, 14);
    final List<Atividade> lista = <Atividade>[
      Atividade(
        tipo: TipoAtividade.caminhada,
        intensidade: Intensidade.moderada,
        minutos: 30,
        quando: DateTime(2026, 11, 14, 8),
      ),
      Atividade(
        tipo: TipoAtividade.caminhada,
        intensidade: Intensidade.leve,
        minutos: 20,
        quando: DateTime(2026, 11, 14, 18),
      ),
      Atividade(
        tipo: TipoAtividade.corrida,
        intensidade: Intensidade.moderada,
        minutos: 25,
        quando: DateTime(2026, 11, 12, 7),
      ),
    ];

    expect(minutosNosUltimos(lista, 7, referencia: ref), 75);
    expect(diasAtivos(lista, 7, referencia: ref), 2);
    expect(caloriasNosUltimos(lista, 7, 70, referencia: ref), isNotNull);
  });

  test('JSON leva e traz a intensidade', () {
    final Atividade original =
        a(TipoAtividade.corrida, Intensidade.forte, 40);
    final Atividade copia = Atividade.doJson(original.paraJson());
    expect(copia.tipo, TipoAtividade.corrida);
    expect(copia.intensidade, Intensidade.forte);
    expect(copia.minutos, 40);
  });
}

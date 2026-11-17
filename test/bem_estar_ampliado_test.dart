// Bem-Estar ampliado: 4 itens do dia, água, resumo semanal e WHO-5.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/wellness/data/bem_estar_repositorio.dart';
import 'package:cultivando_saude/features/wellness/domain/checkup_emocional.dart';
import 'package:cultivando_saude/features/wellness/domain/registro_bem_estar.dart';
import 'package:cultivando_saude/features/wellness/presentation/bem_estar_page.dart';

void main() {
  setUp(() => usarBemEstarRepo(BemEstarMemoria()));

  test('cada toque do dia preserva o que já foi marcado', () async {
    final BemEstarMemoria repo = BemEstarMemoria();
    usarBemEstarRepo(repo);
    final DateTime hoje = RegistroBemEstar.soData(DateTime.now());

    await repo.salvar(RegistroBemEstar(dia: hoje, humor: Humor.bem));
    await repo.salvar(
      RegistroBemEstar(dia: hoje, humor: Humor.bem, agua: 2),
    );

    final RegistroBemEstar? salvo = await repo.deHoje();
    expect(salvo!.humor, Humor.bem);
    expect(salvo.agua, 2);
    // Um único registro por dia
    expect((await repo.listar()).length, 1);
  });

  test('WHO-5: soma × 4 vira nota de 0 a 100', () {
    expect(
      CheckupEmocional(dia: DateTime(2026, 11, 15), respostas: <int>[5, 5, 5, 5, 5])
          .nota,
      100,
    );
    expect(
      CheckupEmocional(dia: DateTime(2026, 11, 15), respostas: <int>[0, 0, 0, 0, 0])
          .nota,
      0,
    );
    expect(
      CheckupEmocional(dia: DateTime(2026, 11, 15), respostas: <int>[3, 3, 3, 3, 3])
          .nota,
      60,
    );
    expect(
      CheckupEmocional(dia: DateTime(2026, 11, 15), respostas: <int>[3, 3, 3, 3, 3])
          .leitura,
      'Atenção ao seu ânimo',
    );
  });

  test('resumo da semana conta cada indicador', () {
    final DateTime ref = DateTime(2026, 11, 15);
    final List<RegistroBemEstar> lista = <RegistroBemEstar>[
      RegistroBemEstar(
        dia: DateTime(2026, 11, 15),
        humor: Humor.bem,
        sono: QualidadeSono.bem,
        dor: Dor.nenhuma,
        convivio: Convivio.pessoalmente,
        agua: 7,
      ),
      RegistroBemEstar(
        dia: DateTime(2026, 11, 14),
        humor: Humor.bem,
        sono: QualidadeSono.mal,
        dor: Dor.forte,
        convivio: Convivio.ninguem,
        agua: 3,
      ),
      // Fora da janela de 7 dias
      RegistroBemEstar(
        dia: DateTime(2026, 11, 1),
        humor: Humor.bem,
        agua: 8,
      ),
    ];

    expect(diasComBomHumor(lista, 7, referencia: ref), 2);
    expect(diasDormiuBem(lista, 7, referencia: ref), 1);
    expect(diasComDor(lista, 7, referencia: ref), 1);
    expect(diasConversou(lista, 7, referencia: ref), 1);
    expect(diasBebeuAgua(lista, 7, meta: 6, referencia: ref), 1);
  });

  testWidgets('tela mostra os quatro itens, água e a semana',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: BemEstarPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Como foi seu dia'), findsOneWidget);
    expect(find.text('Sono'), findsOneWidget);
    expect(find.text('Humor'), findsOneWidget);
    expect(find.text('Dor'), findsOneWidget);
    expect(find.text('Convivência'), findsWidgets);
    expect(find.text('Água hoje'), findsOneWidget);

    // Marca "Dormi mal" e confere que aparece na tela
    await tester.tap(find.text('Dormi mal'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dormi mal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('check-up: 5 perguntas e nota ao responder tudo',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CheckupEmocionalPage()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('1. Me senti alegre'), findsOneWidget);

    // Salvar começa desabilitado (nenhuma resposta)
    final ElevatedButton salvar = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Salvar resultado'),
    );
    expect(salvar.onPressed, isNull);

    // Responde 5 em todas as perguntas
    for (int i = 0; i < 5; i++) {
      final Finder linha = find.text('$i'.padLeft(0));
      expect(linha, findsWidgets);
      await tester.tap(find.text('5').at(i));
      await tester.pump(const Duration(milliseconds: 80));
    }

    final ElevatedButton habilitado = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Salvar resultado'),
    );
    expect(habilitado.onPressed, isNotNull);
  });
}

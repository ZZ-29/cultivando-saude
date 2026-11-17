// Referência médica das faixas de pressão precisa estar na tela.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/pressure/data/pressao_repositorio.dart';
import 'package:cultivando_saude/features/pressure/domain/medicao.dart';
import 'package:cultivando_saude/features/pressure/presentation/pressao_page.dart';

Medicao _m(int s, int d) =>
    Medicao(sistolica: s, diastolica: d, quando: DateTime(2026, 11, 15));

void main() {
  setUp(() => usarPressaoRepo(PressaoMemoria()));

  test('faixas batem com as diretrizes', () {
    expect(_m(110, 70).classificacao, ClassificacaoPressao.normal);
    expect(_m(130, 85).classificacao, ClassificacaoPressao.limite);
    expect(_m(145, 95).classificacao, ClassificacaoPressao.atencao);
    expect(_m(165, 105).classificacao, ClassificacaoPressao.alerta);
    expect(_m(185, 125).criseHipertensiva, isTrue);
    expect(_m(132, 88).criseHipertensiva, isFalse);
  });

  testWidgets('tela sem medidas mostra a fonte das faixas',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PressaoPage()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.textContaining('Diretrizes Brasileiras'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Diretrizes Brasileiras'), findsOneWidget);
    expect(find.textContaining('SBC/SBH/SBN'), findsOneWidget);
    expect(find.textContaining('Ministério da Saúde'), findsOneWidget);
  });

  testWidgets('com medidas, o rodapé com a fonte continua na lista',
      (WidgetTester tester) async {
    final PressaoMemoria repo = PressaoMemoria();
    usarPressaoRepo(repo);
    await repo.salvar(_m(130, 85));

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PressaoPage()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Diretrizes Brasileiras'), findsOneWidget);
  });
}

// Pressão: a tela mostra a data de hoje e as medidas próximas por "Hoje".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/pressure/data/pressao_repositorio.dart';
import 'package:cultivando_saude/features/pressure/domain/medicao.dart';
import 'package:cultivando_saude/features/pressure/presentation/pressao_page.dart';

void main() {
  setUp(() => usarPressaoRepo(PressaoMemoria()));

  testWidgets('mostra a data de hoje no topo', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PressaoPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Hoje,'), findsOneWidget);
  });

  testWidgets('medida de hoje aparece como "Hoje" na lista',
      (WidgetTester tester) async {
    final PressaoMemoria repo = PressaoMemoria();
    usarPressaoRepo(repo);
    await repo.salvar(
      Medicao(sistolica: 130, diastolica: 85, quando: DateTime.now()),
    );

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PressaoPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Hoje '), findsWidgets);
    expect(find.textContaining('130/85'), findsOneWidget);
  });
}

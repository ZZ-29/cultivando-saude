// Reabilitação: exercícios escritos pela pessoa, com horário e check do dia.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/rehab/data/reabilitacao_repositorio.dart';
import 'package:cultivando_saude/features/rehab/domain/exercicio.dart';
import 'package:cultivando_saude/features/rehab/presentation/reabilitacao_page.dart';

void main() {
  setUp(() => usarReabilitacaoRepo(ReabilitacaoMemoria()));

  test('guarda horários e marca feito só no dia', () async {
    final int id = await reabilitacaoRepo.salvar(
      const Exercicio(
        nome: 'Elevação de perna',
        series: '3 x 10',
        orientacao: 'deitado, subir devagar',
        horarios: <String>['08:00', '15:00'],
      ),
    );
    await reabilitacaoRepo.marcarFeito(id, DateTime(2026, 11, 15), true);

    expect(await reabilitacaoRepo.feitosNoDia(DateTime(2026, 11, 15)),
        <int>{id});
    expect(await reabilitacaoRepo.feitosNoDia(DateTime(2026, 11, 16)), isEmpty);
    expect((await reabilitacaoRepo.listar()).single.horarios.length, 2);
  });

  test('JSON preserva orientação e horários', () {
    const Exercicio original = Exercicio(
      nome: 'Alongamento',
      series: '2 minutos',
      orientacao: 'sem dor',
      horarios: <String>['07:30'],
    );
    final Exercicio copia = Exercicio.doJson(original.paraJson());
    expect(copia.nome, 'Alongamento');
    expect(copia.orientacao, 'sem dor');
    expect(copia.horarios.single, '07:30');
  });

  testWidgets('cadastrar exercício aparece na lista',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ReabilitacaoPage()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Exercício'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final Finder campos = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(campos.at(0), 'Elevação de perna');
    await tester.enterText(campos.at(1), '3 x 10');
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(find.text('Salvar exercício'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Elevação de perna'), findsOneWidget);
    expect(find.textContaining('3 x 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

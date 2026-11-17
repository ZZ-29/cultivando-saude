// Plano alimentar editável: a pessoa escreve as próprias refeições.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/nutrition/data/plano_repositorio.dart';
import 'package:cultivando_saude/features/nutrition/domain/refeicao.dart';
import 'package:cultivando_saude/features/nutrition/presentation/alimentacao_page.dart';
import 'package:cultivando_saude/features/patients/data/paciente_atual.dart';
import 'package:cultivando_saude/features/patients/data/pacientes_repositorio.dart';

void main() {
  setUp(() {
    pacienteAtualId = 1;
    usarPlanoRepo(PlanoMemoria());
  });

  test('o plano começa vazio e grava por paciente', () async {
    expect(await planoRepo.ler(), isEmpty);

    await planoRepo.salvar(<Refeicao>[
      const Refeicao(id: '1', titulo: 'Café da manhã', itens: <String>['Ovos']),
    ]);
    expect((await planoRepo.ler()).length, 1);

    // Outro paciente não enxerga o plano do primeiro
    pacienteAtualId = 2;
    expect(await planoRepo.ler(), isEmpty);
    pacienteAtualId = 1;
    expect((await planoRepo.ler()).length, 1);
  });

  testWidgets('criar refeição com item mostra na tela',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: AlimentacaoPage()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Abre a folha de nova refeição
    await tester.tap(find.text('Refeição'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    // Título + item
    final Finder campos = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(campos.at(0), 'Café da manhã');
    await tester.enterText(campos.at(2), '3 ovos');
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Salvar refeição'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Café da manhã'), findsOneWidget);
    expect(find.text('3 ovos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

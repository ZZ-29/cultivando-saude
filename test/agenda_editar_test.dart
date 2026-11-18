// Agenda: o cartão abre para EDITAR (com o endereço) e remover pede confirmação.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/agenda/data/agenda_repositorio.dart';
import 'package:cultivando_saude/features/agenda/domain/compromisso.dart';
import 'package:cultivando_saude/features/agenda/presentation/agenda_page.dart';

void main() {
  setUp(() => usarAgendaRepo(AgendaMemoria()));

  testWidgets('tocar no cartão abre o compromisso com o endereço preenchido',
      (WidgetTester tester) async {
    await agendaRepo.salvar(
      Compromisso(
        titulo: 'Otorrino',
        tipo: TipoCompromisso.consulta,
        quando: DateTime.now().add(const Duration(hours: 3)),
        local: 'Clínica Otorrino',
        endereco: 'Rua das Acácias, 120 — Centro',
      ),
    );

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AgendaPage()));
    await tester.pump(const Duration(milliseconds: 400));

    // Toca no nome do compromisso (dentro do cartão)
    await tester.tap(find.text('Otorrino'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    // A folha de edição abre com os dados já preenchidos.
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Salvar'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Rua das Acácias, 120 — Centro'),
      ),
      findsOneWidget,
      reason: 'o endereço tem que vir preenchido na edição',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('remover pede confirmação e pode cancelar',
      (WidgetTester tester) async {
    await agendaRepo.salvar(
      Compromisso(
        titulo: 'Cardiologista',
        tipo: TipoCompromisso.consulta,
        quando: DateTime.now().add(const Duration(hours: 5)),
      ),
    );

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AgendaPage()));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Remover compromisso?'), findsOneWidget);

    // Cancelar mantém o compromisso
    await tester.tap(find.text('Cancelar'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text('Cardiologista'), findsOneWidget);
    expect((await agendaRepo.listar()).length, 1);
  });
}

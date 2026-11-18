// Agenda: o campo do profissional substitui o "Local", que repetia o endereço.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/agenda/data/agenda_repositorio.dart';
import 'package:cultivando_saude/features/agenda/domain/compromisso.dart';
import 'package:cultivando_saude/features/agenda/presentation/agenda_page.dart';

void main() {
  setUp(() => usarAgendaRepo(AgendaMemoria()));

  test('profissional vai e volta no JSON', () {
    final Compromisso c = Compromisso(
      titulo: 'Otorrino',
      tipo: TipoCompromisso.consulta,
      quando: DateTime(2026, 11, 20, 17),
      profissional: 'Dra. Helena Souza',
      endereco: 'Rua das Acácias, 120 — Centro',
    );
    final Compromisso copia = Compromisso.doJson(c.paraJson());
    expect(copia.profissional, 'Dra. Helena Souza');
    expect(copia.temProfissional, isTrue);
  });

  testWidgets('o cartão mostra o profissional, não o nome do lugar',
      (WidgetTester tester) async {
    await agendaRepo.salvar(
      Compromisso(
        titulo: 'Otorrino',
        tipo: TipoCompromisso.consulta,
        quando: DateTime.now().add(const Duration(hours: 4)),
        profissional: 'Dra. Helena Souza',
        endereco: 'Rua das Acácias, 120 — Centro',
      ),
    );

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AgendaPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Dra. Helena Souza'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o formulário pede o profissional, não o local',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AgendaPage()));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Adicionar'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Profissional (opcional)'), findsOneWidget);
    expect(find.text('Local (opcional)'), findsNothing);
  });
}

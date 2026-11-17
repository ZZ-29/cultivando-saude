// Agenda: dois avisos por compromisso (1 hora e 30 minutos antes) e os dois
// cards de resultado de exame separados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/agenda/data/agenda_repositorio.dart';
import 'package:cultivando_saude/features/agenda/domain/aviso.dart';
import 'package:cultivando_saude/features/agenda/domain/compromisso.dart';
import 'package:cultivando_saude/features/agenda/presentation/agenda_page.dart';
import 'package:cultivando_saude/features/exams/data/exames_repositorio.dart';
import 'package:cultivando_saude/features/exams/domain/exame.dart';
import 'package:cultivando_saude/features/exams/presentation/exames_page.dart';

void main() {
  setUp(() {
    usarAgendaRepo(AgendaMemoria());
    usarExamesRepo(ExamesMemoria());
  });

  test('dois avisos: 1 hora e 30 minutos antes', () {
    final Compromisso c = Compromisso(
      titulo: 'Cardiologista',
      tipo: TipoCompromisso.consulta,
      quando: DateTime.now().add(const Duration(hours: 5)),
    );

    final List<Aviso> avisos = avisosDo(c);
    expect(avisos.length, 2);
    expect(avisos[0].minutosAntes, 60);
    expect(avisos[1].minutosAntes, 30);
    expect(avisos[0].rotulo, '1 hora antes');
    expect(avisos[1].rotulo, '30 minutos antes');

    // O aviso de 1h é exatamente uma hora antes do compromisso.
    expect(
      c.quando.difference(avisos[0].quando).inMinutes,
      60,
    );
    expect(
      c.quando.difference(avisos[1].quando).inMinutes,
      30,
    );
  });

  test('compromisso que já passou não gera aviso futuro', () {
    final Compromisso c = Compromisso(
      titulo: 'Consulta antiga',
      tipo: TipoCompromisso.consulta,
      quando: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(avisosFuturosDo(c), isEmpty);
  });

  testWidgets('a agenda mostra os dois avisos no cartão',
      (WidgetTester tester) async {
    await agendaRepo.salvar(
      Compromisso(
        titulo: 'Oftalmologista',
        tipo: TipoCompromisso.consulta,
        quando: DateTime.now().add(const Duration(hours: 6)),
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AgendaPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('1 hora antes'), findsOneWidget);
    expect(find.textContaining('30 minutos antes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resultados de laboratório ficam separados das especialidades',
      (WidgetTester tester) async {
    await examesRepo.salvar(
      Exame(
        nome: 'Hemograma',
        quando: DateTime(2026, 11, 10),
        categoria: CategoriaExame.laboratorial,
      ),
    );
    await examesRepo.salvar(
      Exame(
        nome: 'Raio-X do tórax',
        quando: DateTime(2026, 11, 11),
        categoria: CategoriaExame.especialidade,
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ExamesPage(categoria: CategoriaExame.laboratorial),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hemograma'), findsOneWidget);
    expect(find.text('Raio-X do tórax'), findsNothing);
    expect(find.text('Resultados de laboratório'), findsOneWidget);
  });
}

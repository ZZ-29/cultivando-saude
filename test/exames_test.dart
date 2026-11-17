// Exames: guarda nome, quem pediu e a foto do resultado.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/exams/data/exames_repositorio.dart';
import 'package:cultivando_saude/features/exams/domain/exame.dart';
import 'package:cultivando_saude/features/exams/presentation/exames_page.dart';

void main() {
  setUp(() => usarExamesRepo(ExamesMemoria()));

  test('exame guarda médico e foto, e lista do mais recente',
      () async {
    await examesRepo.salvar(
      Exame(
        nome: 'Hemograma',
        quando: DateTime(2026, 11, 10),
        medico: 'Dr. Carlos Lima',
        local: 'Lab Central',
        foto: '/tmp/foto.jpg',
      ),
    );
    await examesRepo.salvar(
      Exame(nome: 'Glicemia', quando: DateTime(2026, 11, 12)),
    );

    final List<Exame> lista = await examesRepo.listar();
    expect(lista.length, 2);
    expect(lista.first.nome, 'Glicemia', reason: 'mais recente primeiro');

    final Exame hemograma =
        lista.firstWhere((Exame e) => e.nome == 'Hemograma');
    expect(hemograma.temMedico, isTrue);
    expect(hemograma.temFoto, isTrue);
  });

  test('JSON preserva médico, local e foto', () {
    final Exame original = Exame(
      nome: 'Ultrassom',
      quando: DateTime(2026, 11, 14, 9, 30),
      medico: 'Dra. Ana',
      local: 'Clínica Vida',
      foto: '/foto.png',
    );
    final Exame copia = Exame.doJson(original.paraJson());
    expect(copia.nome, 'Ultrassom');
    expect(copia.medico, 'Dra. Ana');
    expect(copia.local, 'Clínica Vida');
    expect(copia.foto, '/foto.png');
    expect(copia.quando.day, 14);
  });

  testWidgets('cadastrar exame mostra na lista', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ExamesPage(categoria: CategoriaExame.laboratorial)));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Exame'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final Finder campos = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(campos.at(0), 'Hemograma');
    await tester.enterText(campos.at(1), 'Dr. Carlos Lima');
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(find.text('Salvar exame'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Hemograma'), findsOneWidget);
    expect(find.textContaining('pedido por Dr. Carlos Lima'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

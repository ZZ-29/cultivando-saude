// Vitaminas + suplementos no mesmo modelo do card de Remédios.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/vitamins/data/vitaminas_repositorio.dart';
import 'package:cultivando_saude/features/vitamins/domain/vitamina.dart';
import 'package:cultivando_saude/features/vitamins/presentation/vitaminas_page.dart';

void main() {
  setUp(() => usarVitaminasRepo(VitaminasMemoria()));

  test('dose é marcada por horário, não pelo item', () {
    final Vitamina v = Vitamina(
      nome: 'Vitamina D',
      horarios: <String>['08:00', '20:00'],
      horario: '08:00',
    );
    final DateTime hoje = DateTime(2026, 11, 15);

    final Vitamina depois = v.tomarNoHorario('08:00', dia: hoje);
    expect(depois.tomadaNoHorario('08:00', hoje), isTrue);
    expect(depois.tomadaNoHorario('20:00', hoje), isFalse);
    expect(depois.tomadaNoHorario('08:00', DateTime(2026, 11, 16)), isFalse);
  });

  test('suplemento é classe separada e sobrevive ao JSON', () {
    final Vitamina proteina = Vitamina(
      nome: 'Proteína whey',
      classe: ClasseVitamina.suplemento,
      dosagem: '30 g',
      horarios: <String>['07:00'],
      horario: '07:00',
    );
    final Vitamina copia = Vitamina.doJson(proteina.paraJson());

    expect(copia.classe, ClasseVitamina.suplemento);
    expect(copia.dosagem, '30 g');
    expect(copia.horariosDoDia.single, '07:00');
    expect(copia.classe.emoji, '🥤');
  });

  test('dado antigo (horário único) continua funcionando', () {
    final Vitamina antiga = Vitamina.doJson(<String, Object?>{
      'nome': 'Ômega 3',
      'horario': '09:30',
      'tomadas': <String>['2026-11-15T00:00:00.000'],
      'estoque': 10,
    });
    expect(antiga.horariosDoDia.single, '09:30');
    expect(antiga.classe, ClasseVitamina.vitamina);
    // Tomada antiga sem hora vale para o dia inteiro.
    expect(antiga.tomadaNoHorario('09:30', DateTime(2026, 11, 15)), isTrue);
  });

  testWidgets('lista mostra vitamina e suplemento com o botão TOMEI',
      (WidgetTester tester) async {
    final VitaminasRepo repo = VitaminasMemoria();
    usarVitaminasRepo(repo);
    await repo.salvar(const Vitamina(
      nome: 'Vitamina D',
      horarios: <String>['08:00'],
      horario: '08:00',
    ));
    await repo.salvar(const Vitamina(
      nome: 'Proteína whey',
      classe: ClasseVitamina.suplemento,
      horarios: <String>['08:00'],
      horario: '08:00',
    ));

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: VitaminasPage()));
    await tester.pump(const Duration(milliseconds: 400));

    // Abre o período da manhã (o atual pode ser outro).
    // O período atual já abre aberto; tocar fecharia.
    final Finder manha = find.text('Manhã');
    if (manha.evaluate().isNotEmpty &&
        find.text('Vitamina D').evaluate().isEmpty) {
      await tester.tap(manha);
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('Vitamina D'), findsOneWidget);
    expect(find.text('Proteína whey'), findsOneWidget);
    expect(find.text('TOMEI'), findsNWidgets(2));
    expect(find.textContaining('1 vitamina'), findsOneWidget);
    expect(find.textContaining('1 suplemento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

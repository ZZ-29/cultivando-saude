// Modo atividade ao vivo: renderiza, encerra e devolve a atividade.
//
// O avanço do cronômetro usa Timer.periodic, que em teste dispara conforme os
// pumps — controlar 30 minutos de relógio falso tornaria o teste frágil sem
// ganho real. A conta de calorias já é testada no domínio (esportes_met_test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/sports/domain/atividade.dart';
import 'package:cultivando_saude/features/sports/presentation/atividade_ao_vivo_page.dart';

void main() {
  testWidgets('mostra cronômetro, calorias e o seletor de água',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: AtividadeAoVivoPage(
          tipo: TipoAtividade.caminhada,
          intensidade: Intensidade.moderada,
          pesoKg: 70,
        ),
      ),
    );
    // Sem avançar o relógio: o cronômetro está em zero.
    await tester.pump();

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Caminhada · Moderada'), findsOneWidget);
    expect(find.text('ENCERRAR ATIVIDADE'), findsOneWidget);
    expect(find.text('Lembrar de beber água a cada'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem peso, mostra — em vez de inventar calorias',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: AtividadeAoVivoPage(
          tipo: TipoAtividade.caminhada,
          intensidade: Intensidade.moderada,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('encerrar devolve a atividade (mínimo 1 minuto)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Atividade? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async {
              resultado = await Navigator.of(context).push<Atividade>(
                MaterialPageRoute<Atividade>(
                  builder: (BuildContext _) => const AtividadeAoVivoPage(
                    tipo: TipoAtividade.corrida,
                    intensidade: Intensidade.forte,
                    pesoKg: 70,
                  ),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('ENCERRAR ATIVIDADE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(resultado, isNotNull);
    expect(resultado!.minutos, greaterThanOrEqualTo(1));
    expect(resultado!.tipo, TipoAtividade.corrida);
    expect(resultado!.intensidade, Intensidade.forte);
    expect(resultado!.calorias(70), isNotNull);
  });
}

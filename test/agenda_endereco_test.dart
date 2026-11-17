// Endereço na agenda: é o dado que a pessoa caça no WhatsApp na hora de sair.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/agenda/data/agenda_repositorio.dart';
import 'package:cultivando_saude/features/agenda/domain/compromisso.dart';
import 'package:cultivando_saude/features/agenda/presentation/agenda_page.dart';

void main() {
  setUp(() => usarAgendaRepo(AgendaMemoria()));

  // Copiar usa o canal do sistema; no teste ele é simulado.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async => null,
    );
  });

  test('endereço vai e volta no JSON', () {
    final Compromisso c = Compromisso(
      titulo: 'Otorrino',
      tipo: TipoCompromisso.consulta,
      quando: DateTime(2026, 11, 17, 17),
      local: 'Clínica Otorrino',
      endereco: 'Rua das Acácias, 120 — Centro',
    );
    final Compromisso copia = Compromisso.doJson(c.paraJson());

    expect(copia.endereco, 'Rua das Acácias, 120 — Centro');
    expect(copia.temEndereco, isTrue);
    expect(copia.local, 'Clínica Otorrino');
  });

  testWidgets('o cartão mostra o endereço e permite copiar',
      (WidgetTester tester) async {
    await agendaRepo.salvar(
      Compromisso(
        titulo: 'Otorrino',
        tipo: TipoCompromisso.consulta,
        quando: DateTime.now().add(const Duration(hours: 4)),
        local: 'Clínica Otorrino',
        endereco: 'Rua das Acácias, 120 — Centro',
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AgendaPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Rua das Acácias'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Endereço copiado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

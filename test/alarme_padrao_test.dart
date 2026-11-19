// Alarme das doses: vem LIGADO quando existe remédio, e há teste imediato.
//
// Foi a causa de um alarme não tocar na prática: a pessoa cadastrou o remédio,
// mas nunca ligou o interruptor do bloco de alarmes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/core/config/config_repositorio.dart';
import 'package:cultivando_saude/features/medications/data/alarmes_remedios.dart';
import 'package:cultivando_saude/features/medications/data/lembretes_remedios.dart';
import 'package:cultivando_saude/features/medications/data/repositorio.dart';
import 'package:cultivando_saude/features/medications/domain/medicamento.dart';
import 'package:cultivando_saude/features/medications/presentation/remedios_page.dart';

class _Falsos implements LembretesRemedios {
  bool ligado = false;
  List<AlarmeDose> ultimos = <AlarmeDose>[];

  @override
  bool get disponivel => true;

  @override
  Future<bool> sincronizar(List<AlarmeDose> alarmes) async {
    ligado = true;
    ultimos = alarmes;
    return true;
  }

  @override
  Future<void> desligar() async {
    ligado = false;
    ultimos = <AlarmeDose>[];
  }

  @override
  Future<String?> testar({int segundos = 60}) async => null;

  @override
  Future<bool> notificacoesPermitidas() async => true;
}

Medicamento _med() => Medicamento(
      nome: 'Losartana',
      dosagem: '50 mg',
      duracao: TipoDuracao.continuo,
      fases: <Fase>[
        Fase(
          frequencia: const Frequencia(
            tipo: TipoFrequencia.umaAoDia,
            horarios: <String>['08:00'],
          ),
          inicio: DateTime(2026, 11, 1),
        ),
      ],
      criadoEm: DateTime(2026, 11, 1),
    );

void main() {
  late _Falsos lembretes;

  setUp(() {
    usarRepositorio(RepoMemoria());
    usarConfigRepo(ConfigMemoria());
    lembretes = _Falsos();
    usarLembretesRemedios(lembretes);
  });

  testWidgets('com remédio cadastrado, o alarme já vem ligado e agendado',
      (WidgetTester tester) async {
    await medicamentosRepo.salvar(_med());

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RemediosPage()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Avisar nos horários das doses'), findsOneWidget);
    expect(lembretes.ligado, isTrue, reason: 'deve agendar sem a pessoa ligar');
    expect(lembretes.ultimos.length, 1);
    expect(lembretes.ultimos.first.hhmm, '08:00');
    expect(await configRepo.ler(chaveLembretesRemedios), '1');
  });

  testWidgets('o botão "testar" agenda um alarme imediato',
      (WidgetTester tester) async {
    await medicamentosRepo.salvar(_med());

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RemediosPage()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('testar'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.textContaining('Alarme de teste agendado'),
      findsOneWidget,
    );
  });
}

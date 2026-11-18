// Lembretes de pressão: 3x ao dia (manhã, tarde, noite), com horário editável.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/core/config/config_repositorio.dart';
import 'package:cultivando_saude/features/pressure/data/lembretes_pressao.dart';
import 'package:cultivando_saude/features/pressure/data/pressao_repositorio.dart';
import 'package:cultivando_saude/features/pressure/presentation/pressao_page.dart';

/// Falso: registra o que a tela pediu, sem tocar no sistema.
class _LembretesFalsos implements LembretesPressao {
  bool ligado = false;
  List<String> horarios = <String>[];

  @override
  bool get disponivel => true;

  @override
  Future<bool> ligar(List<String> h) async {
    ligado = true;
    horarios = h;
    return true;
  }

  @override
  Future<void> desligar() async {
    ligado = false;
    horarios = <String>[];
  }
}

void main() {
  late _LembretesFalsos lembretes;

  setUp(() {
    usarPressaoRepo(PressaoMemoria());
    usarConfigRepo(ConfigMemoria());
    lembretes = _LembretesFalsos();
    usarLembretesPressao(lembretes);
  });

  test('os três períodos do dia têm nome certo', () {
    expect(periodoDoHorario('07:00'), 'Manhã');
    expect(periodoDoHorario('13:00'), 'Tarde');
    expect(periodoDoHorario('19:00'), 'Noite');
  });

  test('ids das notificações são estáveis e diferentes', () {
    final Set<int> ids = horariosPadraoPressao
        .map((String h) => idLembretePressao(h))
        .toSet();
    expect(ids.length, 3);
  });

  testWidgets('ligar o lembrete agenda os três horários e salva a escolha',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PressaoPage()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lembrar de medir 3x ao dia'), findsOneWidget);
    expect(find.textContaining('Manhã 07:00'), findsOneWidget);
    expect(find.textContaining('Tarde 13:00'), findsOneWidget);
    expect(find.textContaining('Noite 19:00'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));

    expect(lembretes.ligado, isTrue);
    expect(lembretes.horarios.length, 3);
    expect(
      await configRepo.ler(ChavesConfig.lembretesPressao),
      '1',
      reason: 'a escolha precisa sobreviver a fechar o app',
    );

    // Desligar cancela tudo
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));
    expect(lembretes.ligado, isFalse);
    expect(await configRepo.ler(ChavesConfig.lembretesPressao), '0');
  });

  test('horários salvos em JSON voltam como lista', () async {
    final ConfigMemoria repo = ConfigMemoria();
    await repo.salvar(ChavesConfig.horariosPressao, '["06:30","12:30","20:00"]');
    final List<String> lidos = await lerHorariosSalvos(
      repo,
      ChavesConfig.horariosPressao,
    );
    expect(lidos, <String>['06:30', '12:30', '20:00']);
  });
}

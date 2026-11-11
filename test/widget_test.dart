// Teste da casca visual: confere que os cards e as abas aparecem.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/main.dart';

void main() {
  testWidgets('a dashboard mostra as boas-vindas, os cards e o SOS',
      (WidgetTester tester) async {
    // Tela alta o bastante para o ListView construir todos os cards.
    tester.view.physicalSize = const Size(500, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CultivandoSaudeApp());
    await tester.pump();

    expect(find.text('Olá, Maria'), findsOneWidget);
    expect(find.text('PEDIR AJUDA'), findsOneWidget);

    // Ordem nova: Pressão vem antes de Remédios.
    expect(find.text('Última: 120/80'), findsOneWidget);
    expect(find.text('Remédios'), findsWidgets); // card + aba
    expect(find.text('Vitaminas'), findsOneWidget);
    expect(find.text('Orientação Nutricional'), findsOneWidget);

    // Os dois cards que substituíram "Atividades".
    expect(find.text('Esportes'), findsOneWidget);
    expect(find.text('Corrida e Caminhada'), findsOneWidget);
    expect(find.text('Bem-Estar'), findsOneWidget);
    expect(find.text('Academia, Pilates e Massagens'), findsOneWidget);

    // Card novo de reabilitação.
    expect(find.text('Reabilitação'), findsOneWidget);
    expect(find.text('Clínicas e Fisioterapia'), findsOneWidget);
    expect(find.text('Ver Clínicas'), findsOneWidget);

    // O card antigo de Atividades não deve mais existir.
    expect(find.text('Caminhada, Academia, Esporte'), findsNothing);

    // Abas pedidas
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Segurança'), findsWidgets);
  });
}

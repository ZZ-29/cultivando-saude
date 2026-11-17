import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../theme/app_colors.dart';

/// Casca do app.
///
/// **Sem barra fixa no rodapé.** A navegação acontece pelos cards da grade,
/// como já valia para Remédios, Agenda, Plano Alimentar e as demais telas.
///
/// A barra lilás com quatro ícones saiu: ela ficava presa no rodapé (não
/// rolava com o conteúdo) e parecia mais um card solto na tela — além de
/// cobrar espaço de leitura de quem tem 70+.
///
/// O que estava dentro dela foi para o rodapé da grade:
///   • a frase de privacidade ("nada sai do celular");
///   • o aviso de que o app não substitui orientação médica;
///   • o atalho para **Segurança**, que antes era uma aba.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: const DashboardPage(),
    );
  }
}

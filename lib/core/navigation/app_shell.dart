import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../theme/app_colors.dart';

/// Barra inferior com as quatro abas pedidas: Início, Remédios, Agenda,
/// Segurança.
///
/// Só "Início" tem conteúdo nesta fase; as outras três são marcadores de
/// posição — sem tela, sem lógica.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _aba = 0;

  static const List<_Aba> _abas = <_Aba>[
    _Aba('Início', Icons.home_outlined, Icons.home_rounded),
    _Aba('Remédios', Icons.medication_outlined, Icons.medication_rounded),
    _Aba('Agenda', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    _Aba('Segurança', Icons.shield_outlined, Icons.shield_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: IndexedStack(
        index: _aba,
        children: <Widget>[
          const DashboardPage(),
          _emConstrucao('Remédios'),
          _emConstrucao('Agenda'),
          _emConstrucao('Segurança'),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: double.infinity,
            color: AppColors.fundo,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: const Text(
              'Este app não substitui orientação médica.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textoApagado),
            ),
          ),
          NavigationBar(
            height: 84,
            backgroundColor: AppColors.card,
            indicatorColor: const Color(0xFFF3EDE4),
            surfaceTintColor: Colors.transparent,
            selectedIndex: _aba,
            onDestinationSelected: (int indice) =>
                setState(() => _aba = indice),
            destinations: _abas
                .map(
                  (_Aba aba) => NavigationDestination(
                    icon: Icon(aba.icone, color: AppColors.textoApagado),
                    selectedIcon:
                        Icon(aba.iconeAtivo, color: AppColors.texto),
                    label: aba.rotulo,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _emConstrucao(String titulo) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Text(
          '$titulo\n(próxima fase)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            color: AppColors.textoApagado,
          ),
        ),
      ),
    );
  }
}

class _Aba {
  const _Aba(this.rotulo, this.icone, this.iconeAtivo);

  final String rotulo;
  final IconData icone;
  final IconData iconeAtivo;
}

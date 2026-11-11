import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/card_config.dart';
import '../../../core/widgets/cartao_dashboard.dart';
import '../../medications/presentation/remedios_page.dart';

/// Tela principal: os cards empilhados, roláveis.
///
/// Não há lógica aqui — cada card apenas responde com uma mensagem dizendo que
/// a função ainda não existe. É a casca visual para o usuário decidir o layout.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppColors.espacoP,
          AppColors.espacoP,
          AppColors.espacoP,
          32,
        ),
        itemCount: cardsDoDashboard.length,
        separatorBuilder: (BuildContext _, int __) =>
            const SizedBox(height: AppColors.espacoM),
        itemBuilder: (BuildContext context, int i) {
          final CardConfig config = cardsDoDashboard[i];
          return CartaoDashboard(
            config: config,
            aoTocar: () => _tocar(context, config),
          );
        },
      ),
    );
  }

  /// Só o card de Remédios tem tela nesta fase; os outros seguem avisando.
  void _tocar(BuildContext context, CardConfig config) {
    if (config.id == 'remedios') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => const RemediosPage(),
        ),
      );
      return;
    }
    _aviso(context, config);
  }

  void _aviso(BuildContext context, CardConfig config) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${config.titulo}": função entra na próxima fase.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

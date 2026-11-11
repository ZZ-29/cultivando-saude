import 'package:flutter/material.dart';

import 'core/navigation/app_shell.dart';
import 'core/theme/app_colors.dart';

/// Cultivando Saúde — casca visual (v10).
///
/// Esta versão NÃO tem banco, alarme nem navegação funcional: é só a tela
/// para o usuário decidir o layout dos cards.
///
/// Para personalizar: `lib/core/theme/card_config.dart`.
void main() => runApp(const CultivandoSaudeApp());

class CultivandoSaudeApp extends StatelessWidget {
  const CultivandoSaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cultivando Saúde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.fundo,
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF007F),
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.card,
          onSurface: AppColors.texto,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.texto,
          contentTextStyle: TextStyle(fontSize: 18, color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const AppShell(),
    );
  }
}

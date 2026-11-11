import 'package:flutter/material.dart';

/// Paleta e medidas da casca visual.
///
/// **PONTO DE PERSONALIZAÇÃO** — mexer só aqui muda o app inteiro.
abstract final class AppColors {
  // --- Fundo e superfícies ------------------------------------------------
  static const Color fundo = Color(0xFFFFFDF9); // off-white quente
  static const Color card = Color(0xFFFFFFFF);
  static const Color divisoria = Color(0xFFF0E9DF);

  // --- Texto --------------------------------------------------------------
  static const Color texto = Color(0xFF1A1A1A);
  static const Color textoSuave = Color(0xFF5A5450);
  static const Color textoApagado = Color(0xFF6E6763);

  /// Branco usado dentro dos botões coloridos.
  static const Color textoBotao = Color(0xFFFFFFFF);

  // --- Medidas ------------------------------------------------------------
  static const double fonteTituloTela = 32;
  static const double fonteTituloCard = 28;
  static const double fonteTexto = 22;
  static const double fonteApoio = 18;

  static const double alturaBotao = 60;
  static const double alturaBotaoSos = 88;

  static const double raioCard = 20;
  static const double raioBotao = 16;

  static const double espacoP = 20;
  static const double espacoM = 16;
  static const double espacoG = 24;
}

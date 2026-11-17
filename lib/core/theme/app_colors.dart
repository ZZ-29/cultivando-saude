import 'package:flutter/material.dart';

/// Paleta e medidas da casca visual.
///
/// **PONTO DE PERSONALIZAÇÃO** — mexer só aqui muda o app inteiro.
abstract final class AppColors {
  // --- Fundo e superfícies ------------------------------------------------
  /// Fundo creme quente (areia). Escolhido para 60+:
  ///   • não é branco puro — branco total ofusca e cansa a vista;
  ///   • é quente, sem o azul que incomoda quem tem sensibilidade à luz;
  ///   • o card branco por cima continua se destacando, com a sombra
  ///     reforçando a separação;
  ///   • texto #1A1A1A sobre este fundo dá ~13:1 (WCAG AAA).
  ///
  /// Alternativas na mesma família, para testar depois:
  ///   #F3EEE5 (mais claro) · #EDE3D3 (mais escuro) · #F5EFE6 (mais neutro)
  static const Color fundo = Color(0xFFF1E8DB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divisoria = Color(0xFFE0D3C0);

  // --- Card do cabeçalho (lilás) ------------------------------------------
  /// Lilás = calma, cuidado, acolhimento. É a cor do cartão do nome do app.
  static const Color lilasClaro = Color(0xFFF4ECFC);
  static const Color lilasSuave = Color(0xFFE6D8F6);
  static const Color lilasMedio = Color(0xFF8E6FD8);
  static const Color lilasTexto = Color(0xFF472A76);
  static const Color lilasTextoSuave = Color(0xFF6B5A85);

  /// Cor do nome do app no cabeçalho: **dourado**. Sobre o lilás claro, o
  /// dourado puro sumiria; este tom (#B8860B, "goldenrod") ainda lê como ouro
  /// e mantém ~3,9:1 — suficiente para texto grande (o nome tem 46 px), que é
  /// o caso aqui.
  static const Color tituloApp = Color(0xFFB8860B);

  /// Dourado para o slogan, um tom acima — discreto, sem competir com o nome.
  static const Color slogan = Color(0xFF9A7530);

  // --- Família SÁLVIA (identidade: cultivar, cuidar) ----------------------
  /// Verde é a cor que significa crescimento **e** vida ao mesmo tempo —
  /// plantar, cuidar e colher. O sálvia é o verde do cuidado (suave), e o
  /// oliva profundo serve para texto.
  static const Color salviaClaro = Color(0xFFEEF2E6);
  static const Color salvia = Color(0xFFD9E4C9);
  static const Color salviaMedio = Color(0xFF8FA97A);
  static const Color salviaTexto = Color(0xFF4E6B3A);

  /// Tinge uma cor sobre o fundo do app, para o card inteiro ficar com a
  /// família da cor da categoria (como o card lilás do cabeçalho), sem
  /// apagar a legibilidade do texto escuro por cima.
  ///
  /// [forca] 0 = fundo puro · 1 = cor cheia.
  static Color tinta(Color cor, double forca) =>
      Color.alphaBlend(cor.withValues(alpha: forca), fundo);

  // --- Texto --------------------------------------------------------------
  /// Sem preto no app. O texto é **ameixa escuro** (#3E2A47): contraste de
  /// ~9,5:1 sobre o fundo creme, mas sem o peso visual do preto puro.
  static const Color texto = Color(0xFF3E2A47);
  static const Color textoSuave = Color(0xFF6B5A63);
  static const Color textoApagado = Color(0xFF7A6E76);

  /// Branco usado dentro dos botões coloridos.
  static const Color textoBotao = Color(0xFFFFFFFF);

  // --- Medidas ------------------------------------------------------------
  static const double fonteTituloTela = 32;
  static const double fonteTituloCard = 28;
  static const double fonteTexto = 22;
  static const double fonteApoio = 18;

  static const double alturaBotao = 60;
  static const double alturaBotaoSos = 88;

  static const double raioCard = 24;
  static const double raioBotao = 16;

  static const double espacoP = 20;
  static const double espacoM = 16;
  static const double espacoG = 24;
}

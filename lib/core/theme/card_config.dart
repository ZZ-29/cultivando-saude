import 'package:flutter/material.dart';

/// **ARQUIVO DE PERSONALIZAÇÃO**
///
/// Tudo o que se vê na Dashboard vem desta lista.
///
/// **Paleta por significado + separação visual** (v21):
///
/// A regra não é só "cada card com seu significado": como a grade tem duas
/// colunas, dois cards vizinhos (na vertical ou na horizontal) não podem
/// compartilhar a mesma família de cor — senão a coluna inteira vira um
/// borrão. Ordem final, lida de cima para baixo, coluna por coluna:
///
///   esquerda: vermelho · azul-aço · verde · amarelo · laranja
///   direita:  lilás · azul · roxo · teal · terracota
///
///   vermelho intenso → emergência (universal) .. SOS
///   lilás    → identidade, dado pessoal ........ Meus dados
///   azul-aço → clínico, preciso ................ Pressão
///   azul     → confiança, segurança ............ Remédios
///   verde    → saúde, vitalidade ............... Vitaminas
///   roxo     → organização, foco ............... Agenda
///   amarelo  → nutrição, energia do alimento ... Plano Alimentar
///   teal     → recuperação, equilíbrio ......... Reabilitação
///   laranja  → energia, movimento .............. Esportes
///   terracota → terra, aconchego, cuidado ...... Bem-Estar
///
/// Cada card tem DUAS cores: a viva (faixa, ícone, sombra) e a escura
/// (`corBotao`), que garante texto branco com contraste AA.
enum TipoCard { simples, boasVindas, sos }

class CardConfig {
  const CardConfig({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.icone,
    required this.cor,
    required this.corBotao,
    this.rotuloBotao = 'Abrir',
    this.tipo = TipoCard.simples,
  });

  final String id;
  final String titulo;
  final String texto;
  final IconData icone;
  final Color cor;
  final Color corBotao;
  final String rotuloBotao;
  final TipoCard tipo;

  /// Enfeite de fundo do card (emoji grande e apagado). Cada tema tem o seu;
  /// aparece atrás do conteúdo, sem receber toque.
}

/// Os cards da Dashboard, **na ordem em que aparecem**.
///
/// Ordem definida pelo usuário em 11/11:
///   1 Boas-vindas · 2 SOS · 3 Pressão · 4 Remédios · 5 Vitaminas ·
///   6 Agenda · 7 Plano Alimentar · 8 Reabilitação · 9 Esportes · 10 Bem-Estar
const List<CardConfig> cardsDoDashboard = <CardConfig>[
  // 1 — Cabeçalho. Mostra o NOME DO APP; o "Olá, <nome>" só aparece depois
  // que a pessoa se cadastrar (o widget recebe o nome por parâmetro).
  CardConfig(
    id: 'boas_vindas',
    titulo: 'Cultivando Saúde',
    texto: 'Cuidar é preservar a vida',
    icone: Icons.wb_sunny_rounded,
    cor: Color(0xFFFFB300),
    corBotao: Color(0xFF8A6A00),
    tipo: TipoCard.boasVindas,
  ),

  // 2 — SOS · vermelho intenso (emergência é vermelho no mundo inteiro)
  CardConfig(
    id: 'sos',
    titulo: 'Emergência',
    texto: 'Peça ajuda agora',
    icone: Icons.sos_rounded,
    cor: Color(0xFFD50000),
    corBotao: Color(0xFF9B0000),
    rotuloBotao: 'PEDIR AJUDA',
    tipo: TipoCard.sos,
  ),

  // 3 — Pressão · azul-aço (clínico, aparelho de pressão) — 10:1 no botão
  CardConfig(
    id: 'pressao',
    titulo: 'Pressão',
    texto: 'Última: 120/80',
    icone: Icons.monitor_heart_rounded,
    cor: Color(0xFF455A64),
    corBotao: Color(0xFF263238),
    rotuloBotao: 'Registrar pressão',
  ),

  // 4 — Remédios · azul (confiança, segurança) — 7,6:1 no botão
  CardConfig(
    id: 'remedios',
    titulo: 'Remédios',
    texto: '2 de 4 tomados',
    icone: Icons.medication_rounded,
    cor: Color(0xFF2962FF),
    corBotao: Color(0xFF1B45C9),
    rotuloBotao: 'Ver remédios',
  ),

  // 5 — Vitaminas · verde (saúde, vitalidade) — 6,5:1 no botão
  CardConfig(
    id: 'vitaminas',
    titulo: 'Vitaminas',
    texto: '1 de 2 tomadas',
    icone: Icons.eco_rounded,
    cor: Color(0xFF2E9E4F),
    corBotao: Color(0xFF1B6B34),
    rotuloBotao: 'Ver vitaminas',
  ),

  // 6 — Agenda · índigo (organização, planejamento) — 9:1 no botão
  //
  // Sem marca-d'água: o emoji de calendário vira um "July 17" em inglês no
  // Windows e poluía o card. Aqui só as frases.
  CardConfig(
    id: 'agenda',
    titulo: 'Agenda',
    texto: 'Amanhã 10h',
    icone: Icons.calendar_month_rounded,
    cor: Color(0xFF7B1FA2),
    corBotao: Color(0xFF4A148C),
    rotuloBotao: 'Ver agenda',
  ),

  // 7 — Plano Alimentar · verde-lima (nutrição, frescor) — 5,5:1 no botão
  CardConfig(
    id: 'alimentacao',
    titulo: 'Plano Alimentar',
    texto: 'Orientação Nutricional',
    icone: Icons.restaurant_rounded,
    cor: Color(0xFFC9A227),
    corBotao: Color(0xFF7A5F00),
    rotuloBotao: 'Ver Plano',
  ),

  // 8 — Reabilitação · teal (recuperação, equilíbrio) — 8:1 no botão
  CardConfig(
    id: 'reabilitacao',
    titulo: 'Reabilitação',
    texto: 'Clínicas e Fisioterapia',
    icone: Icons.healing_rounded,
    cor: Color(0xFF00897B),
    corBotao: Color(0xFF00564D),
    rotuloBotao: 'Ver Clínicas',
  ),

  // 9 — Esportes · laranja (energia, movimento) — 5,9:1 no botão
  CardConfig(
    id: 'esportes',
    titulo: 'Esportes',
    texto: 'Corrida e Caminhada',
    icone: Icons.directions_run_rounded,
    cor: Color(0xFFFB8C00),
    corBotao: Color(0xFFA85A00),
    rotuloBotao: 'Ver Esportes',
  ),

  // 10 — Bem-Estar · verde-sálvia (calma, natureza, cuidado) — 8:1 no botão
  CardConfig(
    id: 'bem_estar',
    titulo: 'Bem-Estar',
    texto: 'Pilates e massagens',
    icone: Icons.spa_rounded,
    cor: Color(0xFFB07D5A),
    corBotao: Color(0xFF6D4C34),
    rotuloBotao: 'Ver Bem-Estar',
  ),
];

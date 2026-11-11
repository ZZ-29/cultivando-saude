import 'package:flutter/material.dart';

/// **ARQUIVO DE PERSONALIZAÇÃO**
///
/// Tudo o que se vê na Dashboard vem desta lista. Para mudar cor, ícone,
/// título, texto, ordem ou rótulo do botão de um card, mexa aqui.
///
/// Campos de cada card:
///   id          — identificador curto (só para referência)
///   titulo      — título grande do card
///   texto       — a linha de resumo
///   icone       — desenho no quadrado colorido
///   cor         — cor da faixa, do quadrado e do brilho
///   corBotao    — versão escura da cor, usada no botão (contraste AA)
///   rotuloBotao — texto do botão
///   tipo        — simples | boasVindas | sos
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
}

/// Os cards da Dashboard, **na ordem em que aparecem**.
///
/// Ordem definida pelo usuário em 11/11:
///   1 Boas-vindas · 2 SOS · 3 Pressão · 4 Remédios · 5 Vitaminas ·
///   6 Agenda · 7 Plano Alimentar · 8 Reabilitação · 9 Esportes · 10 Bem-Estar
///
/// O card **Exames** não aparece como card próprio: ele passou a ser coberto
/// pela **Agenda (Consultas e Exames)**. Se um dia quiser separar de novo, o
/// bloco pronto está no fim deste arquivo, comentado.
const List<CardConfig> cardsDoDashboard = <CardConfig>[
  // 1 — Boas-vindas. O texto (data de hoje) é preenchido pelo widget.
  CardConfig(
    id: 'boas_vindas',
    titulo: 'Olá, Maria',
    texto: '',
    icone: Icons.wb_sunny_rounded,
    cor: Color(0xFFFFB300),
    corBotao: Color(0xFF8A6A00),
    tipo: TipoCard.boasVindas,
  ),

  // 2 — SOS: só o botão vermelho gigante.
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

  // 3 — Pressão
  CardConfig(
    id: 'pressao',
    titulo: 'Pressão',
    texto: 'Última: 120/80',
    icone: Icons.monitor_heart_rounded,
    cor: Color(0xFFE53935),
    corBotao: Color(0xFFB71C1C),
    rotuloBotao: 'Registrar pressão',
  ),

  // 4 — Remédios
  CardConfig(
    id: 'remedios',
    titulo: 'Remédios',
    texto: '2 de 4 tomados',
    icone: Icons.medication_rounded,
    cor: Color(0xFFFF007F),
    corBotao: Color(0xFFB0005A),
    rotuloBotao: 'Ver remédios',
  ),

  // 5 — Vitaminas
  CardConfig(
    id: 'vitaminas',
    titulo: 'Vitaminas',
    texto: '1 de 2 tomadas',
    // Ícone de folha: o spa ficou reservado ao Bem-Estar.
    icone: Icons.eco_rounded,
    cor: Color(0xFF8E24AA),
    corBotao: Color(0xFF6A1B9A),
    rotuloBotao: 'Ver vitaminas',
  ),

  // 6 — Agenda
  CardConfig(
    id: 'agenda',
    titulo: 'Agenda',
    texto: 'Dr. Silva · Amanhã 10h',
    icone: Icons.calendar_month_rounded,
    cor: Color(0xFFFF5E00),
    corBotao: Color(0xFFB33F00),
    rotuloBotao: 'Ver agenda',
  ),

  // 7 — Plano Alimentar
  CardConfig(
    id: 'alimentacao',
    titulo: 'Plano Alimentar',
    texto: 'Orientação Nutricional',
    icone: Icons.restaurant_rounded,
    cor: Color(0xFF43A047),
    corBotao: Color(0xFF2E7D32),
    rotuloBotao: 'Ver Plano',
  ),

  // 8 — Reabilitação (novo): clínicas e fisioterapia
  CardConfig(
    id: 'reabilitacao',
    titulo: 'Reabilitação',
    texto: 'Clínicas e Fisioterapia',
    icone: Icons.healing_rounded,
    cor: Color(0xFF1E88E5),
    corBotao: Color(0xFF0D47A1),
    rotuloBotao: 'Ver Clínicas',
  ),

  // 9 — Esportes
  CardConfig(
    id: 'esportes',
    titulo: 'Esportes',
    texto: 'Corrida e Caminhada',
    icone: Icons.directions_run_rounded,
    cor: Color(0xFFFFC300),
    corBotao: Color(0xFF8A6A00),
    rotuloBotao: 'Ver Esportes',
  ),

  // 10 — Bem-Estar
  CardConfig(
    id: 'bem_estar',
    titulo: 'Bem-Estar',
    texto: 'Academia, Pilates e Massagens',
    icone: Icons.spa_rounded,
    cor: Color(0xFF9C27B0),
    corBotao: Color(0xFF6A1B9A),
    rotuloBotao: 'Ver Bem-Estar',
  ),
];

// ---------------------------------------------------------------------------
// Card removido nesta versão. Para trazer de volta, descomente o bloco e
// acrescente-o na posição desejada da lista acima.
//
//   CardConfig(
//     id: 'exames',
//     titulo: 'Exames',
//     texto: 'Último: Sangue · 10/11',
//     icone: Icons.biotech_rounded,
//     cor: Color(0xFF1E88E5),
//     corBotao: Color(0xFF1565C0),
//     rotuloBotao: 'Ver exames',
//   ),
// ---------------------------------------------------------------------------

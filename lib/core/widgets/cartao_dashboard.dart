import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/card_config.dart';

/// CARD DA MARCA — o cartão lilás do topo.
///
/// ```
///    🌷🌸   Cultivando Saúde   🌼🌺🌿
///          Cuidar é preservar a vida
/// ```
///
/// O nome fica **centralizado**, com o jardim dividido dos dois lados, e é
/// escrito num **dourado em gradiente** — o metal, não a tinta: claro no
/// topo da letra, fundo na base, como ouro polido sob luz.
///
/// A vida do card vem de movimentos lentos (ciclo de 9 s):
///   • o gradiente lilás do fundo desliza na diagonal;
///   • as flores balançam em fases diferentes;
///   • as flores respiram (sobem ~2,5 px).
class CartaoDashboard extends StatefulWidget {
  const CartaoDashboard({
    required this.config,
    super.key,
  });

  final CardConfig config;

  @override
  State<CartaoDashboard> createState() => _CartaoDashboardState();
}

class _CartaoDashboardState extends State<CartaoDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ciclo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat(reverse: true);

  /// Jardim **simétrico** e mais cheio: três flores de cada lado, com tamanhos
  /// espelhados (grande junto do nome, pequena na ponta) e alturas diferentes
  /// — canteiro de verdade, não fileira de carimbos.
  static const List<_Flor> _esquerda = <_Flor>[
    _Flor('🌼', 14, 0.10, 1.2, 5),
    _Flor('🌸', 17, 0.28, 2.2, 2),
    _Flor('🌷', 22, 0.00, 1.6, 0),
  ];

  static const List<_Flor> _direita = <_Flor>[
    _Flor('🌺', 22, 0.56, 2.0, 0),
    _Flor('🌻', 17, 0.70, 1.4, 2),
    _Flor('🌿', 14, 0.85, 1.8, 5),
  ];

  /// Largura fixa de cada canteiro — é o que garante o centro de verdade.
  static const double _larguraJardim = 66;

  late DateTime _agora = DateTime.now();
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    // Data e hora ficam na marca, e precisam andar sozinhas.
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime novo = DateTime.now();
      if (novo.minute != _agora.minute || novo.hour != _agora.hour) {
        setState(() => _agora = novo);
      }
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O topo é a MARCA: o nome do app nunca sai daqui. A saudação com o nome
    // da pessoa vive no card "Meus dados".
    final String nome = widget.config.titulo;
    final bool temSlogan = widget.config.texto.trim().isNotEmpty;

    return AnimatedBuilder(
      animation: _ciclo,
      builder: (BuildContext context, Widget? _) {
        final double t = Curves.easeInOut.transform(_ciclo.value);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.bottomLeft,
                t,
              )!,
              end: Alignment.lerp(
                Alignment.bottomRight,
                Alignment.topRight,
                t,
              )!,
              colors: <Color>[
                // Jardim ao amanhecer: sálvia clara → sálvia.
                Color.lerp(AppColors.salviaClaro, Colors.white, t * 0.5)!,
                Color.lerp(AppColors.salvia, AppColors.salviaClaro, t)!,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.salviaMedio.withValues(alpha: 0.20 + t * 0.10),
                blurRadius: 20 + t * 8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Nome centralizado: canteiros de largura IGUAL nas duas pontas.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: _larguraJardim,
                    child: _jardim(_esquerda, t, alinhamentoFim: true),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _nomeDourado(nome),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _larguraJardim,
                    child: _jardim(_direita, t, alinhamentoFim: false),
                  ),
                ],
              ),

              // Slogan
              if (temSlogan) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  widget.config.texto,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <ui.FontVariation>[
                      ui.FontVariation('wght', 480),
                    ],
                    fontSize: 13.5,
                    letterSpacing: 1.5,
                    height: 1.2,
                    color: AppColors.slogan,
                  ),
                ),
              ],

              // Data à esquerda (sob as flores da esquerda) e relógio grande
              // à direita (sob as flores da direita).
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _dataLonga(_agora),
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontVariations: <ui.FontVariation>[
                              ui.FontVariation('wght', 650),
                            ],
                            fontSize: 14.5,
                            height: 1.15,
                            color: AppColors.salviaTexto,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _hora(_agora),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <ui.FontVariation>[
                        ui.FontVariation('wght', 800),
                      ],
                      fontSize: 31,
                      height: 1.0,
                      letterSpacing: -0.8,
                      color: AppColors.salviaTexto,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dourado em gradiente: claro no alto, profundo na base.
  Widget _nomeDourado(String texto) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect limites) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE8C46A),
            Color(0xFFC79A2E),
            Color(0xFF9E7412),
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ).createShader(limites);
      },
      child: Text(
        texto,
        maxLines: 1,
        style: const TextStyle(
          fontFamily: 'DancingScript',
          fontVariations: <ui.FontVariation>[
            ui.FontVariation('wght', 420),
          ],
          fontSize: 46,
          letterSpacing: 0.6,
          height: 1.15,
          color: Colors.white, // vira o gradiente pelo ShaderMask
        ),
      ),
    );
  }

  Widget _jardim(
    List<_Flor> flores,
    double t, {
    required bool alinhamentoFim,
  }) {
    return Row(
      mainAxisAlignment:
          alinhamentoFim ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: flores.map((_Flor flor) {
        final double fase = (t + flor.fase) % 1.0;
        final double onda = math.sin(fase * 2 * math.pi);

        return Padding(
          // Altura própria de cada flor: dá o desenho de canteiro.
          padding: EdgeInsets.only(left: 1, right: 1, bottom: flor.altura),
          child: Transform.translate(
            offset: Offset(0, -2.5 * (onda + 1) / 2),
            child: Transform.rotate(
              angle: onda * 0.030 * flor.balanco,
              child: Text(
                flor.emoji,
                style: TextStyle(fontSize: flor.tamanho),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _Flor {
  const _Flor(
    this.emoji,
    this.tamanho,
    this.fase,
    this.balanco,
    this.altura,
  );

  final String emoji;
  final double tamanho;
  final double fase;
  final double balanco;
  final double altura;
}

/// "sexta-feira, 13 de novembro de 2026"
String _dataLonga(DateTime d) {
  const List<String> dias = <String>[
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  const List<String> meses = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
}

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

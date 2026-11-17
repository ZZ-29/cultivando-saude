import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/card_config.dart';

/// CARD DA MARCA — o cartão do topo.
///
/// ```
///   🌸                      🌼
///        Cultivando Saúde          ← nome grande, dourado
///        Cuidar é preservar a vida
///   🌿   sexta-feira, 13…   08:42  🌷
/// ```
///
/// **v18:** as flores saíram dos dois canteiros laterais e foram **espalhadas
/// pelo card** (cantos e bordas), pequenas (12–17px) e atrás do conteúdo.
/// Antes elas ocupavam 132px de largura, um de cada lado, e o nome era
/// encolhido para caber no meio — ficava menor que as próprias flores.
///
/// O nome é escrito num **dourado em gradiente** — o metal, não a tinta.
///
/// A vida do card vem de movimentos lentos (ciclo de 9 s):
///   • o gradiente do fundo desliza na diagonal;
///   • as flores balançam e respiram em fases diferentes.
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

  /// Flores espalhadas numa **faixa no alto do card** (22px).
  ///
  /// Antes elas flutuavam por todo o card e as da base caíam em cima do
  /// relógio. Numa faixa própria, ficam soltas e espalhadas sem encostar em
  /// nome, slogan, data ou hora.
  static const List<_Flor> _flores = <_Flor>[
    _Flor('🌸', 16, 0.03, 6, 0.12, 2.4),
    _Flor('🌼', 13, 0.22, 0, 0.34, 1.8),
    _Flor('🌻', 15, 0.41, 8, 0.62, 2.0),
    _Flor('🌺', 14, 0.58, 1, 0.80, 2.2),
    _Flor('🌷', 16, 0.77, 7, 0.22, 2.6),
    _Flor('🌿', 13, 0.93, 2, 0.46, 1.9),
  ];

  static const double _alturaFaixaFlores = 22;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              // Faixa de flores: decoração que não encosta em nada.
              SizedBox(
                height: _alturaFaixaFlores,
                width: double.infinity,
                child: IgnorePointer(child: _faixaDeFlores(t)),
              ),

              // Nome grande: recebe a largura toda do card.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _nomeDourado(nome),
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

                  // Data à esquerda e relógio grande à direita.
                  const SizedBox(height: 10),
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

  /// Faixa de flores: cada flor numa posição horizontal própria, com um
  /// deslocamento vertical pequeno — soltas, mas sem sair da faixa.
  Widget _faixaDeFlores(double t) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints limites) {
        final double largura = limites.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: _flores.map((_Flor flor) {
            final double fase = (t + flor.fase) % 1.0;
            final double onda = math.sin(fase * 2 * math.pi);

            return Positioned(
              // Centraliza a flor na posição horizontal escolhida.
              left: largura * flor.x - flor.tamanho / 2,
              top: flor.y,
              child: Transform.translate(
                offset: Offset(0, -2.0 * (onda + 1) / 2),
                child: Transform.rotate(
                  angle: onda * 0.06 * flor.balanco,
                  child: Text(
                    flor.emoji,
                    style: TextStyle(fontSize: flor.tamanho),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _Flor {
  const _Flor(
    this.emoji,
    this.tamanho,
    this.x,
    this.y,
    this.fase,
    this.balanco,
  );

  final String emoji;
  final double tamanho;

  /// Posição horizontal dentro da faixa (0 = esquerda, 1 = direita).
  final double x;

  /// Deslocamento vertical dentro da faixa, em pixels.
  final double y;

  final double fase;
  final double balanco;
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

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card de EMERGÊNCIA no tamanho de um card comum da grade.
///
/// v19 — o vermelho saiu do fundo e foi para a tinta:
///   • fundo em gradiente **claro** de vermelho (como os outros cards), em
///     vez de vermelho cheio;
///   • título, ação e seta em **vermelho escuro**;
///   • só o quadradinho do ícone continua vermelho sólido — é o ponto de
///     alarme que a vista acha de relance, sem o card inteiro gritar.
class CartaoSos extends StatelessWidget {
  const CartaoSos({required this.aoTocar, super.key});

  final VoidCallback? aoTocar;

  static const double raio = 20;

  /// Vermelho da marca de emergência.
  static const Color _vermelho = Color(0xFFD50000);

  /// Vermelho escuro para texto (contraste AA sobre a tinta clara).
  static const Color _vermelhoTexto = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(raio),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _vermelho.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(raio),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.tinta(_vermelho, 0.10),
                AppColors.tinta(_vermelho, 0.22),
              ],
            ),
            borderRadius: BorderRadius.circular(raio),
            border: Border.all(
              color: _vermelho.withValues(alpha: 0.34),
              width: 1.2,
            ),
          ),
          child: InkWell(
            onTap: aoTocar,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _vermelho,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: _vermelho.withValues(alpha: 0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sos_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _vermelhoTexto,
                        size: 19,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Emergência',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: _vermelhoTexto,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Expanded(
                    child: Text(
                      'PEDIR AJUDA',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _vermelhoTexto.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

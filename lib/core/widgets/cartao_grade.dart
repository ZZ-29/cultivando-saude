import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/card_config.dart';

/// Card compacto da grade de 2 colunas.
///
/// v17 — altura 100 px (era 112):
///   • fundo em gradiente da própria cor da categoria (sem branco);
///   • **ícone colorido**: quadrado branco translúcido com o glifo na cor cheia
///     da categoria (antes era quadrado colorido com glifo branco — a cor
///     desaparecia a distância);
///   • texto na cor escura da categoria (contraste AA);
///   • ícone 26, título 15, texto 12 em até duas linhas.
class CartaoGrade extends StatelessWidget {
  const CartaoGrade({
    required this.config,
    this.aoTocar,
    this.acessorio,
    this.texto,
    super.key,
  });

  final CardConfig config;
  final VoidCallback? aoTocar;

  /// Texto que substitui o do [CardConfig] — usado para mostrar dado real
  /// (ex.: última pressão medida) em vez do texto de exemplo.
  final String? texto;

  /// Substitui a seta no canto superior direito (usado pelo relógio no card
  /// de Remédios).
  final Widget? acessorio;


  static const double raio = 20;

  @override
  Widget build(BuildContext context) {
    final Color corTexto = config.corBotao;
    // Título pode ter cor própria (ex.: Agenda em laranja).
    final Color corTitulo = config.corTitulo ?? corTexto;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints limites) {
        // Duas colunas em celular estreito deixam o card com ~140px: aí o
        // texto do rodapé ocupa UMA linha (em vez de duas) para não estourar
        // a altura fixa de 100px.
        final bool estreito = limites.maxWidth < 160;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(raio),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: config.cor.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 5),
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
                    AppColors.tinta(config.cor, 0.13),
                    AppColors.tinta(config.cor, 0.26),
                  ],
                ),
                borderRadius: BorderRadius.circular(raio),
                border: Border.all(
                  color: config.cor.withValues(alpha: 0.28),
                  width: 1.1,
                ),
              ),
              child: InkWell(
                onTap: aoTocar,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 7, 9, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: estreito ? 24 : 26,
                            height: estreito ? 24 : 26,
                            decoration: BoxDecoration(
                              // Fundo claro para o glifo colorido aparecer.
                              color: Colors.white.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: config.cor.withValues(alpha: 0.30),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              config.icone,
                              color: config.cor,
                              size: estreito ? 15 : 17,
                            ),
                          ),
                          const Spacer(),
                          acessorio ??
                              Icon(
                                Icons.chevron_right_rounded,
                                color: corTexto,
                                size: 18,
                              ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        config.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: estreito ? 14 : 15,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: corTitulo,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Expanded(
                        child: Text(
                          texto ?? config.texto,
                          maxLines: estreito ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: estreito ? 11.5 : 12,
                            height: 1.15,
                            color: corTexto.withValues(alpha: 0.78),
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
      },
    );
  }
}

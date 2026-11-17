import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tela de área que ainda não existe, mas já sabe o que vai ser.
///
/// Em vez de um texto solto no meio da tela ("(próxima fase)"), mostra o
/// ícone da área, o nome, uma frase curta e a lista do que vem ali. Para quem
/// abre o app, isso responde "isso está vazio por quê?" — e para nós, documenta
/// o escopo de cada módulo antes de escrevê-lo.
class TelaProximaFase extends StatelessWidget {
  const TelaProximaFase({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.resumo,
    required this.itens,
    super.key,
  });

  final String titulo;
  final IconData icone;
  final Color cor;
  final String resumo;
  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        children: <Widget>[
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: cor.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: Icon(icone, color: cor, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontVariations: <FontVariation>[FontVariation('wght', 700)],
              fontSize: 26,
              height: 1.15,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resumo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontVariations: <FontVariation>[FontVariation('wght', 380)],
              fontSize: 15,
              height: 1.35,
              color: AppColors.textoSuave,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.tinta(cor, 0.09),
                  AppColors.tinta(cor, 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: cor.withValues(alpha: 0.26),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.auto_awesome_rounded, size: 16, color: cor),
                    const SizedBox(width: 6),
                    Text(
                      'O que vem aqui',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 14,
                        color: cor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...itens.map(
                  (String item) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontVariations: <FontVariation>[
                                FontVariation('wght', 420),
                              ],
                              fontSize: 14,
                              height: 1.3,
                              color: AppColors.texto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

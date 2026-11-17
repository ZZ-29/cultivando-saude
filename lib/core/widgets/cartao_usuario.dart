import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card de DADOS DO USUÁRIO, ao lado do card de emergência.
///
/// Mostra, quando o cadastro existir:
///   • nome;
///   • idade;
///   • tipo sanguíneo;
///   • data de hoje (o relógio saiu daqui e foi para o card de Remédios).
///
/// Sem cadastro, os campos aparecem como traços — assim o card já tem o
/// tamanho definitivo e não muda de altura quando o dado chegar.
class CartaoUsuario extends StatelessWidget {
  const CartaoUsuario({
    this.nome,
    this.idade,
    this.tipoSanguineo,
    this.aoTocar,
    super.key,
  });

  final String? nome;
  final int? idade;
  final String? tipoSanguineo;
  final VoidCallback? aoTocar;

  static const double _raio = 20;

  @override
  Widget build(BuildContext context) {
    final String nome = (this.nome ?? '').trim().isEmpty
        ? '—'
        : this.nome!.trim();
    // A saudação mora aqui, não na marca: o topo é o nome do app.
    final String saudacao = nome == '—' ? '—' : 'Olá, $nome';
    final String idade = this.idade == null ? '—' : '${this.idade}';
    final String sangue = (tipoSanguineo ?? '').trim().isEmpty
        ? '—'
        : tipoSanguineo!.trim();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_raio),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.lilasMedio.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_raio),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[AppColors.lilasClaro, AppColors.lilasSuave],
            ),
            borderRadius: BorderRadius.circular(_raio),
            border: Border.all(
              color: AppColors.lilasMedio.withValues(alpha: 0.28),
              width: 1.1,
            ),
          ),
          child: InkWell(
            onTap: aoTocar,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Etiqueta do card
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.person_rounded,
                        color: AppColors.tituloApp,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Meus dados',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontVariations: const <ui.FontVariation>[
                              ui.FontVariation('wght', 700),
                            ],
                            fontSize: 13.5,
                            letterSpacing: 0.2,
                            color: AppColors.lilasTextoSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),

                  // Saudação com o nome (cursiva, casando com a marca)
                  Text(
                    saudacao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DancingScript',
                      fontVariations: <ui.FontVariation>[
                        ui.FontVariation('wght', 600),
                      ],
                      fontSize: 27,
                      height: 1.02,
                      color: AppColors.tituloApp,
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Idade e sangue: encolhe em vez de cortar em tela estreita.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Idade $idade · Sangue $sangue',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontVariations: const <ui.FontVariation>[
                            ui.FontVariation('wght', 600),
                          ],
                          fontSize: 15.5,
                          height: 1.05,
                          color: AppColors.lilasTexto,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  // A data saiu daqui: agora vive no card da marca, grande.
                  // Fica só a dica de que o card é tocável.
                  const Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'toque para editar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.1,
                          color: AppColors.lilasTextoSuave,
                        ),
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

  /// "qua, 12 nov 2026"
  static String _dataCurta(DateTime d) {
    const List<String> dias = <String>[
      'seg',
      'ter',
      'qua',
      'qui',
      'sex',
      'sáb',
      'dom',
    ];
    const List<String> meses = <String>[
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${dias[d.weekday - 1]}, ${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}

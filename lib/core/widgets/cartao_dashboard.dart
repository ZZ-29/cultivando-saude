import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/card_config.dart';

/// Um card da Dashboard, montado a partir de um [CardConfig].
///
/// Estrutura fixa (o que o usuário personaliza é o conteúdo e a cor):
///   faixa colorida no topo
///   [ícone em quadrado colorido]  Título
///                                 Texto/resumo
///   [botão de ação]
class CartaoDashboard extends StatelessWidget {
  const CartaoDashboard({
    required this.config,
    this.aoTocar,
    super.key,
  });

  final CardConfig config;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    if (config.tipo == TipoCard.sos) {
      return _sos();
    }
    if (config.tipo == TipoCard.boasVindas) {
      return _boasVindas();
    }
    return _cardNormal();
  }

  // --------------------------------------------------------- Boas-vindas --

  Widget _boasVindas() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TituloBoasVindas(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Card normal --

  Widget _cardNormal() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.raioCard),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: config.cor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 8, color: config.cor),
          Padding(
            padding: const EdgeInsets.all(AppColors.espacoP),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _quadradoIcone(),
                    const SizedBox(width: AppColors.espacoM),
                    Expanded(
                      child: Text(
                        config.titulo,
                        style: const TextStyle(
                          fontSize: AppColors.fonteTituloCard,
                          fontWeight: FontWeight.w800,
                          color: AppColors.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  config.texto,
                  style: const TextStyle(
                    fontSize: AppColors.fonteTexto,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: AppColors.espacoM),
                _botao(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quadradoIcone() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: config.cor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(config.icone, color: Colors.white, size: 34),
    );
  }

  Widget _botao() {
    return SizedBox(
      height: AppColors.alturaBotao,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: config.corBotao,
          foregroundColor: AppColors.textoBotao,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.raioBotao),
          ),
        ),
        child: Text(
          config.rotuloBotao,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ SOS --

  Widget _sos() {
    return Container(
      padding: const EdgeInsets.all(AppColors.espacoP),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.raioCard),
        border: Border.all(color: config.cor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(config.icone, color: config.cor, size: 30),
              const SizedBox(width: 10),
              Text(
                config.titulo,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.texto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: AppColors.alturaBotaoSos,
            child: ElevatedButton(
              onPressed: aoTocar,
              style: ElevatedButton.styleFrom(
                backgroundColor: config.cor,
                foregroundColor: AppColors.textoBotao,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.raioBotao),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.sos_rounded, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    config.rotuloBotao,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Olá, Maria" + data de hoje, em texto grande.
class _TituloBoasVindas extends StatelessWidget {
  const _TituloBoasVindas();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Olá, Maria',
          style: TextStyle(
            fontSize: AppColors.fonteTituloTela,
            fontWeight: FontWeight.w900,
            color: AppColors.texto,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dataLonga(DateTime.now()),
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.textoSuave,
          ),
        ),
      ],
    );
  }

  /// "terça-feira, 11 de novembro" — sem pacote de idioma.
  static String _dataLonga(DateTime d) {
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
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }
}

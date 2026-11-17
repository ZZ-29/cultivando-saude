import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/pressao_repositorio.dart';
import '../domain/medicao.dart';

/// Pressão: registrar medida e ver o histórico.
///
/// Duas coisas apenas — o formulário (em folha deslizante) e a lista. Cada
/// medida aparece com os números grandes, porque é isso que a pessoa quer
/// comparar de uma olhada.
class PressaoPage extends StatefulWidget {
  const PressaoPage({super.key});

  @override
  State<PressaoPage> createState() => _PressaoPageState();
}

class _PressaoPageState extends State<PressaoPage> {
  static const Color _vermelho = Color(0xFFE53935);
  static const Color _vermelhoEscuro = Color(0xFFB71C1C);
  static const Color _verde = Color(0xFF2E9E4F);
  static const Color _dourado = Color(0xFFC9A227);
  static const Color _laranja = Color(0xFFEE7B00);

  List<Medicao> _itens = <Medicao>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<Medicao> lista = await pressaoRepo.listar();
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  /// Cor por faixa: verde (normal) → dourado (no limite) → laranja (atenção)
  /// → vermelho (alerta).
  Color _cor(ClassificacaoPressao c) => switch (c) {
        ClassificacaoPressao.normal => _verde,
        ClassificacaoPressao.limite => _dourado,
        ClassificacaoPressao.atencao => _laranja,
        ClassificacaoPressao.alerta => _vermelho,
      };

  Future<void> _registrar() async {
    final int? sistolica = await _pedirNumero(
      titulo: 'Pressão sistólica',
      dica: 'O número de cima, ex.: 120',
      maximo: 260,
    );
    if (sistolica == null || !mounted) return;

    final int? diastolica = await _pedirNumero(
      titulo: 'Pressão diastólica',
      dica: 'O número de baixo, ex.: 80',
      maximo: 200,
    );
    if (diastolica == null || !mounted) return;

    await pressaoRepo.salvar(
      Medicao(
        sistolica: sistolica,
        diastolica: diastolica,
        quando: DateTime.now(),
      ),
    );
    await _carregar();

    if (!mounted) return;
    final Medicao? ultima = _itens.isEmpty ? null : _itens.first;
    final ClassificacaoPressao c =
        ultima?.classificacao ?? ClassificacaoPressao.normal;

    // Só a indicação médica: classificação + (quando a diretriz manda)
    // procurar atendimento. Nada de conselho de hábito.
    final String complemento;
    if (ultima != null && ultima.criseHipertensiva) {
      complemento = ' Valores de crise: procure atendimento agora.';
    } else if (c.orientacao.isNotEmpty) {
      complemento = ' ${c.orientacao}';
    } else {
      complemento = '';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registrado: $sistolica/$diastolica — ${c.rotulo}.$complemento',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Pede um número em folha deslizante, com validação simples.
  ///
  /// O campo é um widget próprio ([_CampoNumero]) porque o
  /// `TextEditingController` precisa viver e morrer junto com a folha — se for
  /// descartado no `whenComplete`, o campo usa um controller já liberado
  /// enquanto a animação de saída roda.
  Future<int?> _pedirNumero({
    required String titulo,
    required String dica,
    required int maximo,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => _CampoNumero(
        titulo: titulo,
        dica: dica,
        maximo: maximo,
        cor: _vermelho,
      ),
    );
  }

  Future<void> _remover(Medicao m) async {
    final int? id = m.id;
    if (id == null) return;
    await pressaoRepo.remover(id);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-pressao',
        onPressed: _registrar,
        backgroundColor: _vermelho,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Registrar',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontVariations: <FontVariation>[FontVariation('wght', 700)],
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.texto,
                  ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      'Pressão',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 26,
                        height: 1.1,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                  if (_itens.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _vermelho.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _vermelho.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        '${_itens.length}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 800),
                          ],
                          fontSize: 15,
                          color: _vermelhoEscuro,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _vermelho))
                  : _itens.isEmpty
                      ? _vazio()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          itemCount: _itens.length + 1,
                          separatorBuilder: (BuildContext _, int __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (BuildContext context, int i) {
                            if (i == _itens.length) return _rodapeFonte();
                            return _cartao(_itens[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio() {
    // Rolável: a explicação das faixas + a fonte não cabem em telas baixas.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _vermelho.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _vermelho.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.monitor_heart_rounded,
                  color: _vermelho, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma medida ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 20,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toque em Registrar para anotar a primeira.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: AppColors.textoSuave,
              ),
            ),
            const SizedBox(height: 22),
            // Referência das faixas — só aparece quando ainda não há medidas,
            // para ensinar sem ocupar espaço no uso do dia a dia.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _vermelho.withValues(alpha: 0.20),
                  width: 1.1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Faixas de referência',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: AppColors.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ClassificacaoPressao.values.map(
                    (ClassificacaoPressao c) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _cor(c),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 74,
                            child: Text(
                              c.rotulo,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _cor(c),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              c.faixa,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textoSuave,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _vermelho.withValues(alpha: 0.16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Referência: Diretrizes Brasileiras de Hipertensão '
                    'Arterial – 2020 (SBC/SBH/SBN), medida no consultório em '
                    'adultos. Crise (180 por 120 ou mais): Ministério da '
                    'Saúde — Linhas de Cuidado de HAS.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: AppColors.textoApagado,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'O app reúne os estágios 2 e 3 em "Alerta" e não '
                    'interpreta sua saúde: quem avalia é o profissional.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textoApagado,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Rodapé da lista: de onde vêm as faixas. Fica sempre visível — a
  /// classificação não pode parecer invenção do app.
  Widget _rodapeFonte() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.menu_book_rounded,
                  size: 13, color: _vermelho.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Faixas: Diretrizes Brasileiras de Hipertensão Arterial – '
                  '2020 (SBC/SBH/SBN); crise (≥180/120): Ministério da Saúde, '
                  'Linhas de Cuidado de HAS.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    color: AppColors.textoApagado,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'O app não interpreta sua saúde — ele guarda as medidas para você '
            'levar ao profissional.',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.3,
              fontStyle: FontStyle.italic,
              color: AppColors.textoApagado,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartao(Medicao m) {
    final Color cor = _cor(m.classificacao);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cor.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.tinta(cor, 0.13),
              AppColors.tinta(cor, 0.24),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withValues(alpha: 0.30), width: 1.1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${m.sistolica}/${m.diastolica}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 28,
                      height: 1.0,
                      color: cor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_data(m.quando)} · ${_hora(m.quando)}'
                    '${m.pulso == null ? '' : ' · pulso ${m.pulso}'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cor.withValues(alpha: 0.35)),
              ),
              child: Text(
                m.classificacao.rotulo,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: cor,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: () => _remover(m),
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.textoApagado,
              iconSize: 19,
            ),
          ],
        ),
      ),
    );
  }

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

/// Folha que pede um número inteiro.
///
/// Tem estado próprio para poder **descartar o controller** no `dispose`, que
/// é o momento correto — depois da animação de saída terminar.
class _CampoNumero extends StatefulWidget {
  const _CampoNumero({
    required this.titulo,
    required this.dica,
    required this.maximo,
    required this.cor,
  });

  final String titulo;
  final String dica;
  final int maximo;
  final Color cor;

  @override
  State<_CampoNumero> createState() => _CampoNumeroState();
}

class _CampoNumeroState extends State<_CampoNumero> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final int? v = int.tryParse(_ctrl.text.trim());
    if (v == null || v < 40 || v > widget.maximo) {
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.titulo,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontVariations: <FontVariation>[FontVariation('wght', 700)],
              fontSize: 20,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.dica,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textoSuave,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22),
            onSubmitted: (_) => _confirmar(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.fundo,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: widget.cor.withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.cor, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.cor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

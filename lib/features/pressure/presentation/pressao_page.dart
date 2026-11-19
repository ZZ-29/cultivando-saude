import 'package:flutter/material.dart';

import 'dart:convert';

import '../../../core/config/config_repositorio.dart';
import '../../../core/theme/app_colors.dart';
import '../data/compartilhar.dart';
import '../data/lembretes_pressao.dart';
import '../data/pressao_repositorio.dart';
import '../domain/texto_pressao.dart';
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

  /// Lembretes de medir a pressão (3x ao dia, pedido da cardiologista).
  bool _lembretesLigados = false;
  List<String> _horarios = List<String>.from(horariosPadraoPressao);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<Medicao> lista = await pressaoRepo.listar();
      final bool ligados =
          (await configRepo.ler(ChavesConfig.lembretesPressao)) == '1';
      final List<String> horarios = await lerHorariosSalvos(
        configRepo,
        ChavesConfig.horariosPressao,
      );
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _lembretesLigados = ligados;
        _horarios = horarios.isEmpty
            ? List<String>.from(horariosPadraoPressao)
            : horarios;
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

  /// Envia as medidas para o WhatsApp — o pedido da cardiologista.
  ///
  /// Abre uma folha para escolher o período (hoje ou últimos 7 dias) e monta a
  /// mensagem já formatada: data, período do dia, valor e pulso, com a média no
  /// fim.
  Future<void> _enviarWhatsapp() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registre uma medida primeiro.')),
      );
      return;
    }

    final int? dias = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Enviar por WhatsApp',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[
                  FontVariation('wght', 700),
                ],
                fontSize: 20,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escolha quais medidas vão na mensagem.',
              style: TextStyle(fontSize: 13, color: AppColors.textoSuave),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Só as de hoje',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(7),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B6B3A),
                  side: const BorderSide(color: Color(0xFF25D366), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Últimos 7 dias',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (dias == null) return;

    final DateTime limite = DateTime.now().subtract(Duration(days: dias));
    final List<Medicao> escolhidas = _itens
        .where((Medicao m) => m.quando.isAfter(limite))
        .toList(growable: false);
    if (escolhidas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma medida nesse período.')),
      );
      return;
    }

    final String texto = textoPressaoParaWhatsapp(escolhidas);
    final bool abriu = await compartilharWhatsapp.enviar(texto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          abriu
              ? 'WhatsApp aberto com as medidas.'
              : 'Medidas copiadas — cole no WhatsApp.',
        ),
      ),
    );
  }

  /// Liga/desliga os três lembretes diários.
  Future<void> _alternarLembretes(bool ligar) async {
    setState(() => _lembretesLigados = ligar);
    await configRepo.salvar(
      ChavesConfig.lembretesPressao,
      ligar ? '1' : '0',
    );

    if (ligar) {
      final bool exato = await lembretesPressao.ligar(_horarios);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exato
                ? 'Lembretes ligados: ${_horarios.join(' · ')}'
                // Quando o Android nega o alarme exato, é honesto avisar.
                : 'Lembretes ligados. O celular pode avisar com alguns minutos '
                    'de diferença.',
          ),
        ),
      );
    } else {
      await lembretesPressao.desligar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lembretes desligados.')),
      );
    }
  }

  /// Troca o horário de um dos três lembretes (manhã, tarde ou noite).
  Future<void> _editarHorario(int indice) async {
    final List<String> partes = _horarios[indice].split(':');
    final TimeOfDay? escolhido = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(partes.first) ?? 8,
        minute: partes.length > 1 ? (int.tryParse(partes[1]) ?? 0) : 0,
      ),
      helpText: 'Horário do lembrete',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (BuildContext context, Widget? filho) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: filho ?? const SizedBox.shrink(),
      ),
    );
    if (escolhido == null) return;

    final String texto =
        '${escolhido.hour.toString().padLeft(2, '0')}:'
        '${escolhido.minute.toString().padLeft(2, '0')}';
    final List<String> novos = List<String>.from(_horarios)..[indice] = texto;
    setState(() => _horarios = novos);
    await configRepo.salvar(
      ChavesConfig.horariosPressao,
      jsonEncode(novos),
    );
    if (_lembretesLigados) await lembretesPressao.ligar(novos);
  }

  /// Bloco de lembretes: três horários, um por período do dia.
  Widget _blocoLembretes() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _vermelho.withValues(alpha: 0.24),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.alarm_rounded, size: 18, color: _vermelhoEscuro),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lembrar de medir 3x ao dia',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 14.5,
                    color: AppColors.texto,
                  ),
                ),
              ),
              Switch(
                value: _lembretesLigados,
                activeThumbColor: _vermelho,
                onChanged: _alternarLembretes,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List<Widget>.generate(_horarios.length, (int i) {
              return ActionChip(
                avatar: const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: _vermelhoEscuro,
                ),
                label: Text(
                  '${periodoDoHorario(_horarios[i])} ${_horarios[i]}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: _vermelho
                    .withValues(alpha: _lembretesLigados ? 0.12 : 0.05),
                side: BorderSide(color: _vermelho.withValues(alpha: 0.30)),
                onPressed: () => _editarHorario(i),
              );
            }),
          ),
          if (!lembretesPressao.disponivel)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'O alarme toca no app Android; aqui o ajuste fica salvo.',
                style:
                    TextStyle(fontSize: 10.5, color: AppColors.textoApagado),
              ),
            ),
        ],
      ),
    );
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
            // Data de hoje: sem ela a pessoa não sabe a que dia pertencem as
            // medidas que está vendo.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
              child: Row(
                children: <Widget>[
                  Icon(Icons.today_rounded,
                      size: 13, color: _vermelho.withValues(alpha: 0.85)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Hoje, ${_dataLonga(DateTime.now())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _vermelhoEscuro.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Enviar ao médico pelo WhatsApp: é o que a cardiologista pediu,
            // sem copiar e colar.
            if (_itens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviarWhatsapp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 19),
                    label: const Text(
                      'Enviar por WhatsApp',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 800),
                        ],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            _blocoLembretes(),
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

  /// "Hoje", "Ontem" ou "18/11" — a data do dia, sem a pessoa ter que
  /// comparar número.
  static String _data(DateTime d, {DateTime? referencia}) {
    final DateTime agora = referencia ?? DateTime.now();
    final DateTime dia = DateTime(d.year, d.month, d.day);
    final DateTime hoje = DateTime(agora.year, agora.month, agora.day);
    final int diferenca = hoje.difference(dia).inDays;
    if (diferenca == 0) return 'Hoje';
    if (diferenca == 1) return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  /// "terça-feira, 18 de novembro de 2026" — data completa de hoje.
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
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/barra_inferior.dart';
import '../../exams/data/exames_repositorio.dart';
import '../../exams/domain/exame.dart';
import '../../exams/presentation/exames_page.dart';
import '../data/agenda_repositorio.dart';
import '../domain/compromisso.dart';

/// Agenda: consultas e exames, com o próximo compromisso em destaque.
///
/// Cada item mostra quando (em linguagem de gente: "Amanhã 10:00"), o tipo e
/// o local. Os passados ficam numa seção separada, apagados.
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const Color _indigo = Color(0xFF5E35B1);
  static const Color _indigoEscuro = Color(0xFF3F2380);

  List<Compromisso> _itens = <Compromisso>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    alturaBarraInferior.addListener(_aoMedirBarra);
    _carregar();
  }

  List<Exame> _exames = <Exame>[];

  void _aoMedirBarra() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    alturaBarraInferior.removeListener(_aoMedirBarra);
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final List<Compromisso> lista = await agendaRepo.listar();
      final List<Exame> exames = await examesRepo.listar();
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _exames = exames;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _abrirExames() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => const ExamesPage(),
      ),
    );
    await _carregar();
  }

  Future<void> _adicionar() async {
    final Compromisso? novo = await showModalBottomSheet<Compromisso>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => const _FormularioCompromisso(),
    );

    if (novo == null) return;
    await agendaRepo.salvar(novo);
    await _carregar();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${novo.titulo}: ${quandoResumido(novo.quando)}')),
    );
  }

  Future<void> _remover(Compromisso c) async {
    final int? id = c.id;
    if (id == null) return;
    await agendaRepo.remover(id);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final List<Compromisso> futuros =
        _itens.where((Compromisso c) => !c.passado).toList(growable: false);
    final List<Compromisso> passados =
        _itens.where((Compromisso c) => c.passado).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-agenda',
        onPressed: _adicionar,
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Adicionar',
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
                  // Seta só quando a tela foi aberta como rota (não como aba).
                  if (Navigator.of(context).canPop()) ...<Widget>[
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.texto,
                    ),
                    const SizedBox(width: 2),
                  ],
                  const Expanded(
                    child: Text(
                      'Agenda',
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
                        color: _indigo.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _indigo.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        '${futuros.length}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 800),
                          ],
                          fontSize: 15,
                          color: _indigoEscuro,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _indigo))
                  : _itens.isEmpty
                      ? ListView(
                          padding: EdgeInsets.fromLTRB(16, 6, 16, respiroInferior),
                          children: <Widget>[
                            _cartaoExames(),
                            const SizedBox(height: 10),
                            _vazio(),
                          ],
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(16, 6, 16, respiroInferior),
                          children: <Widget>[
                            _cartaoExames(),
                            const SizedBox(height: 4),
                            if (futuros.isNotEmpty) ...<Widget>[
                              _secao('Próximos'),
                              ...futuros.map(_cartao),
                            ],
                            if (passados.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              _secao('Já passaram'),
                              ...passados.map(
                                (Compromisso c) => _cartao(c, apagado: true),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoExames() {
    final int comFoto = _exames.where((Exame e) => e.temFoto).length;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirExames,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.tinta(const Color(0xFF5E35B1), 0.09),
                AppColors.tinta(const Color(0xFF5E35B1), 0.17),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF5E35B1).withValues(alpha: 0.26),
              width: 1.1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E35B1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.science_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Meus exames',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 800),
                        ],
                        fontSize: 15,
                        color: Color(0xFF3F2380),
                      ),
                    ),
                    Text(
                      _exames.isEmpty
                          ? 'guarde o resultado e quem pediu'
                          : '${_exames.length} guardado'
                              '${_exames.length == 1 ? '' : 's'}'
                              '${comFoto == 0 ? '' : ' · $comFoto com foto'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF5E35B1), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 0, 8),
      child: Text(
        titulo,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontVariations: const <FontVariation>[FontVariation('wght', 700)],
          fontSize: 13,
          letterSpacing: 0.4,
          color: AppColors.textoApagado,
        ),
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _indigo.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _indigo.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _indigo, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhum compromisso',
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
              'Toque em Adicionar para marcar uma consulta ou exame.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: AppColors.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartao(Compromisso c, {bool apagado = false}) {
    final Color cor = apagado ? AppColors.textoApagado : _indigo;
    final Color corTexto = apagado ? AppColors.textoSuave : _indigoEscuro;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: apagado
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: _indigo.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.tinta(cor, apagado ? 0.06 : 0.12),
              AppColors.tinta(cor, apagado ? 0.10 : 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withValues(alpha: 0.26), width: 1.1),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: apagado ? 0.14 : 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                switch (c.tipo) {
                  TipoCompromisso.consulta => Icons.medical_services_rounded,
                  TipoCompromisso.exame => Icons.science_rounded,
                  TipoCompromisso.outro => Icons.event_rounded,
                },
                color: apagado ? cor : Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    c.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 16,
                      height: 1.15,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quandoResumido(c.quando)} · ${c.tipo.rotulo}'
                    '${c.local.isEmpty ? '' : ' · ${c.local}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      color: AppColors.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: () => _remover(c),
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.textoApagado,
              iconSize: 19,
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulário do compromisso, em folha deslizante.
class _FormularioCompromisso extends StatefulWidget {
  const _FormularioCompromisso();

  @override
  State<_FormularioCompromisso> createState() => _FormularioCompromissoState();
}

class _FormularioCompromissoState extends State<_FormularioCompromisso> {
  static const Color _indigo = Color(0xFF5E35B1);

  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _local = TextEditingController();

  TipoCompromisso _tipo = TipoCompromisso.consulta;
  DateTime _quando = DateTime.now().add(const Duration(days: 1));
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _local.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _quando,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Data do compromisso',
      cancelText: 'Cancelar',
      confirmText: 'Escolher',
    );
    if (d == null) return;
    setState(() {
      _quando = DateTime(d.year, d.month, d.day, _quando.hour, _quando.minute);
    });
  }

  Future<void> _escolherHora() async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_quando),
    );
    if (t == null) return;
    setState(() {
      _quando = DateTime(
        _quando.year,
        _quando.month,
        _quando.day,
        t.hour,
        t.minute,
      );
    });
  }

  void _salvar() {
    final String titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      setState(() => _erro = 'Escreva o nome do compromisso.');
      return;
    }
    Navigator.of(context).pop(
      Compromisso(
        titulo: titulo,
        tipo: _tipo,
        quando: _quando,
        local: _local.text.trim(),
      ),
    );
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Novo compromisso',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 21,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Título', 'Ex.: Cardiologista'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _local,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Local (opcional)', 'Ex.: Clínica Central'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TipoCompromisso.values.map((TipoCompromisso t) {
                final bool marcado = _tipo == t;
                return ChoiceChip(
                  label: Text(t.rotulo),
                  selected: marcado,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: marcado ? Colors.white : _indigo,
                  ),
                  selectedColor: _indigo,
                  backgroundColor: AppColors.card,
                  side: BorderSide(color: _indigo.withValues(alpha: 0.30)),
                  onSelected: (bool _) => setState(() => _tipo = t),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _escolherData,
                      style: _estiloBotao(),
                      icon: const Icon(Icons.calendar_today_rounded, size: 17),
                      label: Text(
                        '${_quando.day.toString().padLeft(2, '0')}/'
                        '${_quando.month.toString().padLeft(2, '0')}/'
                        '${_quando.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _escolherHora,
                      style: _estiloBotao(),
                      icon: const Icon(Icons.schedule_rounded, size: 17),
                      label: Text(
                        '${_quando.hour.toString().padLeft(2, '0')}:'
                        '${_quando.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_erro != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFB71C1C)),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracao(String rotulo, String dica) => InputDecoration(
        labelText: rotulo,
        hintText: dica,
        filled: true,
        fillColor: AppColors.fundo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _indigo.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _indigo, width: 1.8),
        ),
      );

  ButtonStyle _estiloBotao() => OutlinedButton.styleFrom(
        backgroundColor: AppColors.fundo,
        foregroundColor: _indigo,
        side: BorderSide(color: _indigo.withValues(alpha: 0.35), width: 1.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      );
}

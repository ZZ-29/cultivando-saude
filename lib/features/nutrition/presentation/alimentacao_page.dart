import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/plano_repositorio.dart';
import '../domain/refeicao.dart';

/// Plano Alimentar **pessoal**: a pessoa escreve as refeições dela.
///
/// O app não prescreve dieta e não assina plano de ninguém — guarda o que foi
/// combinado com o nutricionista e mostra no dia a dia. Por isso o conteúdo
/// começa vazio, com um convite a escrever a primeira refeição.
class AlimentacaoPage extends StatefulWidget {
  const AlimentacaoPage({super.key});

  @override
  State<AlimentacaoPage> createState() => _AlimentacaoPageState();
}

class _AlimentacaoPageState extends State<AlimentacaoPage> {
  static const Color _verdeLima = Color(0xFFC9A227);
  static const Color _verdeOliva = Color(0xFF7A5F00);

  List<Refeicao> _refeicoes = <Refeicao>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final List<Refeicao> lista = await planoRepo.ler();
    if (!mounted) return;
    setState(() {
      _refeicoes = lista;
      _carregando = false;
    });
  }

  Future<void> _gravar() async {
    await planoRepo.salvar(_refeicoes);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _novaRefeicao() async {
    final Refeicao? nova = await showModalBottomSheet<Refeicao>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => const _FolhaRefeicao(),
    );
    if (nova == null) return;

    setState(() => _refeicoes = <Refeicao>[..._refeicoes, nova]);
    await _gravar();
  }

  Future<void> _editar(Refeicao r, int indice) async {
    final Refeicao? editada = await showModalBottomSheet<Refeicao>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => _FolhaRefeicao(inicial: r),
    );
    if (editada == null) return;

    setState(() {
      final List<Refeicao> copia = List<Refeicao>.from(_refeicoes);
      copia[indice] = editada;
      _refeicoes = copia;
    });
    await _gravar();
  }

  Future<void> _remover(int indice) async {
    setState(() {
      final List<Refeicao> copia = List<Refeicao>.from(_refeicoes)
        ..removeAt(indice);
      _refeicoes = copia;
    });
    await _gravar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-plano',
        onPressed: _novaRefeicao,
        backgroundColor: _verdeLima,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Refeição',
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
                  if (Navigator.of(context).canPop())
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.texto,
                    ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      'Plano Alimentar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 24,
                        height: 1.1,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 6),
              child: Text(
                'Seu plano, do seu jeito. O app só guarda o que você escrever — '
                'quem orienta a dieta é o nutricionista.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: AppColors.textoSuave,
                ),
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _verdeLima))
                  : _refeicoes.isEmpty
                      ? _vazio()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          itemCount: _refeicoes.length,
                          separatorBuilder: (BuildContext _, int __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (BuildContext context, int i) =>
                              _cartao(_refeicoes[i], i),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _verdeLima.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _verdeLima.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.restaurant_rounded,
                  color: _verdeOliva, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma refeição ainda',
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
              'Toque em "Refeição" e escreva o que você come em cada uma. '
              'Ex.: Café da manhã — ovos, bacon, café.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartao(Refeicao r, int indice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_verdeLima, 0.10),
            AppColors.tinta(_verdeLima, 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _verdeLima.withValues(alpha: 0.30),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _verdeLima,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  r.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 16,
                    color: _verdeOliva,
                  ),
                ),
              ),
              if (r.horario.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    r.horario,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _verdeOliva.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Editar',
                onPressed: () => _editar(r, indice),
                icon: const Icon(Icons.edit_outlined),
                color: _verdeOliva,
                iconSize: 19,
              ),
              IconButton(
                tooltip: 'Remover',
                onPressed: () => _remover(indice),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textoApagado,
                iconSize: 19,
              ),
            ],
          ),
          if (r.itens.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                'Sem itens ainda — toque no lápis para escrever.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textoApagado,
                ),
              ),
            )
          else
            ...r.itens.map(
              (String item) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 7),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _verdeLima,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13.5,
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
    );
  }
}

/// Folha de nova refeição / edição.
class _FolhaRefeicao extends StatefulWidget {
  const _FolhaRefeicao({this.inicial});

  final Refeicao? inicial;

  @override
  State<_FolhaRefeicao> createState() => _FolhaRefeicaoState();
}

class _FolhaRefeicaoState extends State<_FolhaRefeicao> {
  static const Color _verdeLima = Color(0xFFC9A227);

  late final TextEditingController _titulo =
      TextEditingController(text: widget.inicial?.titulo ?? '');
  late final TextEditingController _horario =
      TextEditingController(text: widget.inicial?.horario ?? '');
  late final TextEditingController _item = TextEditingController();

  late List<String> _itens = List<String>.from(widget.inicial?.itens ?? const <String>[]);

  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _horario.dispose();
    _item.dispose();
    super.dispose();
  }

  void _adicionarItem() {
    final String texto = _item.text.trim();
    if (texto.isEmpty) return;
    setState(() => _itens = <String>[..._itens, texto]);
    _item.clear();
  }

  void _salvar() {
    final String titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      setState(() => _erro = 'Dê um nome à refeição.');
      return;
    }
    if (_item.text.trim().isNotEmpty) _adicionarItem();

    Navigator.of(context).pop(
      Refeicao(
        id: widget.inicial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        titulo: titulo,
        horario: _horario.text.trim(),
        itens: _itens,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.inicial == null ? 'Nova refeição' : 'Editar refeição',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      fontSize: 21,
                      color: AppColors.texto,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textoSuave,
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Nome da refeição', 'Ex.: Café da manhã'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _horario,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Horário (opcional)', 'Ex.: 07:00'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Itens',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 13.5,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 6),
            ..._itens.asMap().entries.map(
                  (MapEntry<int, String> e) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: _verdeLima),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.texto),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover item',
                          onPressed: () => setState(() {
                            final List<String> copia =
                                List<String>.from(_itens)..removeAt(e.key);
                            _itens = copia;
                          }),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textoApagado,
                          iconSize: 16,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _item,
                    style: const TextStyle(fontSize: 15),
                    onSubmitted: (_) => _adicionarItem(),
                    decoration: _decoracao('Adicionar item', 'Ex.: 3 ovos'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _adicionarItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verdeLima,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                ),
              ],
            ),
            if (_erro != null) ...<Widget>[
              const SizedBox(height: 8),
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
                  backgroundColor: _verdeLima,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Salvar refeição',
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
            color: _verdeLima.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _verdeLima, width: 1.8),
        ),
      );
}

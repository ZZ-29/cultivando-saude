import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/barra_inferior.dart';
import '../data/contatos_repositorio.dart';
import '../domain/contato.dart';

/// Segurança: contatos de emergência + resumo do cartão de saúde.
///
/// Os contatos são a parte viva: dá para ter **quantos quiser** (filho, filha,
/// vizinho, cuidador), com nome e parentesco. O resto da tela é leitura do que
/// já existe no perfil.
class SegurancaPage extends StatefulWidget {
  const SegurancaPage({super.key});

  @override
  State<SegurancaPage> createState() => _SegurancaPageState();
}

class _SegurancaPageState extends State<SegurancaPage> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _tealEscuro = Color(0xFF00564D);

  List<Contato> _contatos = <Contato>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    alturaBarraInferior.addListener(_aoMedirBarra);
    _carregar();
  }

  @override
  void dispose() {
    alturaBarraInferior.removeListener(_aoMedirBarra);
    super.dispose();
  }

  void _aoMedirBarra() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    try {
      final List<Contato> lista = await contatosRepo.listar();
      if (!mounted) return;
      setState(() {
        _contatos = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _adicionar({Contato? editar}) async {
    final Contato? novo = await showModalBottomSheet<Contato>(
      context: context,
      isScrollControlled: true,
      // Sem isso a folha pode ocupar a tela inteira e a pessoa não acha como
      // fechar: a alça de arraste + o X resolvem, e tocar fora também fecha.
      showDragHandle: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => _FormularioContato(inicial: editar),
    );
    if (novo == null) return;

    await contatosRepo.salvar(
        editar == null ? novo : novo.copiarCom(id: editar.id));
    await _carregar();
  }

  Future<void> _remover(Contato c) async {
    final int? id = c.id;
    if (id == null) return;
    await contatosRepo.remover(id);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, respiroInferior),
        children: <Widget>[
          // ---- Cabeçalho ------------------------------------------------
          Row(
            children: <Widget>[
              // Seta só quando a tela foi aberta como rota (ex.: vinda do SOS).
              // Como aba, ela não tem para onde voltar.
              if (Navigator.of(context).canPop()) ...<Widget>[
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.texto,
                ),
                const SizedBox(width: 2),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _teal.withValues(alpha: 0.30),
                    width: 1.1,
                  ),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Segurança',
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
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _adicionar(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Contato',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ---- Contatos --------------------------------------------------
          const _TituloSecao(
            texto: 'Contatos de emergência',
            cor: _teal,
            dica: 'Quem ligar se você precisar de ajuda',
          ),
          const SizedBox(height: 8),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Carregando…', style: TextStyle(fontSize: 14)),
            )
          else if (_contatos.isEmpty)
            _vazioContatos()
          else
            ..._contatos.map(_cartaoContato),

          const SizedBox(height: 20),

          // ---- Cartão de saúde ------------------------------------------
          const _TituloSecao(
            texto: 'Cartão de saúde',
            cor: _teal,
            dica: 'O que outra pessoa precisa saber sobre você',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.tinta(_teal, 0.07),
                  AppColors.tinta(_teal, 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _teal.withValues(alpha: 0.26),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Preenchido em "Meus dados": nome, idade e tipo sanguíneo.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O tipo sanguíneo aparece no card da tela inicial.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppColors.textoApagado,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazioContatos() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _teal.withValues(alpha: 0.20),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.person_add_alt_1_rounded, color: _teal, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Nenhum contato ainda. Cadastre pelo menos um — de preferência '
              'dois ou três.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.3,
                color: AppColors.textoSuave,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoContato(Contato c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_teal, 0.11),
            AppColors.tinta(_teal, 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withValues(alpha: 0.26), width: 1.1),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  c.parentesco.isEmpty
                      ? c.nome
                      : '${c.nome} · ${c.parentesco}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 14.5,
                    height: 1.1,
                    color: _tealEscuro,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  telefoneFormatado(c.telefone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                    fontSize: 12.5,
                    height: 1.15,
                    color: AppColors.texto,
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
            iconSize: 17,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.texto,
    required this.cor,
    required this.dica,
  });

  final String texto;
  final Color cor;
  final String dica;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              texto,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                ],
                fontSize: 14.5,
                color: cor,
              ),
            ),
          ],
        ),
        if (dica.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 13, top: 1),
            child: Text(
              dica,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textoApagado,
              ),
            ),
          ),
      ],
    );
  }
}

/// Formulário de contato, em folha deslizante.
class _FormularioContato extends StatefulWidget {
  const _FormularioContato({this.inicial});

  final Contato? inicial;

  @override
  State<_FormularioContato> createState() => _FormularioContatoState();
}

class _FormularioContatoState extends State<_FormularioContato> {
  static const Color _teal = Color(0xFF00897B);

  late final TextEditingController _nome =
      TextEditingController(text: widget.inicial?.nome ?? '');
  late final TextEditingController _fone =
      TextEditingController(text: widget.inicial?.telefone ?? '');
  late final TextEditingController _parentesco =
      TextEditingController(text: widget.inicial?.parentesco ?? '');

  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _fone.dispose();
    _parentesco.dispose();
    super.dispose();
  }

  void _salvar() {
    final String nome = _nome.text.trim();
    final String fone = soDigitos(_fone.text);

    if (nome.isEmpty) {
      setState(() => _erro = 'Escreva o nome do contato.');
      return;
    }
    if (fone.length < 8) {
      setState(() => _erro = 'Telefone incompleto.');
      return;
    }

    Navigator.of(context).pop(
      Contato(
        nome: nome,
        telefone: fone,
        parentesco: _parentesco.text.trim(),
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
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Contato de emergência',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      fontSize: 21,
                      color: AppColors.texto,
                    ),
                  ),
                ),
                // Fechar sempre visível — foi o ponto que faltou antes.
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textoSuave,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Nome', 'Ex.: Ana (filha)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fone,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Telefone', 'Ex.: (21) 99999-8888'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _parentesco,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Parentesco (opcional)', 'Ex.: filha'),
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
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Salvar contato',
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
            color: _teal.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _teal, width: 1.8),
        ),
      );
}

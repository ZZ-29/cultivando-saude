import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/perfil_repositorio.dart';
import '../domain/perfil.dart';

/// Cadastro / edição dos dados da pessoa.
///
/// Só três campos — nome, nascimento e tipo sanguíneo — porque é o que o app
/// precisa para identificar quem é e para o cartão de saúde. Tudo local: a
/// promessa da barra inferior é que nada sai do celular.
///
/// A data é digitada em **dd/mm/aaaa** (folha com três campos), não escolhida
/// num calendário: para quem nasceu em 1950, navegar mês a mês até o ano é
/// trabalho sem sentido.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const Color _lilas = Color(0xFF8E6FD8);
  static const Color _lilasEscuro = Color(0xFF5B3FA8);
  static const Color _verde = Color(0xFF2E9E4F);

  final TextEditingController _nome = TextEditingController();
  final TextEditingController _peso = TextEditingController();

  DateTime? _nascimento;
  String? _sangue;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _peso.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final Perfil p = await perfilRepo.ler();
    if (!mounted) return;
    setState(() {
      _nome.text = p.nome;
      _nascimento = p.nascimento;
      _sangue = p.tipoSanguineo;
      _peso.text = p.peso == null
          ? ''
          : p.peso!.toStringAsFixed(p.peso! % 1 == 0 ? 0 : 1);
      _carregando = false;
    });
  }

  Future<void> _digitarData() async {
    final DateTime? escolhida = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => _FolhaData(inicial: _nascimento),
    );
    if (escolhida != null) {
      setState(() {
        _nascimento = escolhida;
        _erro = null;
      });
    }
  }

  Future<void> _salvar() async {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Escreva seu nome.');
      return;
    }

    try {
      await perfilRepo.salvar(
        Perfil(
          nome: nome,
          nascimento: _nascimento,
          tipoSanguineo: _sangue,
          peso: double.tryParse(_peso.text.trim().replaceAll(',', '.')),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (erro) {
      setState(() => _erro = 'Não consegui salvar: $erro');
    }
  }

  static String _data(DateTime? d) {
    if (d == null) return 'dd/mm/aaaa';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
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
                      'Meus dados',
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
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _lilas),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      children: <Widget>[
                        _Bloco(
                          titulo: 'Quem é você',
                          cor: _lilas,
                          filho: TextField(
                            controller: _nome,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.texto),
                            decoration: InputDecoration(
                              labelText: 'Seu nome',
                              hintText: 'Ex.: Maria Aparecida',
                              filled: true,
                              fillColor: AppColors.card,
                              prefixIcon: const Icon(Icons.person_rounded,
                                  color: _lilasEscuro, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _lilas.withValues(alpha: 0.30),
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _lilas, width: 1.8),
                              ),
                            ),
                          ),
                        ),
                        _Bloco(
                          titulo: 'Nascimento',
                          cor: _lilas,
                          filho: SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _digitarData,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.card,
                                foregroundColor: _lilasEscuro,
                                side: BorderSide(
                                  color: _lilas.withValues(alpha: 0.35),
                                  width: 1.1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.cake_rounded, size: 19),
                              label: Text(
                                _data(_nascimento),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _Bloco(
                          titulo: 'Peso',
                          cor: _lilas,
                          filho: TextField(
                            controller: _peso,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.texto),
                            decoration: InputDecoration(
                              labelText: 'Peso em kg (opcional)',
                              hintText: 'Ex.: 72',
                              helperText: 'Usado só para estimar calorias '
                                  'no card de Esportes.',
                              helperMaxLines: 2,
                              filled: true,
                              fillColor: AppColors.card,
                              prefixIcon: const Icon(Icons.monitor_weight_rounded,
                                  color: _lilasEscuro, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _lilas.withValues(alpha: 0.30),
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _lilas, width: 1.8),
                              ),
                            ),
                          ),
                        ),
                        _Bloco(
                          titulo: 'Tipo sanguíneo',
                          cor: _lilas,
                          filho: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              ...kTiposSanguineos.map(_chipSangue),
                              _chipSangueTexto(kSangueNaoSei, kSangueNaoSei),
                            ],
                          ),
                        ),
                        if (_erro != null) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFB71C1C), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _erro!,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFB71C1C)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _verde,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 22),
                            label: const Text(
                              'Salvar meus dados',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontVariations: <FontVariation>[
                                  FontVariation('wght', 800),
                                ],
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: <Widget>[
                            Icon(Icons.lock_outline_rounded,
                                size: 14, color: AppColors.textoApagado),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Fica só neste celular. Nada é enviado para a '
                                'internet.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.25,
                                  color: AppColors.textoApagado,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipSangue(String tipo) => _chipSangueTexto(tipo, tipo);

  Widget _chipSangueTexto(String rotulo, String valor) {
    final bool marcado = _sangue == valor;
    return ChoiceChip(
      label: Text(rotulo),
      selected: marcado,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: marcado ? Colors.white : _lilasEscuro,
      ),
      selectedColor: _lilas,
      backgroundColor: AppColors.card,
      side: BorderSide(color: _lilas.withValues(alpha: 0.30)),
      onSelected: (bool _) => setState(() {
        _sangue = marcado ? null : valor;
        _erro = null;
      }),
    );
  }
}

/// Folha para digitar a data: três campos (dia, mês, ano).
class _FolhaData extends StatefulWidget {
  const _FolhaData({this.inicial});

  final DateTime? inicial;

  @override
  State<_FolhaData> createState() => _FolhaDataState();
}

class _FolhaDataState extends State<_FolhaData> {
  static const Color _lilas = Color(0xFF8E6FD8);

  late final TextEditingController _dia = TextEditingController(
    text: widget.inicial?.day.toString().padLeft(2, '0') ?? '',
  );
  late final TextEditingController _mes = TextEditingController(
    text: widget.inicial?.month.toString().padLeft(2, '0') ?? '',
  );
  late final TextEditingController _ano = TextEditingController(
    text: widget.inicial?.year.toString() ?? '',
  );

  final FocusNode _fDia = FocusNode();
  final FocusNode _fMes = FocusNode();
  final FocusNode _fAno = FocusNode();

  String? _erro;

  @override
  void dispose() {
    _dia.dispose();
    _mes.dispose();
    _ano.dispose();
    _fDia.dispose();
    _fMes.dispose();
    _fAno.dispose();
    super.dispose();
  }

  /// Ao digitar, pula para o próximo campo — como se digita data no papel.
  ///
  ///   • dia: com 2 dígitos, ou 1 dígito de 4 a 9 (não existe dia 40) → mês;
  ///   • mês: com 2 dígitos, ou 1 dígito de 2 a 9 (não existe mês 20) → ano;
  ///   • ano: com 4 dígitos → fecha o teclado.
  void _aoDigitarDia(String v) {
    final bool dois = v.length >= 2;
    final bool impossivel = v.length == 1 && '456789'.contains(v);
    if (dois || impossivel) _fMes.requestFocus();
  }

  void _aoDigitarMes(String v) {
    final bool dois = v.length >= 2;
    final bool impossivel = v.length == 1 && '23456789'.contains(v);
    if (dois || impossivel) _fAno.requestFocus();
  }

  void _aoDigitarAno(String v) {
    if (v.length >= 4) _fAno.unfocus();
  }

  void _confirmar() {
    final int? d = int.tryParse(_dia.text.trim());
    final int? m = int.tryParse(_mes.text.trim());
    final int? a = int.tryParse(_ano.text.trim());

    if (d == null || m == null || a == null) {
      setState(() => _erro = 'Preencha dia, mês e ano.');
      return;
    }
    if (d < 1 || d > 31 || m < 1 || m > 12 || a < 1900) {
      setState(() => _erro = 'Data inválida.');
      return;
    }

    final DateTime data = DateTime(a, m, d);
    // DateTime "rola" datas impossíveis (31/02 vira 03/03): se rolou, é inválida.
    if (data.day != d || data.month != m || data.year != a) {
      setState(() => _erro = 'Essa data não existe.');
      return;
    }

    final DateTime hoje = DateTime.now();
    if (data.isAfter(hoje)) {
      setState(() => _erro = 'A data não pode ser no futuro.');
      return;
    }
    if (hoje.year - a > 120) {
      setState(() => _erro = 'Confira o ano.');
      return;
    }

    Navigator.of(context).pop(data);
  }

  Widget _campo(
    TextEditingController ctrl,
    String rotulo,
    String dica, {
    int? maxLength,
    FocusNode? foco,
    ValueChanged<String>? aoDigitar,
    TextInputAction acao = TextInputAction.next,
  }) {
    return TextField(
      controller: ctrl,
      focusNode: foco,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      textInputAction: acao,
      onChanged: aoDigitar,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        counterText: '',
        filled: true,
        fillColor: AppColors.fundo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _lilas.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lilas, width: 1.8),
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Data de nascimento',
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
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(null),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textoSuave,
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Digite só os números: dia, mês e ano.',
            style: TextStyle(fontSize: 13, color: AppColors.textoSuave),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              SizedBox(
                width: 74,
                child: _campo(
                  _dia,
                  'Dia',
                  '13',
                  maxLength: 2,
                  foco: _fDia,
                  aoDigitar: _aoDigitarDia,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 74,
                child: _campo(
                  _mes,
                  'Mês',
                  '11',
                  maxLength: 2,
                  foco: _fMes,
                  aoDigitar: _aoDigitarMes,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _campo(
                  _ano,
                  'Ano',
                  '1950',
                  maxLength: 4,
                  foco: _fAno,
                  aoDigitar: _aoDigitarAno,
                  acao: TextInputAction.done,
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
              onPressed: _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lilas,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirmar data',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão de seção.
class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.titulo,
    required this.cor,
    required this.filho,
  });

  final String titulo;
  final Color cor;
  final Widget filho;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(cor, 0.07),
            AppColors.tinta(cor, 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.26), width: 1.1),
      ),
      child: Column(
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
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    fontSize: 14.5,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          filho,
        ],
      ),
    );
  }
}

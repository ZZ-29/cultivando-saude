import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/atividade.dart';

/// MODO ATIVIDADE — cronômetro ao vivo enquanto a pessoa caminha.
///
/// Mostra tempo, calorias em tempo real (pela fórmula do Compendium) e avisa
/// **quando beber água** a cada X minutos. Ao encerrar, devolve a [Atividade]
/// pronta para salvar — quem chamou só grava.
///
/// A notificação fora do app (tela bloqueada) é fase Android; aqui o aviso é
/// faixa no topo + vibração leve.
class AtividadeAoVivoPage extends StatefulWidget {
  const AtividadeAoVivoPage({
    required this.tipo,
    required this.intensidade,
    this.pesoKg,
    super.key,
  });

  final TipoAtividade tipo;
  final Intensidade intensidade;
  final double? pesoKg;

  @override
  State<AtividadeAoVivoPage> createState() => _AtividadeAoVivoPageState();
}

class _AtividadeAoVivoPageState extends State<AtividadeAoVivoPage> {
  static const Color _laranja = Color(0xFFFB8C00);
  static const Color _laranjaEscuro = Color(0xFFA85A00);
  static const Color _azul = Color(0xFF2962FF);

  late final DateTime _inicio = DateTime.now();

  /// Contagem por tiques do cronômetro (não por `DateTime.now()`): assim o
  /// tempo não "pula" se o relógio do aparelho mudar, e o teste consegue
  /// avançar o tempo.
  int _segundos = 0;
  Duration get _decorrido => Duration(seconds: _segundos);
  Timer? _cronometro;

  int _intervaloAguaMin = 15;
  int _proximoAvisoMin = 15;
  bool _avisarAgora = false;

  @override
  void initState() {
    super.initState();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _segundos++;
        if (_segundos ~/ 60 >= _proximoAvisoMin) {
          _avisarAgora = true;
          _proximoAvisoMin = (_segundos ~/ 60) + _intervaloAguaMin;
        }
      });
    });
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    super.dispose();
  }

  double get _minutos => _decorrido.inSeconds / 60.0;

  double? get _kcal {
    final double? peso = widget.pesoKg;
    if (peso == null) return null;
    return metDe(widget.tipo, widget.intensidade) *
        3.5 *
        peso /
        200 *
        _segundos /
        60;
  }

  String get _tempoTexto {
    final String m = _decorrido.inMinutes.toString().padLeft(2, '0');
    final String s = (_decorrido.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _marcarAguaBebida() {
    HapticFeedback.mediumImpact();
    setState(() => _avisarAgora = false);
  }

  void _encerrar() {
    _cronometro?.cancel();
    final int minutos = _decorrido.inMinutes < 1 ? 1 : _decorrido.inMinutes;
    Navigator.of(context).pop(
      Atividade(
        tipo: widget.tipo,
        intensidade: widget.intensidade,
        minutos: minutos,
        quando: _inicio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: <Widget>[
              // ---- Cabeçalho --------------------------------------------
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Encerrar',
                    onPressed: _encerrar,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.texto,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${widget.tipo.rotulo} · ${widget.intensidade.rotulo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 18,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                ],
              ),

              // ---- Aviso de água ---------------------------------------
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: _avisarAgora
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: _azul.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _azul.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Text('💧', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Hora de beber água',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 800),
                                  ],
                                  fontSize: 16,
                                  color: _azul,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _marcarAguaBebida,
                              style: TextButton.styleFrom(
                                foregroundColor: _azul,
                              ),
                              child: const Text(
                                'Bebi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ---- Cronômetro ------------------------------------------
              const Spacer(),
              // FittedBox: o número encolhe em tela estreita em vez de estourar.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _tempoTexto,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 76,
                    height: 1.0,
                    letterSpacing: -2,
                    color: AppColors.texto,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'tempo em movimento',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textoApagado,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _dado(
                    valor: _kcal == null ? '—' : '${_kcal!.round()}',
                    rotulo: 'kcal',
                  ),
                  const SizedBox(width: 28),
                  _dado(
                    valor: '${_decorrido.inMinutes}',
                    rotulo: 'minutos',
                  ),
                ],
              ),
              const Spacer(),

              // ---- Intervalo de água -----------------------------------
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: <Widget>[
                  const Text('💧', style: TextStyle(fontSize: 16)),
                  const Text(
                    'Lembrar de beber água a cada',
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.textoSuave),
                  ),
                  DropdownButton<int>(
                    value: _intervaloAguaMin,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _laranjaEscuro,
                    ),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(value: 10, child: Text('10 min')),
                      DropdownMenuItem<int>(value: 15, child: Text('15 min')),
                      DropdownMenuItem<int>(value: 20, child: Text('20 min')),
                    ],
                    onChanged: (int? v) {
                      if (v == null) return;
                      setState(() {
                        _intervaloAguaMin = v;
                        _proximoAvisoMin = (_segundos ~/ 60) + v;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Encerrar --------------------------------------------
              SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _encerrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _laranja,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 24),
                  label: const Text(
                    'ENCERRAR ATIVIDADE',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dado({required String valor, required String rotulo}) {
    return Column(
      children: <Widget>[
        Text(
          valor,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontVariations: <FontVariation>[FontVariation('wght', 800)],
            fontSize: 30,
            height: 1.0,
            color: _laranjaEscuro,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          style: const TextStyle(fontSize: 12, color: AppColors.textoApagado),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/card_config.dart';
import '../../features/medications/data/repositorio.dart';
import '../../features/medications/domain/medicamento.dart';
import '../../features/medications/domain/motor.dart';

/// Card de REMÉDIOS — o card do horário, agora com dados reais.
///
/// Mostra:
///   • o relógio atual (grande, à direita) — é o dado que se procura de relance;
///   • quantas doses do dia já foram tomadas;
///   • a hora da próxima dose.
///
/// Os dados vêm do mesmo repositório da tela de remédios: no Android o SQLite,
/// na preview a memória. O card se atualiza sozinho, e a Dashboard pede uma
/// recarga quando você volta da tela de remédios (via [CartaoRemediosState]).
class CartaoRemedios extends StatefulWidget {
  const CartaoRemedios({
    required this.config,
    this.aoTocar,
    super.key,
  });

  final CardConfig config;
  final VoidCallback? aoTocar;

  @override
  State<CartaoRemedios> createState() => CartaoRemediosState();
}

class CartaoRemediosState extends State<CartaoRemedios> {
  late DateTime _agora = DateTime.now();
  Timer? _relogio;

  int _total = 0;
  int _tomadas = 0;
  DateTime? _proxima;
  bool _carregou = false;

  static const double _raio = 20;

  @override
  void initState() {
    super.initState();
    _recarregar();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime novo = DateTime.now();
      if (novo.minute != _agora.minute || novo.hour != _agora.hour) {
        setState(() => _agora = novo);
        _recarregar();
      }
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  /// Relê as doses do dia. Chamada na abertura, a cada minuto e quando a
  /// Dashboard volta da tela de remédios.
  Future<void> recarregar() => _recarregar();

  Future<void> _recarregar() async {
    try {
      final DateTime agora = DateTime.now();
      final List<Medicamento> meds = await medicamentosRepo.listar();

      int total = 0;
      int tomadas = 0;
      DateTime? proxima;

      for (final Medicamento med in meds) {
        final List<Ocorrencia> hoje =
            MotorRemedios.ocorrenciasDoDia(med, agora);
        final int? id = med.id;
        final Set<String> chaves =
            id == null ? <String>{} : await medicamentosRepo.tomadas(id);

        for (final Ocorrencia o in hoje) {
          final EstadoDose estado =
              MotorRemedios.estadoDe(o, agora, chaves);
          if (estado == EstadoDose.suspenso) continue;
          total++;
          if (estado == EstadoDose.tomado) tomadas++;
          if (estado == EstadoDose.agendado &&
              (proxima == null || o.quando.isBefore(proxima))) {
            proxima = o.quando;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _total = total;
        _tomadas = tomadas;
        _proxima = proxima;
        _carregou = true;
        _agora = agora;
      });
    } catch (_) {
      // Sem banco (ou erro de leitura), o card segue mostrando o relógio.
      if (!mounted) return;
      setState(() => _carregou = true);
    }
  }

  String get _hora =>
      '${_agora.hour.toString().padLeft(2, '0')}:${_agora.minute.toString().padLeft(2, '0')}';

  /// "2 de 4 tomados · próxima 20:00"
  String get _resumo {
    if (!_carregou) return '…';
    if (_total == 0) {
      return 'sem dose hoje';
    }
    final String contagem = '$_tomadas de $_total tomados';
    if (_proxima == null) return '$contagem · em dia';
    final String hh =
        '${_proxima!.hour.toString().padLeft(2, '0')}:${_proxima!.minute.toString().padLeft(2, '0')}';
    return '$contagem · próxima $hh';
  }

  @override
  Widget build(BuildContext context) {
    final CardConfig c = widget.config;
    final Color corTexto = c.corBotao;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_raio),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: c.cor.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_raio),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.tinta(c.cor, 0.13),
                AppColors.tinta(c.cor, 0.26),
              ],
            ),
            borderRadius: BorderRadius.circular(_raio),
            border: Border.all(
              color: c.cor.withValues(alpha: 0.28),
              width: 1.1,
            ),
          ),
          child: InkWell(
            onTap: widget.aoTocar,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints limites) {
                final double corpoHora = limites.maxWidth >= 240 ? 34 : 26;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(11, 8, 10, 8),
                  child: Stack(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    // Igual aos outros cards: fundo claro e
                                    // glifo na cor cheia da categoria.
                                    color: Colors.white.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: c.cor.withValues(alpha: 0.30),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    c.icone,
                                    color: c.cor,
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                    color: corTexto,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _resumo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.15,
                                    color: corTexto.withValues(alpha: 0.80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hora,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontVariations: const <ui.FontVariation>[
                                ui.FontVariation('wght', 700),
                              ],
                              fontSize: corpoHora,
                              height: 1.0,
                              letterSpacing: -1.0,
                              color: corTexto,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

/// Relógio que se atualiza sozinho (HH:MM).
///
/// Um [Timer] de 1 s confere se o minuto mudou e só então redesenha — nada de
/// animar à toa ou gastar bateria.
class Relogio extends StatefulWidget {
  const Relogio({
    required this.tamanho,
    required this.cor,
    this.peso = FontWeight.w700,
    super.key,
  });

  final double tamanho;
  final Color cor;
  final FontWeight peso;

  @override
  State<Relogio> createState() => _RelogioState();
}

class _RelogioState extends State<Relogio> {
  late DateTime _agora = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime novo = DateTime.now();
      if (novo.minute != _agora.minute || novo.hour != _agora.hour) {
        setState(() => _agora = novo);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String hora =
        '${_agora.hour.toString().padLeft(2, '0')}:${_agora.minute.toString().padLeft(2, '0')}';

    return Text(
      hora,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontVariations: const <FontVariation>[FontVariation('wght', 700)],
        fontSize: widget.tamanho,
        fontWeight: widget.peso,
        height: 1.0,
        letterSpacing: -0.2,
        color: widget.cor,
      ),
    );
  }
}

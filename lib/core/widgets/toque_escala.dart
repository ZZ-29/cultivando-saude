import 'package:flutter/material.dart';

/// Dá retorno visual ao toque **sem consumir o gesto**.
///
/// Usa [Listener] (que só observa o ponteiro) e não [GestureDetector] (que
/// disputaria o toque com o `InkWell` de dentro do card). Assim o card pode
/// continuar usando o ripple do Material e, mesmo assim, encolher 3% e
/// escurecer levemente enquanto o dedo está encostado.
///
/// Por que dois efeitos e não só o ripple: ripple é rápido e some com o dedo
/// em cima; o encolhimento fica visível durante todo o toque. Para quem tem
/// menos sensibilidade tátil, isso é a diferença entre "registrou" e "não sei
/// se pegou".
class ToqueEscala extends StatefulWidget {
  const ToqueEscala({required this.child, super.key});

  final Widget child;

  @override
  State<ToqueEscala> createState() => _ToqueEscalaState();
}

class _ToqueEscalaState extends State<ToqueEscala> {
  bool _pressionado = false;

  void _mudar(bool valor) {
    if (_pressionado != valor) {
      setState(() => _pressionado = valor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _mudar(true),
      onPointerUp: (_) => _mudar(false),
      onPointerCancel: (_) => _mudar(false),
      child: AnimatedScale(
        scale: _pressionado ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressionado ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Check-up emocional com o **WHO-5** — instrumento validado pela OMS.
///
/// Cinco perguntas sobre as duas últimas semanas, cada uma de 0 a 5. A soma
/// (0 a 25) é multiplicada por 4 e vira uma nota de 0 a 100. **Não é
/// diagnóstico**: serve para a pessoa perceber tendência e levar o resultado
/// ao profissional.
class CheckupEmocional {
  const CheckupEmocional({
    this.id,
    required this.dia,
    required this.respostas,
  });

  final int? id;
  final DateTime dia;

  /// Cinco respostas de 0 a 5.
  final List<int> respostas;

  /// Nota 0–100 (WHO-5: soma × 4).
  int get nota {
    final int soma = respostas.fold(0, (int a, int b) => a + b);
    return soma * 4;
  }

  /// Leitura simples, sem diagnóstico.
  String get leitura {
    if (nota >= 68) return 'Bem-estar preservado';
    if (nota >= 50) return 'Atenção ao seu ânimo';
    return 'Vale conversar com um profissional';
  }

  bool get completo => respostas.length == CheckupEmocional.perguntas.length;

  Map<String, Object?> paraJson() => <String, Object?>{
        'dia': dia.toIso8601String(),
        'respostas': respostas,
      };

  factory CheckupEmocional.doJson(Map<String, Object?> json) {
    final Object? cru = json['respostas'];
    return CheckupEmocional(
      dia: DateTime.tryParse((json['dia'] as String?) ?? '') ?? DateTime.now(),
      respostas: cru is List
          ? cru.whereType<num>().map((num n) => n.toInt()).toList()
          : const <int>[],
    );
  }

  /// As cinco perguntas do WHO-5, traduzidas para linguagem simples.
  static const List<String> perguntas = <String>[
    'Me senti alegre e de bom humor',
    'Me senti calmo e tranquilo',
    'Me senti ativo e com energia',
    'Acordei me sentindo descansado',
    'Meu dia teve coisas que me interessam',
  ];

  /// Opções de resposta do WHO-5.
  static const List<String> opcoes = <String>[
    'Nenhum momento',
    'Raramente',
    'Menos da metade do tempo',
    'Mais da metade do tempo',
    'Quase sempre',
    'Todo o tempo',
  ];
}

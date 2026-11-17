/// Uma refeição do plano pessoal.
///
/// O app **não prescreve** dieta: ele guarda o que a pessoa (ou o nutricionista
/// dela) escreveu. Cada item é texto livre — "3 ovos mexidos", "carne com
/// gordura", "café com manteiga" — porque só quem segue o plano sabe o que
/// cabe nele.
class Refeicao {
  const Refeicao({
    this.id,
    required this.titulo,
    this.horario = '',
    this.itens = const <String>[],
  });

  final String? id;
  final String titulo;

  /// "07:00" ou vazio.
  final String horario;
  final List<String> itens;

  Refeicao copiarCom({
    String? titulo,
    String? horario,
    List<String>? itens,
  }) =>
      Refeicao(
        id: id,
        titulo: titulo ?? this.titulo,
        horario: horario ?? this.horario,
        itens: itens ?? this.itens,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'id': id,
        'titulo': titulo,
        'horario': horario,
        'itens': itens,
      };

  factory Refeicao.doJson(Map<String, Object?> json) {
    final Object? cru = json['itens'];
    return Refeicao(
      id: json['id'] as String?,
      titulo: (json['titulo'] as String?) ?? '',
      horario: (json['horario'] as String?) ?? '',
      itens: cru is List ? cru.whereType<String>().toList() : <String>[],
    );
  }
}

/// O plano alimentar é uma lista de refeições — sem regra médica embutida.
List<Refeicao> refeicoesDoJson(Object? cru) {
  if (cru is! List) return <Refeicao>[];
  return cru
      .whereType<Map<Object?, Object?>>()
      .map((Map<Object?, Object?> m) =>
          Refeicao.doJson(m.cast<String, Object?>()))
      .toList(growable: true);
}

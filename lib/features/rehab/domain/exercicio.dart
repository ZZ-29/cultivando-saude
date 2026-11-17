/// Um exercício de reabilitação **escrito pela pessoa**, a partir da
/// orientação do fisioterapeuta ou do médico.
///
/// O app não prescreve nada: ele guarda o exercício, o horário combinado e
/// marca o que já foi feito — para não esquecer entre uma sessão e outra.
class Exercicio {
  const Exercicio({
    this.id,
    required this.nome,
    this.orientacao = '',
    this.series = '',
    this.horarios = const <String>[],
  });

  final int? id;
  final String nome;

  /// Como fazer (o que o profissional explicou).
  final String orientacao;

  /// "3 x 10" ou "2 minutos".
  final String series;

  /// Horários combinados: `['08:00', '15:00']`.
  final List<String> horarios;

  bool get temHorario => horarios.isNotEmpty;

  Exercicio copiarCom({
    int? id,
    String? nome,
    String? orientacao,
    String? series,
    List<String>? horarios,
  }) =>
      Exercicio(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        orientacao: orientacao ?? this.orientacao,
        series: series ?? this.series,
        horarios: horarios ?? this.horarios,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'nome': nome,
        'orientacao': orientacao,
        'series': series,
        'horarios': horarios,
      };

  factory Exercicio.doJson(Map<String, Object?> json) {
    final Object? lista = json['horarios'];
    return Exercicio(
      nome: (json['nome'] as String?) ?? '',
      orientacao: (json['orientacao'] as String?) ?? '',
      series: (json['series'] as String?) ?? '',
      horarios: lista is List
          ? lista.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}

/// Chave do dia para marcar exercício feito (sem hora).
String chaveDoDia(DateTime d) => '${d.year}-${d.month}-${d.day}';

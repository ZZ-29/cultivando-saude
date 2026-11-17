/// Um compromisso de saúde: consulta, exame ou outro.
class Compromisso {
  const Compromisso({
    this.id,
    required this.titulo,
    required this.tipo,
    required this.quando,
    this.local = '',
  });

  final int? id;
  final String titulo;
  final TipoCompromisso tipo;
  final DateTime quando;
  final String local;

  bool get passado => quando.isBefore(DateTime.now());

  Compromisso copiarCom({int? id}) => Compromisso(
        id: id ?? this.id,
        titulo: titulo,
        tipo: tipo,
        quando: quando,
        local: local,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'titulo': titulo,
        'tipo': tipo.name,
        'quando': quando.toIso8601String(),
        'local': local,
      };

  factory Compromisso.doJson(Map<String, Object?> json) => Compromisso(
        titulo: (json['titulo'] as String?) ?? '',
        tipo: TipoCompromisso.values.firstWhere(
          (TipoCompromisso t) => t.name == json['tipo'],
          orElse: () => TipoCompromisso.outro,
        ),
        quando: DateTime.tryParse((json['quando'] as String?) ?? '') ??
            DateTime.now(),
        local: (json['local'] as String?) ?? '',
      );
}

enum TipoCompromisso { consulta, exame, outro }

extension TipoCompromissoTexto on TipoCompromisso {
  String get rotulo => switch (this) {
        TipoCompromisso.consulta => 'Consulta',
        TipoCompromisso.exame => 'Exame',
        TipoCompromisso.outro => 'Outro',
      };
}

/// "Hoje 14:30" · "Amanhã 10:00" · "sex, 15/11 · 10:00"
///
/// A ideia é que a pessoa entenda sem pensar: hoje e amanhã têm nome, o resto
/// tem dia da semana e data.
String quandoResumido(DateTime d, {DateTime? referencia}) {
  final DateTime agora = referencia ?? DateTime.now();
  final DateTime hoje = DateTime(agora.year, agora.month, agora.day);
  final DateTime dia = DateTime(d.year, d.month, d.day);
  final String hora =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  final int diferenca = dia.difference(hoje).inDays;
  if (diferenca == 0) return 'Hoje $hora';
  if (diferenca == 1) return 'Amanhã $hora';

  const List<String> dias = <String>[
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];
  final String data =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  return '${dias[d.weekday - 1]}, $data · $hora';
}

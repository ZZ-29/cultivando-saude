/// Um compromisso de saúde: consulta, exame ou outro.
///
/// Guarda também o **endereço** — e não só o nome do lugar. As clínicas mandam
/// o endereço pelo WhatsApp; sem ele aqui, a pessoa precisa abrir o aplicativo
/// de mensagens na hora de sair. Com o endereço na agenda, o dado está onde a
/// hora já está.
class Compromisso {
  const Compromisso({
    this.id,
    required this.titulo,
    required this.tipo,
    required this.quando,
    this.local = '',
    this.endereco = '',
  });

  final int? id;
  final String titulo;
  final TipoCompromisso tipo;
  final DateTime quando;

  /// Nome do lugar: "Clínica Vida", "Lab Central".
  final String local;

  /// Endereço completo, como veio do WhatsApp: rua, número, bairro, cidade.
  final String endereco;

  bool get passado => quando.isBefore(DateTime.now());
  bool get temEndereco => endereco.trim().isNotEmpty;

  Compromisso copiarCom({int? id}) => Compromisso(
        id: id ?? this.id,
        titulo: titulo,
        tipo: tipo,
        quando: quando,
        local: local,
        endereco: endereco,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'titulo': titulo,
        'tipo': tipo.name,
        'quando': quando.toIso8601String(),
        'local': local,
        'endereco': endereco,
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
        endereco: (json['endereco'] as String?) ?? '',
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

/// Dados de quem usa o app.
///
/// Guardamos a **data de nascimento**, não a idade: idade digitada envelhece
/// errado. A idade é calculada toda vez que alguém pergunta.
class Perfil {
  const Perfil({
    this.nome = '',
    this.nascimento,
    this.tipoSanguineo,
    this.peso,
  });

  final String nome;
  final DateTime? nascimento;
  final String? tipoSanguineo;

  /// Peso em kg — usado para estimar calorias no card de Esportes.
  /// Opcional: sem ele, o app simplesmente não mostra calorias.
  final double? peso;

  bool get preenchido => nome.trim().isNotEmpty;

  /// Idade em anos completos, ou `null` se a data não foi informada.
  int? get idade {
    final DateTime? n = nascimento;
    if (n == null) return null;
    final DateTime hoje = DateTime.now();
    int anos = hoje.year - n.year;
    final bool aindaNaoFezAniversario =
        hoje.month < n.month || (hoje.month == n.month && hoje.day < n.day);
    if (aindaNaoFezAniversario) anos--;
    return anos < 0 ? null : anos;
  }

  Perfil copiarCom({
    String? nome,
    DateTime? nascimento,
    String? tipoSanguineo,
    double? peso,
  }) {
    return Perfil(
      nome: nome ?? this.nome,
      nascimento: nascimento ?? this.nascimento,
      tipoSanguineo: tipoSanguineo ?? this.tipoSanguineo,
      peso: peso ?? this.peso,
    );
  }

  Map<String, Object?> paraJson() => <String, Object?>{
        'nome': nome,
        'nascimento': nascimento?.toIso8601String(),
        'tipo_sanguineo': tipoSanguineo,
        'peso': peso,
      };

  factory Perfil.doJson(Map<String, Object?> json) {
    final Object? cru = json['nascimento'];
    return Perfil(
      nome: (json['nome'] as String?) ?? '',
      nascimento: cru is String ? DateTime.tryParse(cru) : null,
      tipoSanguineo: json['tipo_sanguineo'] as String?,
      peso: (json['peso'] as num?)?.toDouble(),
    );
  }
}

/// Tipos sanguíneos aceitos. Lista fechada de propósito: texto livre gera
/// "O positivo", "o+", "O Pos" e o dado fica inútil em emergência.
const List<String> kTiposSanguineos = <String>[
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

/// Opção extra para quem não sabe.
const String kSangueNaoSei = 'não sei';

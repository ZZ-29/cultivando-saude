/// Um resultado de exame guardado pela pessoa.
///
/// Guarda **quem pediu** (médico), o **local/laboratório** e a **foto do
/// resultado** — é o que a pessoa precisa quando leva o exame a outro
/// profissional.
///
/// Duas categorias, porque a rotina é diferente e o app separa em dois cards:
///   • **laboratorial** — sangue, urina, fezes (resultado em papel ou PDF);
///   • **especialidade** — raio-X, ultrassom, tomografia, endoscopia…
class Exame {
  const Exame({
    this.id,
    required this.nome,
    required this.quando,
    this.local = '',
    this.medico = '',
    this.foto,
    this.categoria = CategoriaExame.laboratorial,
  });

  final int? id;
  final String nome;
  final DateTime quando;
  final String local;
  final String medico;

  /// Caminho da foto do resultado (null = sem foto).
  final String? foto;

  final CategoriaExame categoria;

  bool get temFoto => (foto ?? '').trim().isNotEmpty;
  bool get temMedico => medico.trim().isNotEmpty;

  Exame copiarCom({int? id, CategoriaExame? categoria}) => Exame(
        id: id ?? this.id,
        nome: nome,
        quando: quando,
        local: local,
        medico: medico,
        foto: foto,
        categoria: categoria ?? this.categoria,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'nome': nome,
        'quando': quando.toIso8601String(),
        'local': local,
        'medico': medico,
        'foto': foto,
        'categoria': categoria.name,
      };

  factory Exame.doJson(Map<String, Object?> json) => Exame(
        nome: (json['nome'] as String?) ?? '',
        quando: DateTime.tryParse((json['quando'] as String?) ?? '') ??
            DateTime.now(),
        local: (json['local'] as String?) ?? '',
        medico: (json['medico'] as String?) ?? '',
        foto: json['foto'] as String?,
        categoria: CategoriaExame.values.firstWhere(
          (CategoriaExame c) => c.name == json['categoria'],
          orElse: () => CategoriaExame.laboratorial,
        ),
      );
}

/// As duas famílias de exame — cada uma com seu card.
enum CategoriaExame { laboratorial, especialidade }

extension CategoriaExameInfo on CategoriaExame {
  String get titulo => switch (this) {
        CategoriaExame.laboratorial => 'Resultados de laboratório',
        CategoriaExame.especialidade => 'Exames de especialidades',
      };

  String get curto => switch (this) {
        CategoriaExame.laboratorial => 'Laboratório',
        CategoriaExame.especialidade => 'Especialidades',
      };

  String get dica => switch (this) {
        CategoriaExame.laboratorial =>
          'Sangue, urina e fezes — com a foto do resultado.',
        CategoriaExame.especialidade =>
          'Raio-X, ultrassom, tomografia — com a foto do laudo.',
      };

  String get exemplo => switch (this) {
        CategoriaExame.laboratorial => 'Ex.: Hemograma',
        CategoriaExame.especialidade => 'Ex.: Raio-X do tórax',
      };

  String get localRotulo => switch (this) {
        CategoriaExame.laboratorial => 'Laboratório (opcional)',
        CategoriaExame.especialidade => 'Clínica (opcional)',
      };
}

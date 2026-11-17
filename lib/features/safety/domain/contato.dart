/// Contato de emergência da família.
///
/// Telefone é guardado só com dígitos (o que o discador usa) e formatado na
/// hora de mostrar. Assim "21 99999-8888", "(21) 99999 8888" e "21999998888"
/// viram o mesmo contato, e nada quebra ao copiar de outro lugar.
class Contato {
  const Contato({
    this.id,
    required this.nome,
    required this.telefone,
    this.parentesco = '',
  });

  final int? id;
  final String nome;

  /// Só dígitos (pode começar com 55 do Brasil).
  final String telefone;
  final String parentesco;

  Contato copiarCom({int? id}) => Contato(
        id: id ?? this.id,
        nome: nome,
        telefone: telefone,
        parentesco: parentesco,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'nome': nome,
        'telefone': telefone,
        'parentesco': parentesco,
      };

  factory Contato.doJson(Map<String, Object?> json) => Contato(
        nome: (json['nome'] as String?) ?? '',
        telefone: (json['telefone'] as String?) ?? '',
        parentesco: (json['parentesco'] as String?) ?? '',
      );
}

/// Deixa só os dígitos.
String soDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Formata para leitura: (21) 99999-8888 · 0800 123 4567 · +55 21 99999-8888
String telefoneFormatado(String digitos) {
  final String d = soDigitos(digitos);
  if (d.isEmpty) return '';

  // Com DDI 55
  if (d.length > 11 && d.startsWith('55')) {
    final String resto = d.substring(2);
    return '+55 ${telefoneFormatado(resto)}';
  }
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  if (d.length == 8 || d.length == 9) {
    final int corte = d.length - 4;
    return '${d.substring(0, corte)}-${d.substring(corte)}';
  }
  return d;
}

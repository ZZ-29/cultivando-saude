import '../domain/medicao.dart';

/// Texto das medidas para mandar ao médico pelo WhatsApp.
///
/// Formato pensado para ser lido no celular do consultório: data, período do
/// dia, valor e pulso — uma linha por medida, sem enfeite. A média vai no fim,
/// porque é o número que o cardiologista procura primeiro.
String textoPressaoParaWhatsapp(
  List<Medicao> medidas, {
  String? nome,
  DateTime? referencia,
}) {
  final DateTime agora = referencia ?? DateTime.now();
  final List<Medicao> validas = medidas
      .where((Medicao m) => !m.quando.isAfter(agora))
      .toList()
    ..sort((Medicao a, Medicao b) => a.quando.compareTo(b.quando));

  final StringBuffer texto = StringBuffer();
  texto.writeln('Medidas de pressão${nome == null ? '' : ' — $nome'}');
  texto.writeln('');

  for (final Medicao m in validas) {
    texto.writeln(
      '${_data(m.quando)} ${_periodo(m.quando.hour)}: '
      '${m.sistolica}/${m.diastolica}${m.pulso == null ? '' : ' · pulso ${m.pulso}'}',
    );
  }

  if (validas.isNotEmpty) {
    final int n = validas.length;
    final int mediaSis =
        (validas.fold<int>(0, (int a, Medicao m) => a + m.sistolica) / n).round();
    final int mediaDia =
        (validas.fold<int>(0, (int a, Medicao m) => a + m.diastolica) / n).round();
    texto.writeln('');
    texto.writeln('Média das $n medidas: $mediaSis/$mediaDia');
  }

  texto.write('Enviado pelo app Cultivando Saúde.');
  return texto.toString();
}

String _data(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Manhã / Tarde / Noite — como a médica pediu, não o horário seco.
String _periodo(int hora) {
  if (hora < 12) return 'manhã';
  if (hora < 18) return 'tarde';
  return 'noite';
}

import 'package:url_launcher/url_launcher.dart';

import 'features/pressure/data/compartilhar.dart';

/// Envio pelo WhatsApp no **Android**.
///
/// Usa o esquema `wa.me`, que abre o WhatsApp com a mensagem pronta e deixa a
/// pessoa escolher o contato (médico, filho, grupo). Não exige login nem API:
/// é o mesmo link que se usa no navegador.
class CompartilharWhatsappAndroid implements CompartilharWhatssapp {
  @override
  bool get disponivel => true;

  @override
  Future<bool> enviar(String texto) async {
    final Uri url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(texto)}',
    );
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

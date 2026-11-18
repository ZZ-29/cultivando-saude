import 'package:flutter/services.dart';

import 'features/pressure/data/compartilhar.dart';

/// Versão **sem plugin** usada na web (preview): copia o texto, porque abrir
/// `wa.me` no navegador de teste não serve para nada.
class CompartilharWhatsappAndroid implements CompartilharWhatssapp {
  @override
  bool get disponivel => false;

  @override
  Future<bool> enviar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    return false;
  }
}

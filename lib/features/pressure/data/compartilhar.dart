import 'package:flutter/services.dart';

/// Envio de texto para o WhatsApp.
///
/// A interface fica em Dart puro. No Android ela abre o WhatsApp com a
/// mensagem já escrita (a pessoa só escolhe para quem mandar); na prévia, cai
/// na área de transferência, para o texto não se perder.
abstract class CompartilharWhatssapp {
  bool get disponivel;

  /// Abre o WhatsApp com [texto] pronto. Devolve `false` se não conseguiu.
  Future<bool> enviar(String texto);
}

class CompartilharIndisponivel implements CompartilharWhatssapp {
  @override
  bool get disponivel => false;

  @override
  Future<bool> enviar(String texto) async {
    // Sem WhatsApp (prévia/desktop): copia, para a pessoa colar onde quiser.
    await Clipboard.setData(ClipboardData(text: texto));
    return false;
  }
}

/// Implementação ativa nesta execução.
CompartilharWhatssapp compartilharWhatsapp = CompartilharIndisponivel();

/// Troca a implementação (chamado uma vez, na inicialização do app).
void usarCompartilharWhatsapp(CompartilharWhatssapp nova) =>
    compartilharWhatsapp = nova;

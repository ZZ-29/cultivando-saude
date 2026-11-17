/// Captura da foto da prescrição.
///
/// A câmera/galeria depende de plugin (`image_picker`), que só existe no app
/// Android. Nas outras plataformas a interface fica indisponível e a tela
/// avisa — em vez de mostrar um botão que não faz nada.
abstract class CapturaPrescricao {
  bool get disponivel;

  /// Devolve o caminho do arquivo, ou `null` se a pessoa cancelou.
  Future<String?> capturar();
}

class CapturaIndisponivel implements CapturaPrescricao {
  @override
  bool get disponivel => false;

  @override
  Future<String?> capturar() async => null;
}

/// Implementação ativa nesta execução.
CapturaPrescricao capturaPrescricao = CapturaIndisponivel();

/// Troca a implementação (chamado uma vez, na inicialização do app).
void usarCapturaPrescricao(CapturaPrescricao nova) => capturaPrescricao = nova;

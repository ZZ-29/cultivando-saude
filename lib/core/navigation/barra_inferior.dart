import 'package:flutter/foundation.dart';

/// Altura real da barra inferior (privacidade + abas), medida em tempo de
/// execução.
///
/// **Por que não um número fixo:** a barra cresce quando o texto de
/// privacidade quebra em duas ou três linhas (telas estreitas). Com um valor
/// fixo menor que a barra, o fim das listas ficava escondido atrás dela — e o
/// último card parecia "preso" na tela, porque nunca passava daquele ponto.
///
/// O app mede a barra depois do primeiro layout e todas as telas com rolagem
/// usam essa medida como respiro inferior.
final ValueNotifier<double> alturaBarraInferior = ValueNotifier<double>(112);

/// Respiro inferior para as listas.
///
/// Com `extendBody: false` a barra não fica mais sobre o conteúdo, então basta
/// um respiro curto — o fim da lista termina acima dela. O valor medido da
/// barra continua disponível para quem precisar (ex.: rolagem programática).
double get respiroInferior => 24;

/// Atualiza a medida (chamado pela casca do app).
void medirBarraInferior(double altura) {
  if ((altura - alturaBarraInferior.value).abs() < 0.5) return;
  alturaBarraInferior.value = altura;
}

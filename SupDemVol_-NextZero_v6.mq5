//+------------------------------------------------------------------+
//|                                    VolumeProfile_HighVolumeOnly.mq5 |
//|                       Volume Profile - 7 Zonas Dinâmicas        |
//+------------------------------------------------------------------+
#property copyright "Volume Profile - 7 Zonas Dinâmicas"
#property version   "14.04"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3

// Plot do histograma de volume
#property indicator_label1  "Volume"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  C'46,123,214', C'46,123,214', C'188,36,52'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

// Plot da banda superior
#property indicator_label2  "Banda Superior"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'46,123,214'
#property indicator_style2  STYLE_DASH
#property indicator_width2  2

// Plot da linha zero
#property indicator_label3  "Zero"
#property indicator_type3   DRAW_LINE
#property indicator_color3  C'46,123,214'
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//+------------------------------------------------------------------+
//| Enumeração para tipo de linha                                   |
//+------------------------------------------------------------------+
enum ENUM_LINE_TYPE
{
    LINE_TOP,      // Linha de topo/resistência
    LINE_BOTTOM    // Linha de fundo/suporte
};

//+------------------------------------------------------------------+
//| Enumeração para estado do pivô                                  |
//+------------------------------------------------------------------+
enum ENUM_PIVO_STATE
{
    PIVO_ATIVO,           // Pivô ativo 
    PIVO_ROMPIDO,         // Pivô rompido (aguardando confirmação)
    PIVO_CONFIRMADO,      // Pivô confirmado após tempo de assentamento
    PIVO_REMOVIDO         // Pivô removido
};

//+------------------------------------------------------------------+
//| Enumeração para intensidade do volume                           |
//+------------------------------------------------------------------+
enum ENUM_VOLUME_INTENSIDADE
{
    VOLUME_BAIXO,         // Volume baixo
    VOLUME_MEDIO,         // Volume médio  
    VOLUME_ALTO,          // Volume alto
    VOLUME_EXTREMO        // Volume extremo
};

enum ENUM_PALETA_PREMIUM {
   PALETA_PREMIUM_ATRATO = 0, // Premium 1: acinzentado + terroso
   PALETA_PREMIUM_SOMBRA = 1, // Premium 2: azul frio + grafite
   PALETA_PREMIUM_COBRE  = 2  // Premium 3: cobre escuro + azul petróleo
};

enum ENUM_POSICAO_HORIZONTAL_TEXTO_ZONA {
   TEXTO_ZONA_ESQUERDA = 0,
   TEXTO_ZONA_CENTRO   = 1,
   TEXTO_ZONA_DIREITA  = 2
};

enum ENUM_POSICAO_PAINEL_LOG {
   PAINEL_LOG_SUP_ESQ = 0,
   PAINEL_LOG_SUP_DIR = 1,
   PAINEL_LOG_INF_ESQ = 2,
   PAINEL_LOG_INF_DIR = 3
};

enum ENUM_MODO_CONFLITO_SINAL_ENRIQ {
   CONFLITO_SINAL_HIBRIDO = 0,   // mantém o volume na zona tocada, mesmo com sinal oposto
   CONFLITO_SINAL_SUBTRAIR = 1,  // em sinal oposto, retira volume da zona ao invés de somar
   CONFLITO_SINAL_MIX_SOMBRA = 2 // divide volume em BUY/SELL pela proporção das sombras da barra
};

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
// Parâmetros do Volume
input int      InpPeriodoMedia = 20;                // Período para Média do Volume
input double   InpMultiplicadorDesvio = 3.5;        // Multiplicador do Desvio Padrão
input ENUM_PALETA_PREMIUM InpPaletaVisual = PALETA_PREMIUM_ATRATO;
input bool     InpUsarPaletaPremium = true;         // Ignora cor manual e usa tema premium selecionado
input color    InpCorPaletaElegante = C'46,123,214'; // Cor elegante principal da v4
input color    InpCorPaletaVermelha = C'188,36,52';  // Cor vermelha principal da v4

// Parâmetros dos Pivôs
input string   InpSeparador1 = "═══ PIVÔS DINÂMICOS ═══";           // ═══════════════════════
input bool     InpMostrarProfile = true;            // Mostrar os Pivôs
input int      InpNumeroPivos = 7;                  // Número de Pivôs (máximo 20)
input double   InpMaxATRPercent = 35.0;             // Máximo % do ATR para ALTURA do pivô
input string   InpSeparadorMerge = "═══ REGRAS DE MERGE SEGURAS ═══";
input double   InpMergeATRPercent = 80.0;           // % do ATR para MERGE automático de pivôs próximos
input double   InpDistanciaMinATR = 50.0;           // Distância mínima entre pivôs (% do ATR)  
input double   InpFatorDistanciaMinCriacao = 1.60;  // Multiplica a distância mínima para criar nova zona
input double   InpFatorGapPorSomaMerge = 1.00;      // Limite de merge por intervalo entre zonas (1.00 = soma das alturas)
input double   InpFatorAlturaBarraOrigem = 0.35;    // Fração da barra de origem para altura da zona (0.05..1.00)
input double   InpFatorAbsorcaoMerge = 0.30;       // Fração da zona absorvida que é engolida (0.00..1.00)
input double   InpPesoDistanciaPrecoNoSlot = 0.35;  // Peso para proteger zonas perto do preço no merge sem slot
input int      InpZigZagDepth = 12;                 // ZigZag importado: Depth
input int      InpZigZagDeviation = 5;              // ZigZag importado: Deviation
input int      InpZigZagBackstep = 3;               // ZigZag importado: Backstep
input int      InpZigZagMaxBarras = 500;            // Máximo de barras para média de distância zig-zag
input double   InpDistMinFatorZigZag = 1.0;         // Fator da distância média zig-zag (1.0 = média pura)
input int      InpTempoAssentamento = 20;           // Barras para considerar 'assentado' (anti pisca-pisca)
input int      InpDiasAnalise = 1;                  // Dias para análise (sempre do dia atual)

// Parâmetros de Validação  
input string   InpSeparador2 = "═══ ROMPIMENTO E ESTABILIZAÇÃO ═══"; // ═══════════════════════
input int      InpBarrasConfirmacao = 2;            // Barras de Confirmação do Rompimento
input double   InpToleranciaRompimento = 0.2;       // Tolerância de Rompimento (% do preço)

// Parâmetros Visuais - PROGRESS BAR DE VOLUME
input string   InpSeparador3 = "═══ VISUAL PROGRESS BAR ═══";        // ═══════════════════════
input color    InpCorVolumeBaixo = C'46,123,214';    // Cor para Volume Baixo
input color    InpCorVolumeMedio = C'46,123,214';    // Cor para Volume Medio
input color    InpCorVolumeAlto = C'188,36,52';      // Cor para Volume Alto
input color    InpCorVolumeExtremo = C'188,36,52';   // Cor para Volume Extremo
input color    InpCorZonaSuporte = C'46,123,214';    // Cor elegante da zona
input color    InpCorZonaResistencia = C'188,36,52'; // Cor vermelha da zona
input color    InpCorRompido = C'188,36,52';         // Cor vermelha para rompido
input color    InpCorProgressBar = C'46,123,214';    // Cor elegante da progress bar
input int      InpLarguraLinhas = 2;                // Largura das Linhas
input int      InpTransparenciaZonas = 120;         // Transparência das Zonas (0-255)
input int      InpTransparenciaProgress = 220;      // Transparência da Progress Bar (0-255)
input bool     InpMostrarVolumeTexto = true;        // Mostrar percentual simples nas zonas
input bool     InpExibirValoresZona = true;         // Chave mestre para exibir valores nas zonas
input ENUM_POSICAO_HORIZONTAL_TEXTO_ZONA InpPosicaoHorizontalTextoZona = TEXTO_ZONA_DIREITA; // Posição horizontal dos valores
input double   InpPosicaoVerticalTextoZona = 0.50;  // 0.00=base da zona, 1.00=topo da zona
input int      InpDeslocamentoTextoBarras = 0;      // Deslocamento horizontal do texto (em barras)
input bool     InpMostrarProgressBar = false;       // (Desativado) Progress Bar de Volume
input bool     InpExibirFaixaVolumeDireita = false; // Exibe a faixa de progresso no recuo direito
input bool     InpDesenharZonaAteRecuo = true;      // Estende a zona ate o recuo direito (sem progress bar)
input bool     InpExibirPainelVolume = true;        // Exibir painel de volume (histograma/banda/zero) ao carregar
input bool     InpAtualizarUIApenasBarraNova = true; // Reduz pisca-pisca: atualiza UI só em barra nova/mudança
input bool     InpLogDetalhado = true;              // Log detalhado (pode deixar lento/ruidoso)
input bool     InpExibirLogEnriquecimentoNoGrafico = true; // Mostra no chart os ultimos enriquecimentos
input int      InpLinhasLogEnriquecimento = 6;      // Linhas do log de enriquecimento em tela (5..12)
input ENUM_POSICAO_PAINEL_LOG InpPosicaoPainelLogEnriquecimento = PAINEL_LOG_SUP_ESQ; // Canto do painel de log
input int      InpPainelLogOffsetX = 12;            // Offset horizontal do painel (px)
input int      InpPainelLogOffsetY = 40;            // Offset vertical do painel (px)
input int      InpPainelLogFonteTamanho = 9;        // Tamanho da fonte do painel de log
input color    InpPainelLogCorTexto = clrWhite;     // Cor do texto do painel de log
input bool     InpExibirPainelBalanceCV = true;     // Mostra debug geral de compras/vendas (azul/vermelho)
input int      InpPainelBalanceOffsetX = 12;        // Offset horizontal do painel de balance CV (px)
input int      InpPainelBalanceOffsetY = 14;        // Offset vertical do painel de balance CV (px)
input int      InpPainelBalanceFonteTamanho = 16;   // Fonte do painel de balance CV
input string   InpSeparadorLinhaMax = "═══ LINHA MAIOR MÁXIMA ═══";
input bool     InpMostrarLinhaMaiorMaxima = true;   // Exibe linha da maior máxima dos últimos X períodos
input int      InpPeriodoLinhaMaiorMaxima = 14;     // Quantidade de períodos para maior máxima
input color    InpCorLinhaMaiorMaxima = C'188,36,52'; // Cor da linha da maior maxima
input ENUM_LINE_STYLE InpEstiloLinhaMaiorMaxima = STYLE_DASHDOT; // Estilo da linha
input int      InpLarguraLinhaMaiorMaxima = 1;      // Largura da linha
input bool     InpMaximaReal = true;                // Sim: ancora máxima/mínima até violação
input string   InpSeparadorLinhaMin = "═══ LINHA MENOR MÍNIMA ═══";
input bool     InpMostrarLinhaMenorMinima = true;   // Exibe linha da menor mínima dos últimos X períodos
input int      InpPeriodoLinhaMenorMinima = 14;     // Quantidade de períodos para menor mínima
input color    InpCorLinhaMenorMinima = C'46,123,214'; // Cor da linha da menor minima
input ENUM_LINE_STYLE InpEstiloLinhaMenorMinima = STYLE_DOT; // Estilo da linha
input int      InpLarguraLinhaMenorMinima = 1;      // Largura da linha
input string   InpSeparadorOrganizacaoDiaria = "═══ ORGANIZACAO CONTINUA (PRIORIDADE) ═══";
input bool     InpOrganizacaoEmBarraFechada = true; // Organiza em toda barra fechada
input int      InpOrganizacaoGatilhoZonas = 7;      // A partir deste número, organizador entra agressivo
input int      InpOrganizacaoLimiteDuroZonas = 10;  // Nunca manter acima deste número após ciclo
input int      InpOrganizacaoAlvoNormal = 7;        // Alvo quando há merges elegíveis
input int      InpOrganizacaoAlvoSemGap = 6;        // Alvo quando não há gap elegível para merge
input double   InpOrganizacaoFatorGapMaiorZona = 2.0; // Gap elegível: dist < fator * maior_altura
input int      InpOrganizacaoMaxAcoesPorBarra = 20; // Segurança de iterações por barra
input double   InpShvedFractalFastFactor = 3.0;     // Inspiração Shved: fator fractal rápido
input double   InpShvedFractalSlowFactor = 6.0;     // Inspiração Shved: fator fractal lento
input int      InpShvedLookbackBarras = 1000;       // Barras para buscar âncora fractal
input string   InpSeparadorAvancado = "═══ AJUSTES AVANÇADOS EXPOSTOS ═══";
input bool     InpHabilitarCompactacaoOverflow = false; // Legado (não utilizado no fluxo principal)
input int      InpFaixaExtraZonas = 2;              // Banda dinâmica ao redor do alvo (N-Extra..N+Extra)
input int      InpBarrasProtecaoZonaRecemCriada = 1; // Proteção contra absorção imediata
input bool     InpHabilitarMergeMesmaBarra = true;  // Permite merge quando uma barra toca mais de uma zona
input bool     InpEnriquecimentoToqueSomenteAcimaBanda = false; // ON: toque só enriquece se volume > banda; OFF: qualquer toque enriquece
input ENUM_MODO_CONFLITO_SINAL_ENRIQ InpModoConflitoSinalEnriquecimento = CONFLITO_SINAL_MIX_SOMBRA; // HIBRIDO: soma; SUBTRAIR: reduz; MIX_SOMBRA: divide buy/sell por sombras
input bool     InpPermitirRemoverZonasNoMerge = true; // Legado (não utilizado no fluxo principal)
input int      InpMargemCompactacaoSuave = 1;       // Compacta so quando ativos > alvo + margem
input bool     InpHabilitarTravaAncora = true;      // Reaplica âncora a cada ciclo
input int      InpAlturaMinimaZonaPontos = 2;       // Espessura mínima da zona em pontos
input int      InpExtensaoTemporalZona = 50;        // Extensão horizontal da zona ao desenhar
input int      InpExtensaoTemporalCoordenada = 100; // Extensão usada na atualização das coordenadas
input double   InpMargemVerticalProgress = 0.10;    // Margem vertical da progress bar (0.0..0.45)
input double   InpFallbackAlturaProgressATR = 0.10; // Fator ATR quando altura da zona for inválida
input int      InpFallbackAlturaProgressPontos = 10; // Mínimo em pontos no fallback da progress bar
input int      InpPeriodoATR = 14;                  // Período do ATR interno
input int      InpVizinhancaPivotBarras = 2;        // Barras de vizinhança para detectar topo/fundo
input double   InpVolumeRatioMedio = 1.5;           // Limiar para VOLUME_MEDIO
input double   InpVolumeRatioAlto = 2.0;            // Limiar para VOLUME_ALTO
input double   InpVolumeRatioExtremo = 3.0;         // Limiar para VOLUME_EXTREMO
input int      InpDiasReferenciaOrigem = 2;         // Dias para normalizar score da origem (1..2)
input int      InpDiasMaximoZonaAtiva = 0;          // Legado (hibernação desativada no fluxo principal)
input bool     InpAtivarFiltroFaixaPreco = false;   // Legado (filtro desativado no fluxo principal)
input int      InpFiltroFaixaPrecoDias = 2;         // Dias usados para calcular a faixa (max-min)
input double   InpFatorFiltroFaixaPreco = 1.00;     // 1.00 => metade da faixa para cada lado do preco
input double   InpPesoOrigemVolume = 0.70;          // Peso do volume na espessura da zona de origem
input double   InpPesoOrigemSombra = 0.25;          // Peso da sombra dominante na espessura
input double   InpPesoOrigemCorpo = 0.05;           // Peso do corpo do candle na espessura
input double   InpToleranciaDominioSombra = 0.05;   // Tolerancia para definir sombra dominante
input bool     InpDistribuicaoSomentePico = true;   // Distribuição usa só barras acima da banda
input bool     InpConservacaoVolumeAltoEstrita = true; // Força soma das zonas = soma dos volumes acima da banda (janela)
input bool     InpAplicarRateioRetroativoNasZonas = false; // ON: reescreve volume da zona com rateio da janela; OFF: soma apenas volume incremental do evento
input bool     InpRatearVolumeSemIntersecao = true; // Sem interseção, envia 100% para zona mais próxima
input bool     InpPercentualNominalSimples = true;  // Percentual simples por volume nominal (sem pesos diários)
input bool     InpEscalaRelativaSemATR = true;      // Distâncias/alturas usam faixa diária em vez de ATR
input double   InpEscalaRelativaFatorFaixaDia = 0.10; // Fator aplicado à faixa diária para a escala relativa
input double   InpEscalaRelativaMinPctPreco = 0.05; // Piso da escala relativa em % do preço
input int      InpJanelaInicioDiaBarras = 2;        // Prioridade do dia anterior nas primeiras barras
input double   InpPesoMaxVolDiaAnterior = 1.20;     // Peso do máximo volume do dia anterior no início do dia
input double   InpPesoMaxVolDiaAtual = 1.08;        // Peso do máximo volume do dia atual
input double   InpPesoExtremosDia = 1.06;           // Peso para zonas próximas das máximas/mínimas diária
input double   InpRedutorZonaVencida = 0.92;        // Reduz peso quando zona já foi vencida
input double   InpPesoScoreProximidade = 0.35;      // Peso no score de compactacao (overflow)
input double   InpPesoScoreDistanciaPreco = 0.25;   // Peso no score de compactacao (overflow)
input double   InpPesoScoreBaixoVolume = 0.25;      // Peso no score de compactacao (overflow)
input double   InpPesoScoreAntiguidade = 0.15;      // Peso no score de compactacao (overflow)
input int      InpBarrasExtrasHistorico = 10;       // Barras extras mínimas além da média para liberar cálculo
input double   InpFatorAlturaMinBarraOrigem = 0.05; // Clamp mínimo do fator de altura da barra de origem
input double   InpFatorAlturaMaxBarraOrigem = 1.00; // Clamp máximo do fator de altura da barra de origem
input int      InpFaixaEstreitaBucketPontos = 10;   // Faixa em pontos para bucket central no overflow
input int      InpMinBarrasZigZagMedia = 20;        // Mínimo de barras para média de distância ZigZag
input double   InpToleranciaDuplicidadePivotPontos = 0.5; // Tolerância em pontos para ignorar pivô ZigZag duplicado
input double   InpAtrFallbackEmErro = 0.01;         // ATR fallback quando houver erro/índice inválido
input int      InpTamanhoFonteTextoZona = 8;        // Fonte do texto exibido nas zonas

// Buffers
double VolumeBuffer[];
double VolumeColorBuffer[];
double BandaSuperiorBuffer[];
double ZeroBuffer[];
double MediaBuffer[];

// Variáveis globais
string g_prefixo = "VProfile7_v5_";
string g_prefixoHibernacao = "VProfile7HIB_v5_";
int g_contadorHibernacao = 1;
long g_chartID;
bool g_profileDesenhado = false;
datetime g_ultimaAtualizacao = 0;
datetime g_ultimoDiaAnalise = 0;
int g_numeroZonas = 7;  // Será inicializado com InpNumeroPivos validado
int g_numeroZonasAlvo = 7;
int g_numeroZonasMin = 5;
int g_numeroZonasMax = 9;
double g_volumeMaximoGlobal = 0.0;
string g_ultimoCommentInfo = "";
string g_logEnriquecimento[12];
int g_logEnriquecimentoCount = 0;
datetime g_tempoUltimaCriacaoBarra = 0;
datetime g_tempoBarraCriacaoRealtime = 0;
double g_volumeCriacaoAplicadoBarra = 0.0;
int g_idxZonaDestinoCriacaoRealtime = -1;
datetime g_tempoEventoVolumeConsumidoCriacao = 0;
int g_zigzagHandle = INVALID_HANDLE;
bool g_prevChartForeground = false;
bool g_prevChartForegroundValid = false;
datetime g_tempoEventoMerge = 0;
bool g_mergeExecutadoNoEvento = false;
bool g_maximaRealInicializada = false;
bool g_minimaRealInicializada = false;
double g_precoMaximaReal = 0.0;
double g_precoMinimaReal = 0.0;
datetime g_ultimoDiaOrganizado = 0;
double g_extremoMaxDiaAtual = 0.0;
double g_extremoMinDiaAtual = 0.0;
double g_extremoMaxDiaAnterior = 0.0;
double g_extremoMinDiaAnterior = 0.0;
datetime g_referenciaDiaAtual = 0;
datetime g_referenciaDiaAnterior = 0;

bool PodeProcessarMergeDoEvento(const datetime tempoEvento) {
   if(g_tempoEventoMerge != tempoEvento) {
      g_tempoEventoMerge = tempoEvento;
      g_mergeExecutadoNoEvento = false;
   }
   return !g_mergeExecutadoNoEvento;
}

void MarcarMergeProcessadoNoEvento(const datetime tempoEvento) {
   g_tempoEventoMerge = tempoEvento;
   g_mergeExecutadoNoEvento = true;
}

void SDV4_ModuloCentralProcessar(const int rates_total,
                                 const int prev_calculated,
                                 const datetime &time[],
                                 const double &open[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 const long &tick_volume[]);
void RegistrarEventoEnriquecimentoNoGrafico(const string origem,
                                            const datetime tempoBarra,
                                            const int idxZona,
                                            const double volumeAplicado);
void RegistrarMensagemPainelLogEnriquecimentoNoGrafico(const string mensagem);
void RegistrarAuditoriaEnriquecimentoBarraNoGrafico(const datetime tempoBarra,
                                                    const double volumeEvento,
                                                    const double volumeAplicado,
                                                    const double volumeResidual,
                                                    const int zonasTocadas,
                                                    const int zonasElegiveis,
                                                    const double volumeZonasAntes,
                                                    const double volumeZonasDepois);
void RegistrarDebugAlocacaoBarraNoGrafico(const string origem,
                                          const datetime tempoBarra,
                                          const int idxZonaBuy,
                                          const double volumeBuy,
                                          const int idxZonaSell,
                                          const double volumeSell);
string ObterTextoLogEnriquecimentoNoGrafico();
int ObterCornerPainelLogEnriquecimento();
int ObterPainelLogOffsetX();
int ObterPainelLogOffsetY();
int ObterPainelLogFonteTamanho();
color ObterPainelLogCorTexto();
bool DeveExibirPainelBalanceCVNoGrafico();
int ObterPainelBalanceOffsetX();
int ObterPainelBalanceOffsetY();
int ObterPainelBalanceFonteTamanho();
bool FiltrarZonasForaJanelaPreco(const int rates_total,
                                 const datetime &time[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[]);
double CalcularScoreOrigemZona(const int idxBarra,
                               const datetime &time[],
                               const double &open[],
                               const double &high[],
                               const double &low[],
                               const double &close[]);
int ConverterScoreEmEspessura(const double scoreOrigem);
ENUM_LINE_TYPE DeterminarTipoLinhaPorSombra(const int barra,
                                            const double &open[],
                                            const double &high[],
                                            const double &low[],
                                            const double &close[]);

// Paleta runtime (tema visual premium escolhido no input).
color g_palCorSuporte = C'46,123,214';
color g_palCorResistencia = C'188,36,52';
color g_palCorRompido = C'188,36,52';
color g_palCorProgress = C'46,123,214';
color g_palCorVolBaixo = C'46,123,214';
color g_palCorVolMedio = C'46,123,214';
color g_palCorVolAlto = C'188,36,52';
color g_palCorVolExtremo = C'188,36,52';

void AplicarPaletaVisual() {
   // v4: paleta fixa de alto contraste com apenas duas cores.
   color corElegante = InpCorPaletaElegante;
   color corVermelha = InpCorPaletaVermelha;

   g_palCorSuporte = corElegante;
   g_palCorResistencia = corVermelha;
   g_palCorRompido = corVermelha;
   g_palCorProgress = corElegante;
   g_palCorVolBaixo = corElegante;
   g_palCorVolMedio = corElegante;
   g_palCorVolAlto = corVermelha;
   g_palCorVolExtremo = corVermelha;
}

// Estrutura para os pivôs ativos
struct PivoAtivo {
   double preco;
   double precoSuperior;
   double precoInferior;
   datetime tempoInicio;
   datetime tempoMaisRecente;
   double volumeTotal;
   double volumeBuy;
   double volumeSell;
   double volumeDistribuicao;       // Volume usado para percentual (somente picos, se ativo)
   double scoreOrigem;              // Score da barra de origem (volume+sombra+corpo)
   int espessuraZona;               // Espessura visual derivada do score de origem
   double volumeMaximo;              // Volume máximo global
   double percentualVolume;          // Percentual em relação ao máximo
   double percentualVolumeInterno;   // % da zona dentro do conjunto de zonas ativas
   int quantidadeBarras;
   int quantidadeTopos;
   int quantidadeFundos;
   ENUM_LINE_TYPE tipo;
   ENUM_LINE_TYPE tipoMajoritario;
   ENUM_PIVO_STATE estado;
   color corAtual;
   double atr;
   int barraInicio;
   int barraRompimento;
   datetime tempoRompimento;
   int barrasAposRompimento;
   bool precoAssentado;
   double distanciaPrecoAtual;
   double score;
   bool foiMergeada;
   int pivoID;
   string pivosIncorporados;
   ENUM_VOLUME_INTENSIDADE intensidadeVolume;
   datetime ultimoTempoToqueContabilizado;
   double ancoraPreco;
   double ancoraSup;
   double ancoraInf;
   datetime ancoraTempoInicio;
   bool ancoraInicializada;
   
   // Construtor padrão
   PivoAtivo() {
      preco = 0;
      precoSuperior = 0;
      precoInferior = 0;
      tempoInicio = 0;
      tempoMaisRecente = 0;
      volumeTotal = 0;
      volumeBuy = 0;
      volumeSell = 0;
      volumeDistribuicao = 0;
      scoreOrigem = 0.0;
      espessuraZona = 1;
      volumeMaximo = 0;
      percentualVolume = 0;
      percentualVolumeInterno = 0;
      quantidadeBarras = 0;
      quantidadeTopos = 0;
      quantidadeFundos = 0;
      tipo = LINE_TOP;
      tipoMajoritario = LINE_TOP;
      estado = PIVO_REMOVIDO;
      corAtual = clrGray;
      atr = 0;
      barraInicio = 0;
      barraRompimento = 0;
      tempoRompimento = 0;
      barrasAposRompimento = 0;
      precoAssentado = false;
      distanciaPrecoAtual = 0;
      score = 0;
      foiMergeada = false;
      pivoID = 0;
      pivosIncorporados = "";
      intensidadeVolume = VOLUME_BAIXO;
      ultimoTempoToqueContabilizado = 0;
      ancoraPreco = 0.0;
      ancoraSup = 0.0;
      ancoraInf = 0.0;
      ancoraTempoInicio = 0;
      ancoraInicializada = false;
   }
   
   // Construtor de cópia
   PivoAtivo(const PivoAtivo &other) {
      preco = other.preco;
      precoSuperior = other.precoSuperior;
      precoInferior = other.precoInferior;
      tempoInicio = other.tempoInicio;
      tempoMaisRecente = other.tempoMaisRecente;
      volumeTotal = other.volumeTotal;
      volumeBuy = other.volumeBuy;
      volumeSell = other.volumeSell;
      volumeDistribuicao = other.volumeDistribuicao;
      scoreOrigem = other.scoreOrigem;
      espessuraZona = other.espessuraZona;
      volumeMaximo = other.volumeMaximo;
      percentualVolume = other.percentualVolume;
      percentualVolumeInterno = other.percentualVolumeInterno;
      quantidadeBarras = other.quantidadeBarras;
      quantidadeTopos = other.quantidadeTopos;
      quantidadeFundos = other.quantidadeFundos;
      tipo = other.tipo;
      tipoMajoritario = other.tipoMajoritario;
      estado = other.estado;
      corAtual = other.corAtual;
      atr = other.atr;
      barraInicio = other.barraInicio;
      barraRompimento = other.barraRompimento;
      tempoRompimento = other.tempoRompimento;
      barrasAposRompimento = other.barrasAposRompimento;
      precoAssentado = other.precoAssentado;
      distanciaPrecoAtual = other.distanciaPrecoAtual;
      score = other.score;
      foiMergeada = other.foiMergeada;
      pivoID = other.pivoID;
      pivosIncorporados = other.pivosIncorporados;
      intensidadeVolume = other.intensidadeVolume;
      ultimoTempoToqueContabilizado = other.ultimoTempoToqueContabilizado;
      ancoraPreco = other.ancoraPreco;
      ancoraSup = other.ancoraSup;
      ancoraInf = other.ancoraInf;
      ancoraTempoInicio = other.ancoraTempoInicio;
      ancoraInicializada = other.ancoraInicializada;
   }
};

PivoAtivo g_pivos[20]; // Máximo 20 pivôs
bool g_pivosInicializados = false;
int g_proximoPivoID = 1;      // Contador global para IDs únicos

// Proteção de zonas-chave: maior volume e maior "fractal".
int ObterIndiceZonaProtegidaPorMaiorVolume();
int ObterIndiceZonaProtegidaPorMaiorFractal();
bool EhZonaProtegidaOrganizacao(const int idx);

// Regras de merge (módulo dedicado).
#include "modules_v6/SupDemVol_MergeRules_v5.mqh"

int ContarZonasAtivas() {
   int total = 0;
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado != PIVO_REMOVIDO) total++;
   }
   return total;
}

double ObterForcaFractalZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return 0.0;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return 0.0;
   int fr = MathMax(g_pivos[idx].quantidadeTopos, g_pivos[idx].quantidadeFundos);
   if(fr < 1) fr = 1;
   return (double)fr;
}

int ObterIndiceZonaProtegidaPorMaiorVolume() {
   int idxMelhor = -1;
   double melhorVolDist = -1.0;
   double melhorVolTotal = -1.0;
   datetime melhorTempo = 0;

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      double volDist = g_pivos[i].volumeDistribuicao;
      double volTotal = g_pivos[i].volumeTotal;
      bool escolhe = false;

      if(volDist > melhorVolDist + 1e-9) escolhe = true;
      else if(MathAbs(volDist - melhorVolDist) <= 1e-9) {
         if(volTotal > melhorVolTotal + 1e-9) escolhe = true;
         else if(MathAbs(volTotal - melhorVolTotal) <= 1e-9) {
            if(idxMelhor < 0 || g_pivos[i].tempoInicio < melhorTempo) escolhe = true;
         }
      }

      if(escolhe) {
         idxMelhor = i;
         melhorVolDist = volDist;
         melhorVolTotal = volTotal;
         melhorTempo = g_pivos[i].tempoInicio;
      }
   }

   return idxMelhor;
}

int ObterIndiceZonaProtegidaPorMaiorFractal() {
   int idxMelhor = -1;
   double melhorFractal = -1.0;
   double melhorVolDist = -1.0;
   datetime melhorTempo = 0;

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      double fr = ObterForcaFractalZona(i);
      double volDist = g_pivos[i].volumeDistribuicao;
      bool escolhe = false;

      if(fr > melhorFractal + 1e-9) escolhe = true;
      else if(MathAbs(fr - melhorFractal) <= 1e-9) {
         if(volDist > melhorVolDist + 1e-9) escolhe = true;
         else if(MathAbs(volDist - melhorVolDist) <= 1e-9) {
            if(idxMelhor < 0 || g_pivos[i].tempoInicio < melhorTempo) escolhe = true;
         }
      }

      if(escolhe) {
         idxMelhor = i;
         melhorFractal = fr;
         melhorVolDist = volDist;
         melhorTempo = g_pivos[i].tempoInicio;
      }
   }

   return idxMelhor;
}

bool EhZonaProtegidaOrganizacao(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return false;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return false;
   if(g_pivos[idx].intensidadeVolume == VOLUME_EXTREMO) return true;

   int idxVol = ObterIndiceZonaProtegidaPorMaiorVolume();
   int idxFractal = ObterIndiceZonaProtegidaPorMaiorFractal();
   return (idx == idxVol || idx == idxFractal);
}

double ObterAlturaMinimaZonaPreco() {
   int pontos = InpAlturaMinimaZonaPontos;
   if(pontos < 1) pontos = 1;
   return _Point * (double)pontos;
}

int ObterBarrasProtecaoRecemCriada() {
   int barras = InpBarrasProtecaoZonaRecemCriada;
   if(barras < 0) barras = 0;
   if(barras > 20) barras = 20;
   return barras;
}

int ObterFaixaExtraZonas() {
   int extra = InpFaixaExtraZonas;
   if(extra < 0) extra = 0;
   if(extra > 10) extra = 10;
   return extra;
}

int ObterMargemCompactacaoSuave() {
   int margem = InpMargemCompactacaoSuave;
   if(margem < 0) margem = 0;
   if(margem > 10) margem = 10;
   return margem;
}

int ObterLimiteAtivosParaCompactar() {
   int limite = g_numeroZonasAlvo + ObterMargemCompactacaoSuave();
   if(limite < g_numeroZonasAlvo) limite = g_numeroZonasAlvo;
   if(limite > g_numeroZonasMax) limite = g_numeroZonasMax;
   return limite;
}

bool DeveCompactarPorExcessoDeZonas() {
   if(!InpPermitirRemoverZonasNoMerge) return false;
   if(!InpHabilitarCompactacaoOverflow) return false;
   return (ContarZonasAtivas() > ObterLimiteAtivosParaCompactar());
}

double ObterFatorDistanciaMinCriacao() {
   double fator = InpFatorDistanciaMinCriacao;
   if(fator < 0.10) fator = 0.10;
   if(fator > 10.0) fator = 10.0;
   return fator;
}

int ObterExtensaoTemporalZona() {
   int ext = InpExtensaoTemporalZona;
   if(ext < 1) ext = 1;
   if(ext > 500) ext = 500;
   return ext;
}

int ObterExtensaoTemporalCoordenada() {
   int ext = InpExtensaoTemporalCoordenada;
   if(ext < 1) ext = 1;
   if(ext > 2000) ext = 2000;
   return ext;
}

bool DeveDesenharZonaAteRecuo() {
   // Compatibilidade: se o parâmetro antigo estiver ligado, também estende.
   return (InpDesenharZonaAteRecuo || InpExibirFaixaVolumeDireita);
}

double ObterMargemVerticalProgress() {
   double m = InpMargemVerticalProgress;
   if(m < 0.0) m = 0.0;
   if(m > 0.45) m = 0.45;
   return m;
}

double ObterFallbackAlturaProgress(const double atr) {
   double fatorATR = InpFallbackAlturaProgressATR;
   if(fatorATR < 0.0) fatorATR = 0.0;
   if(fatorATR > 5.0) fatorATR = 5.0;
   int pontos = InpFallbackAlturaProgressPontos;
   if(pontos < 1) pontos = 1;
   if(pontos > 5000) pontos = 5000;
   return MathMax(atr * fatorATR, _Point * (double)pontos);
}

int ObterPeriodoATR() {
   int p = InpPeriodoATR;
   if(p < 2) p = 2;
   if(p > 200) p = 200;
   return p;
}

int ObterBarrasExtrasHistorico() {
   int b = InpBarrasExtrasHistorico;
   if(b < 0) b = 0;
   if(b > 500) b = 500;
   return b;
}

void ObterLimitesFatorAlturaBarraOrigem(double &fMin, double &fMax) {
   fMin = InpFatorAlturaMinBarraOrigem;
   fMax = InpFatorAlturaMaxBarraOrigem;
   if(fMin < 0.0) fMin = 0.0;
   if(fMax < fMin) fMax = fMin;
   if(fMax > 5.0) fMax = 5.0;
}

double ObterFaixaEstreitaBucketPreco() {
   int pontos = InpFaixaEstreitaBucketPontos;
   if(pontos < 1) pontos = 1;
   if(pontos > 100000) pontos = 100000;
   return _Point * (double)pontos;
}

int ObterVizinhancaPivot() {
   int v = InpVizinhancaPivotBarras;
   if(v < 1) v = 1;
   if(v > 10) v = 10;
   return v;
}

int ObterMinBarrasZigZagMedia() {
   int barras = InpMinBarrasZigZagMedia;
   if(barras < 2) barras = 2;
   if(barras > 2000) barras = 2000;
   return barras;
}

double ObterToleranciaDuplicidadePivotPreco() {
   double pontos = InpToleranciaDuplicidadePivotPontos;
   if(pontos < 0.0) pontos = 0.0;
   if(pontos > 100000.0) pontos = 100000.0;
   return _Point * pontos;
}

double ObterAtrFallbackEmErro() {
   double valor = InpAtrFallbackEmErro;
   if(valor <= 0.0) valor = _Point;
   return valor;
}

int ObterJanelaInicioDiaBarras() {
   int barras = InpJanelaInicioDiaBarras;
   if(barras < 0) barras = 0;
   if(barras > 300) barras = 300;
   return barras;
}

double LimitarPeso(double valor, const double padrao) {
   if(!MathIsValidNumber(valor) || valor <= 0.0) return padrao;
   if(valor < 0.10) valor = 0.10;
   if(valor > 5.00) valor = 5.00;
   return valor;
}

double ObterPesoMaxVolDiaAnterior() {
   return LimitarPeso(InpPesoMaxVolDiaAnterior, 1.35);
}

double ObterPesoMaxVolDiaAtual() {
   return LimitarPeso(InpPesoMaxVolDiaAtual, 1.10);
}

double ObterPesoExtremosDia() {
   return LimitarPeso(InpPesoExtremosDia, 1.10);
}

double ObterRedutorZonaVencida() {
   return LimitarPeso(InpRedutorZonaVencida, 0.85);
}

int ObterDiasReferenciaOrigem() {
   int dias = InpDiasReferenciaOrigem;
   if(dias < 1) dias = 1;
   if(dias > 2) dias = 2;
   return dias;
}

int ObterDiasMaximoZonaAtiva() {
   int dias = InpDiasMaximoZonaAtiva;
   if(dias < 0) dias = 0;
   if(dias > 30) dias = 30;
   return dias;
}

string CriarNomeBaseZonaHibernada(const int idx) {
   int pivoID = g_pivos[idx].pivoID;
   if(pivoID < 0) pivoID = -pivoID;
   int tempoInicio = (int)g_pivos[idx].tempoInicio;
   if(tempoInicio < 0) tempoInicio = 0;
   int contador = g_contadorHibernacao++;
   if(g_contadorHibernacao < 0 || g_contadorHibernacao > 1000000000) g_contadorHibernacao = 1;
   return g_prefixoHibernacao + IntegerToString(pivoID) + "_" +
          IntegerToString(tempoInicio) + "_" + IntegerToString(idx) + "_" + IntegerToString(contador);
}

datetime ObterTempoFimZonaHibernada(const int idx, const datetime tempoReferencia) {
   datetime tempoFim = tempoReferencia;
   string nomeObjAtivo = g_prefixo + "Pivo_" + IntegerToString(idx);
   if(ObjectFind(g_chartID, nomeObjAtivo) >= 0) {
      long tempoObj = ObjectGetInteger(g_chartID, nomeObjAtivo, OBJPROP_TIME, 1);
      if(tempoObj > 0) tempoFim = (datetime)tempoObj;
   } else if(DeveDesenharZonaAteRecuo()) {
      int passo = PeriodSeconds();
      if(passo <= 0) passo = 60;
      tempoFim = tempoReferencia + (datetime)(passo * ObterExtensaoTemporalZona());
   }

   if(tempoFim <= g_pivos[idx].tempoInicio) {
      int passo = PeriodSeconds();
      if(passo <= 0) passo = 60;
      tempoFim = g_pivos[idx].tempoInicio + (datetime)passo;
   }
   return tempoFim;
}

bool CongelarZonaEmHibernacao(const int idx, const datetime tempoReferencia, const int diasMaxAtivo) {
   if(idx < 0 || idx >= g_numeroZonas) return false;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return false;

   string nomeBase = CriarNomeBaseZonaHibernada(idx);
   string nomeTexto = nomeBase + "_Text";
   datetime tempoFim = ObterTempoFimZonaHibernada(idx, tempoReferencia);

   if(!ObjectCreate(g_chartID, nomeBase, OBJ_RECTANGLE, 0,
                    g_pivos[idx].tempoInicio, g_pivos[idx].precoSuperior,
                    tempoFim, g_pivos[idx].precoInferior)) {
      return false;
   }

   color corZona = g_pivos[idx].corAtual;
   if(corZona == clrNONE) {
      corZona = (g_pivos[idx].tipo == LINE_TOP) ? g_palCorResistencia : g_palCorSuporte;
   }

   int larguraZona = g_pivos[idx].espessuraZona;
   if(larguraZona < 1) larguraZona = ConverterScoreEmEspessura(g_pivos[idx].scoreOrigem);
   int larguraBase = ObterLarguraLinhasZona();
   if(larguraZona < larguraBase) larguraZona = larguraBase;
   if(larguraZona < 1) larguraZona = 1;
   if(larguraZona > 10) larguraZona = 10;

   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_COLOR, corZona);
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_WIDTH, larguraZona);
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_HIDDEN, true);

   uint alpha = (uint)InpTransparenciaZonas;
   if(alpha > 255) alpha = 255;
   color corComTransparencia = (color)((corZona & 0x00FFFFFF) | (alpha << 24));
   ObjectSetInteger(g_chartID, nomeBase, OBJPROP_BGCOLOR, corComTransparencia);

   string tipoZona = (g_pivos[idx].tipo == LINE_TOP) ? "Venda" : "Compra";
   ObjectSetString(g_chartID, nomeBase, OBJPROP_TOOLTIP,
                   StringFormat("%s | Hibernada (>%d dias) | PctZonas: %.1f%% | VolDist: %.0f",
                                tipoZona,
                                diasMaxAtivo,
                                g_pivos[idx].percentualVolumeInterno,
                                g_pivos[idx].volumeDistribuicao));

   // Não cria texto em zonas hibernadas para evitar "número solto" no gráfico.
   if(ObjectFind(g_chartID, nomeTexto) >= 0) ObjectDelete(g_chartID, nomeTexto);

   return true;
}

bool HibernarZonasAntigasPorIdade(const int rates_total, const datetime &time[]) {
   // Legado desativado: organização contínua é o mecanismo único de gestão de zonas.
   if(rates_total < 0 && ArraySize(time) < 0) return true;
   return false;
}

bool HibernarZonaParaAbrirSlot(const datetime tempoReferencia) {
   // Legado desativado: gestão de capacidade ocorre apenas no módulo de organização.
   if(tempoReferencia < 0) return true;
   return false;
}

int ObterLinhasLogEnriquecimentoNoGrafico() {
   int n = InpLinhasLogEnriquecimento;
   if(n < 5) n = 5;
   if(n > 12) n = 12;
   return n;
}

int ObterCornerPainelLogEnriquecimento() {
   if(InpPosicaoPainelLogEnriquecimento == PAINEL_LOG_SUP_DIR) return CORNER_RIGHT_UPPER;
   if(InpPosicaoPainelLogEnriquecimento == PAINEL_LOG_INF_ESQ) return CORNER_LEFT_LOWER;
   if(InpPosicaoPainelLogEnriquecimento == PAINEL_LOG_INF_DIR) return CORNER_RIGHT_LOWER;
   return CORNER_LEFT_UPPER;
}

int ObterPainelLogOffsetX() {
   int x = InpPainelLogOffsetX;
   if(x < 0) x = 0;
   if(x > 2000) x = 2000;
   return x;
}

int ObterPainelLogOffsetY() {
   int y = InpPainelLogOffsetY;
   if(y < 0) y = 0;
   if(y > 2000) y = 2000;
   return y;
}

int ObterPainelLogFonteTamanho() {
   int f = InpPainelLogFonteTamanho;
   if(f < 6) f = 6;
   if(f > 36) f = 36;
   return f;
}

color ObterPainelLogCorTexto() {
   color c = InpPainelLogCorTexto;
   if(c == clrNONE) c = clrWhite;
   return c;
}

bool DeveExibirPainelBalanceCVNoGrafico() {
   return InpExibirPainelBalanceCV;
}

int ObterPainelBalanceOffsetX() {
   int x = InpPainelBalanceOffsetX;
   if(x < 0) x = 0;
   if(x > 2000) x = 2000;
   return x;
}

int ObterPainelBalanceOffsetY() {
   int y = InpPainelBalanceOffsetY;
   if(y < 0) y = 0;
   if(y > 2000) y = 2000;
   return y;
}

int ObterPainelBalanceFonteTamanho() {
   int f = InpPainelBalanceFonteTamanho;
   if(f < 6) f = 6;
   if(f > 36) f = 36;
   return f;
}

void RegistrarLinhaPainelLogEnriquecimentoNoGrafico(const string linha) {
   if(!InpExibirLogEnriquecimentoNoGrafico) return;
   if(StringLen(linha) <= 0) return;

   int maxLinhas = ObterLinhasLogEnriquecimentoNoGrafico();
   if(g_logEnriquecimentoCount < maxLinhas) {
      g_logEnriquecimento[g_logEnriquecimentoCount++] = linha;
      return;
   }

   for(int i = 1; i < maxLinhas; i++) {
      g_logEnriquecimento[i - 1] = g_logEnriquecimento[i];
   }
   g_logEnriquecimento[maxLinhas - 1] = linha;
   g_logEnriquecimentoCount = maxLinhas;
}

void RegistrarEventoEnriquecimentoNoGrafico(const string origem,
                                            const datetime tempoBarra,
                                            const int idxZona,
                                            const double volumeAplicado) {
   if(!InpExibirLogEnriquecimentoNoGrafico) return;

   string origemTxt = origem;
   if(StringLen(origemTxt) == 0) origemTxt = "ENRIQ";

   string zonaTxt = "Z?";
   if(idxZona >= 0 && idxZona < g_numeroZonas) {
      string lado = (g_pivos[idxZona].tipo == LINE_BOTTOM) ? "SUP" : "RES";
      zonaTxt = StringFormat("Z%d-%s", idxZona + 1, lado);
   }

   string tempoTxt = "--:--";
   if(tempoBarra > 0) tempoTxt = TimeToString(tempoBarra, TIME_MINUTES);
   double vol = volumeAplicado;
   if(!MathIsValidNumber(vol) || vol < 0.0) vol = 0.0;

   string linha = StringFormat("%s | +%.0f | %s -> %s", tempoTxt, vol, origemTxt, zonaTxt);
   RegistrarLinhaPainelLogEnriquecimentoNoGrafico(linha);
}

void RegistrarMensagemPainelLogEnriquecimentoNoGrafico(const string mensagem) {
   if(!InpExibirLogEnriquecimentoNoGrafico) return;
   if(StringLen(mensagem) <= 0) return;
   RegistrarLinhaPainelLogEnriquecimentoNoGrafico(mensagem);
}

void RegistrarAuditoriaEnriquecimentoBarraNoGrafico(const datetime tempoBarra,
                                                    const double volumeEvento,
                                                    const double volumeAplicado,
                                                    const double volumeResidual,
                                                    const int zonasTocadas,
                                                    const int zonasElegiveis,
                                                    const double volumeZonasAntes,
                                                    const double volumeZonasDepois) {
   if(!InpExibirLogEnriquecimentoNoGrafico) return;

   string tempoTxt = "--:--";
   if(tempoBarra > 0) tempoTxt = TimeToString(tempoBarra, TIME_MINUTES);

   double vEvt = volumeEvento;
   if(!MathIsValidNumber(vEvt) || vEvt < 0.0) vEvt = 0.0;
   double vApp = volumeAplicado;
   if(!MathIsValidNumber(vApp) || vApp < 0.0) vApp = 0.0;
   double vRes = volumeResidual;
   if(!MathIsValidNumber(vRes)) vRes = 0.0;
   if(MathAbs(vRes) < 1e-6) vRes = 0.0;
   double vBefore = volumeZonasAntes;
   if(!MathIsValidNumber(vBefore) || vBefore < 0.0) vBefore = 0.0;
   double vAfter = volumeZonasDepois;
   if(!MathIsValidNumber(vAfter) || vAfter < 0.0) vAfter = 0.0;

   string linha = StringFormat("%s | AUD evt=%.0f app=%.0f res=%.0f tz=%d ez=%d z:%.0f->%.0f",
                               tempoTxt,
                               vEvt,
                               vApp,
                               vRes,
                               zonasTocadas,
                               zonasElegiveis,
                               vBefore,
                               vAfter);
   RegistrarLinhaPainelLogEnriquecimentoNoGrafico(linha);
}

string SDV4_ObterTextoZonaPainelDebug(const int idxZona) {
   if(idxZona < 0 || idxZona >= g_numeroZonas) return "--";
   string lado = (g_pivos[idxZona].tipo == LINE_BOTTOM) ? "SUP" : "RES";
   return StringFormat("Z%d-%s", idxZona + 1, lado);
}

string SDV4_ObterTextoModoConflitoPainelDebug() {
   if(InpModoConflitoSinalEnriquecimento == CONFLITO_SINAL_SUBTRAIR) return "SUBTR";
   if(InpModoConflitoSinalEnriquecimento == CONFLITO_SINAL_MIX_SOMBRA) return "MIX";
   return "HIBR";
}

void RegistrarDebugAlocacaoBarraNoGrafico(const string origem,
                                          const datetime tempoBarra,
                                          const int idxZonaBuy,
                                          const double volumeBuy,
                                          const int idxZonaSell,
                                          const double volumeSell) {
   if(!InpExibirLogEnriquecimentoNoGrafico) return;

   string origemTxt = origem;
   if(StringLen(origemTxt) == 0) origemTxt = "DBG";

   string tempoTxt = "--:--";
   if(tempoBarra > 0) tempoTxt = TimeToString(tempoBarra, TIME_MINUTES);

   double vBuy = volumeBuy;
   if(!MathIsValidNumber(vBuy) || vBuy < 0.0) vBuy = 0.0;
   double vSell = volumeSell;
   if(!MathIsValidNumber(vSell) || vSell < 0.0) vSell = 0.0;

   string zonaBuy = SDV4_ObterTextoZonaPainelDebug(idxZonaBuy);
   string zonaSell = SDV4_ObterTextoZonaPainelDebug(idxZonaSell);
   string modo = SDV4_ObterTextoModoConflitoPainelDebug();

   string linha = StringFormat("%s | DBG %s | B%.0f@%s S%.0f@%s | %s",
                               tempoTxt,
                               origemTxt,
                               vBuy,
                               zonaBuy,
                               vSell,
                               zonaSell,
                               modo);
   RegistrarLinhaPainelLogEnriquecimentoNoGrafico(linha);
}

string ObterTextoLogEnriquecimentoNoGrafico() {
   if(!InpExibirLogEnriquecimentoNoGrafico) return "";
   int maxLinhas = ObterLinhasLogEnriquecimentoNoGrafico();
   int minLinhasExibicao = 5;
   int total = g_logEnriquecimentoCount;
   if(total < 0) total = 0;
   if(total > maxLinhas) total = maxLinhas;

   string out = "ENRIQ (barra->zona->vol):";
   int exibidas = 0;
   for(int i = total - 1; i >= 0; i--) {
      out += "\n" + g_logEnriquecimento[i];
      exibidas++;
   }
   while(exibidas < minLinhasExibicao) {
      out += "\n" + "Aguardando evento...";
      exibidas++;
   }
   return out;
}

bool FiltrarZonasForaJanelaPreco(const int rates_total,
                                 const datetime &time[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[]) {
   // Legado desativado: zonas não são removidas por faixa de preço.
   if(rates_total < 0 && ArraySize(time) < 0 && ArraySize(high) < 0 &&
      ArraySize(low) < 0 && ArraySize(close) < 0) return true;
   return false;
}

double LimitarScoreUnitario(double v) {
   if(!MathIsValidNumber(v)) return 0.0;
   if(v < 0.0) v = 0.0;
   if(v > 1.0) v = 1.0;
   return v;
}

double ObterMaxVolumeReferenciaOrigem(const int idxBarra, const datetime &time[]) {
   if(idxBarra < 0 || idxBarra >= ArraySize(time)) return 0.0;
   int diasRef = ObterDiasReferenciaOrigem();
   datetime diaBase = ObterInicioDia(time[idxBarra]);
   if(diaBase <= 0) return 0.0;
   datetime diaLimite = diaBase - (datetime)((diasRef - 1) * 86400);

   double maxVol = 0.0;
   for(int i = idxBarra; i >= 0; i--) {
      datetime diaI = ObterInicioDia(time[i]);
      if(diaI < diaLimite) break;
      if(VolumeBuffer[i] > maxVol) maxVol = VolumeBuffer[i];
   }
   return maxVol;
}

int ConverterScoreEmEspessura(const double scoreOrigem) {
   double s = LimitarScoreUnitario(scoreOrigem);
   int esp = 1 + (int)MathRound(s * 9.0); // 1..10
   if(esp < 1) esp = 1;
   if(esp > 10) esp = 10;
   return esp;
}

ENUM_LINE_TYPE DeterminarTipoLinhaPorSombra(const int barra,
                                            const double &open[],
                                            const double &high[],
                                            const double &low[],
                                            const double &close[]) {
   int sz = ArraySize(high);
   if(barra < 0 || barra >= sz) return LINE_TOP;
   if(barra >= ArraySize(open) || barra >= ArraySize(low) || barra >= ArraySize(close)) return LINE_TOP;

   double h = high[barra];
   double l = low[barra];
   double o = open[barra];
   double c = close[barra];
   double range = MathMax(h - l, _Point);

   double sup = h - MathMax(o, c);
   double inf = MathMin(o, c) - l;
   if(sup < 0.0) sup = 0.0;
   if(inf < 0.0) inf = 0.0;

   double tol = InpToleranciaDominioSombra;
   if(tol < 0.0) tol = 0.0;
   if(tol > 0.50) tol = 0.50;

   double razao = (sup - inf) / range;
   if(razao > tol) return LINE_TOP;     // sombra superior dominante => resistência (vermelha)
   if(razao < -tol) return LINE_BOTTOM; // sombra inferior dominante => suporte (azul)

   // Empate: usa posição do fechamento na barra.
   double posFech = (c - l) / range;
   if(posFech <= 0.50) return LINE_BOTTOM;
   return LINE_TOP;
}

double CalcularScoreOrigemZona(const int idxBarra,
                               const datetime &time[],
                               const double &open[],
                               const double &high[],
                               const double &low[],
                               const double &close[]) {
   if(idxBarra < 0) return 0.0;
   if(idxBarra >= ArraySize(time) || idxBarra >= ArraySize(open) ||
      idxBarra >= ArraySize(high) || idxBarra >= ArraySize(low) || idxBarra >= ArraySize(close))
      return 0.0;

   double h = high[idxBarra];
   double l = low[idxBarra];
   double o = open[idxBarra];
   double c = close[idxBarra];
   double range = MathMax(h - l, _Point);

   double sombraSup = h - MathMax(o, c);
   double sombraInf = MathMin(o, c) - l;
   if(sombraSup < 0.0) sombraSup = 0.0;
   if(sombraInf < 0.0) sombraInf = 0.0;
   double corpo = MathAbs(c - o);

   ENUM_LINE_TYPE tipoOrigem = DeterminarTipoLinhaPorSombra(idxBarra, open, high, low, close);
   double scoreSombra = (tipoOrigem == LINE_BOTTOM) ? (sombraInf / range) : (sombraSup / range);
   double scoreCorpo = corpo / range;

   double maxVolRef = ObterMaxVolumeReferenciaOrigem(idxBarra, time);
   if(maxVolRef <= 0.0) maxVolRef = VolumeBuffer[idxBarra];
   if(maxVolRef <= 0.0) maxVolRef = 1.0;
   double scoreVolume = VolumeBuffer[idxBarra] / maxVolRef;

   scoreVolume = LimitarScoreUnitario(scoreVolume);
   scoreSombra = LimitarScoreUnitario(scoreSombra);
   scoreCorpo = LimitarScoreUnitario(scoreCorpo);

   double wVol = InpPesoOrigemVolume;
   double wSom = InpPesoOrigemSombra;
   double wCor = InpPesoOrigemCorpo;
   if(wVol < 0.0) wVol = 0.0;
   if(wSom < 0.0) wSom = 0.0;
   if(wCor < 0.0) wCor = 0.0;
   double soma = wVol + wSom + wCor;
   if(soma <= 0.0) {
      wVol = 0.70;
      wSom = 0.25;
      wCor = 0.05;
      soma = 1.0;
   }

   double score = ((scoreVolume * wVol) + (scoreSombra * wSom) + (scoreCorpo * wCor)) / soma;
   return LimitarScoreUnitario(score);
}

datetime ObterInicioDia(const datetime tempo) {
   if(tempo <= 0) return 0;
   return (tempo - (tempo % 86400));
}

datetime ObterTempoAtividadeZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return 0;
   datetime tInicio = g_pivos[idx].tempoInicio;
   datetime tRecente = g_pivos[idx].tempoMaisRecente;
   if(tRecente > tInicio) return tRecente;
   return tInicio;
}

double ObterVolumeNominalZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return 0.0;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return 0.0;

   double volDist = g_pivos[idx].volumeDistribuicao;
   double volTotal = g_pivos[idx].volumeTotal;
   if(volDist < 0.0) volDist = 0.0;
   if(volTotal < 0.0) volTotal = 0.0;

   if(InpDistribuicaoSomentePico) return volDist;
   return MathMax(volDist, volTotal);
}

void AtualizarReferenciasDiarias(const int rates_total,
                                 const datetime &time[],
                                 const double &high[],
                                 const double &low[]) {
   g_referenciaDiaAtual = 0;
   g_referenciaDiaAnterior = 0;
   g_extremoMaxDiaAtual = 0.0;
   g_extremoMinDiaAtual = 0.0;
   g_extremoMaxDiaAnterior = 0.0;
   g_extremoMinDiaAnterior = 0.0;

   if(rates_total <= 0) return;
   if(rates_total > ArraySize(time) || rates_total > ArraySize(high) || rates_total > ArraySize(low)) return;

   g_referenciaDiaAtual = ObterInicioDia(time[rates_total - 1]);
   g_referenciaDiaAnterior = g_referenciaDiaAtual - 86400;

   double maxAtual = -DBL_MAX;
   double minAtual = DBL_MAX;
   double maxAnterior = -DBL_MAX;
   double minAnterior = DBL_MAX;

   bool achouAtual = false;
   bool achouAnterior = false;
   for(int i = rates_total - 1; i >= 0; i--) {
      datetime diaBarra = ObterInicioDia(time[i]);

      if(diaBarra == g_referenciaDiaAtual) {
         if(high[i] > maxAtual) maxAtual = high[i];
         if(low[i] < minAtual) minAtual = low[i];
         achouAtual = true;
      } else if(diaBarra == g_referenciaDiaAnterior) {
         if(high[i] > maxAnterior) maxAnterior = high[i];
         if(low[i] < minAnterior) minAnterior = low[i];
         achouAnterior = true;
      } else if(achouAtual && achouAnterior && diaBarra < g_referenciaDiaAnterior) {
         break;
      }
   }

   if(achouAtual) {
      g_extremoMaxDiaAtual = maxAtual;
      g_extremoMinDiaAtual = minAtual;
   }
   if(achouAnterior) {
      g_extremoMaxDiaAnterior = maxAnterior;
      g_extremoMinDiaAnterior = minAnterior;
   } else {
      g_extremoMaxDiaAnterior = g_extremoMaxDiaAtual;
      g_extremoMinDiaAnterior = g_extremoMinDiaAtual;
   }
}

int ObterTamanhoFonteTextoZona() {
   int fonte = InpTamanhoFonteTextoZona;
   if(fonte < 6) fonte = 6;
   if(fonte > 24) fonte = 24;
   return fonte;
}

int ObterLarguraLinhasZona() {
   int largura = InpLarguraLinhas;
   if(largura < 1) largura = 1;
   if(largura > 10) largura = 10;
   return largura;
}

int CalcularLarguraZonaPorVolume(const int idx) {
   int larguraBase = ObterLarguraLinhasZona();
   if(idx < 0 || idx >= g_numeroZonas) return larguraBase;

   int largura = larguraBase;
   double pct = g_pivos[idx].percentualVolumeInterno;
   if(!MathIsValidNumber(pct) || pct <= 0.0) pct = g_pivos[idx].percentualVolume;
   if(g_volumeMaximoGlobal > 0.0 && MathIsValidNumber(pct)) {
      if(pct < 0.0) pct = 0.0;
      if(pct > 100.0) pct = 100.0;
      largura = 1 + (int)MathRound((pct / 100.0) * 9.0); // 1..10
   } else {
      largura = ConverterScoreEmEspessura(g_pivos[idx].scoreOrigem);
   }

   if(largura < 1) largura = 1;
   if(largura > 10) largura = 10;
   return largura;
}

#include "modules_v6/SupDemVol_ModuleLinhasReferencia_v5.mqh"

#include "modules_v6/SupDemVol_ModuleOrganizacaoCore_v5.mqh"

//+------------------------------------------------------------------+
int OnInit() {
   AplicarPaletaVisual();

   // Configurar buffers
   SetIndexBuffer(0, VolumeBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, VolumeColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, BandaSuperiorBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, ZeroBuffer, INDICATOR_DATA);

   if(!InpExibirPainelVolume) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);
   }
   
   ArraySetAsSeries(MediaBuffer, false);
   ArrayResize(MediaBuffer, 0);
   
   // Organização contínua: gatilho/alvo e limite duro explícitos.
   g_numeroZonasAlvo = ObterAlvoNormalOrganizacaoZonas();
   g_numeroZonasMin = ObterAlvoSemGapOrganizacaoZonas();
   g_numeroZonasMax = ObterLimiteDuroOrganizacaoZonas();
   if(g_numeroZonasMin < 1) g_numeroZonasMin = 1;
   if(g_numeroZonasAlvo < g_numeroZonasMin) g_numeroZonasAlvo = g_numeroZonasMin;
   if(g_numeroZonasMax < g_numeroZonasAlvo) g_numeroZonasMax = g_numeroZonasAlvo;

   // Capacidade operacional é o limite duro.
   g_numeroZonas = g_numeroZonasMax;

   IndicatorSetString(INDICATOR_SHORTNAME,
                      StringFormat("Zonas org gatilho %d | alvo %d/%d | limite %d (%d dias)",
                                   ObterGatilhoOrganizacaoZonas(),
                                   g_numeroZonasAlvo,
                                   g_numeroZonasMin,
                                   g_numeroZonasMax,
                                   InpDiasAnalise));
   
   g_chartID = ChartID();
   long fg = ChartGetInteger(g_chartID, CHART_FOREGROUND, 0);
   if(fg == 0 || fg == 1) {
      g_prevChartForeground = (fg == 1);
      g_prevChartForegroundValid = true;
   }
   ChartSetInteger(g_chartID, CHART_FOREGROUND, true);
   LimparObjetos();

   // ZigZag importado (sem implementação manual no código).
   g_zigzagHandle = iCustom(_Symbol, _Period, "ZigZag", InpZigZagDepth, InpZigZagDeviation, InpZigZagBackstep);
   if(g_zigzagHandle == INVALID_HANDLE) {
      g_zigzagHandle = iCustom(_Symbol, _Period, "Examples\\ZigZag", InpZigZagDepth, InpZigZagDeviation, InpZigZagBackstep);
   }
   if(g_zigzagHandle == INVALID_HANDLE) {
      Print("❌ Falha ao importar ZigZag (ZigZag / Examples\\ZigZag).");
      return(INIT_FAILED);
   }
   
   // Reset das variáveis
   g_profileDesenhado = false;
   g_ultimaAtualizacao = 0;
   g_ultimoDiaAnalise = 0;
   g_pivosInicializados = false;
   
   // Inicializar os pivôs
   for(int i = 0; i < 20; i++) {
      g_pivos[i].estado = PIVO_REMOVIDO;
      g_pivos[i].preco = 0;
      g_pivos[i].score = 0;
      g_pivos[i].pivoID = 0;
      g_pivos[i].pivosIncorporados = "";
      g_pivos[i].precoAssentado = false;
      g_pivos[i].barrasAposRompimento = 0;
      g_pivos[i].volumeTotal = 0;
      g_pivos[i].volumeBuy = 0;
      g_pivos[i].volumeSell = 0;
      g_pivos[i].volumeDistribuicao = 0;
      g_pivos[i].scoreOrigem = 0.0;
      g_pivos[i].espessuraZona = 1;
      g_pivos[i].volumeMaximo = 0;
      g_pivos[i].percentualVolume = 0;
      g_pivos[i].percentualVolumeInterno = 0;
      g_pivos[i].ancoraInicializada = false;
   }
   
   g_volumeMaximoGlobal = 0.0;
   g_maximaRealInicializada = false;
   g_minimaRealInicializada = false;
   g_precoMaximaReal = 0.0;
   g_precoMinimaReal = 0.0;
   g_ultimoDiaOrganizado = 0;
   g_extremoMaxDiaAtual = 0.0;
   g_extremoMinDiaAtual = 0.0;
   g_extremoMaxDiaAnterior = 0.0;
   g_extremoMinDiaAnterior = 0.0;
   g_referenciaDiaAtual = 0;
   g_referenciaDiaAnterior = 0;
   
   Print("════════════════════════════════════════");
   Print("  Organização contínua: gatilho ", ObterGatilhoOrganizacaoZonas(),
         " | alvo ", g_numeroZonasAlvo, "/", g_numeroZonasMin,
         " | limite duro ", g_numeroZonasMax);
   Print("════════════════════════════════════════");
   Print("  🎯 COR POR VOLUME: Paleta premium de baixa saturação");
   Print("  📊 PROGRESS BAR: Mostra volume acumulado visualmente");
   Print("  ✅ MERGE IMEDIATO: ", InpMergeATRPercent, "% ATR");
   Print("  ✅ DISTÂNCIA MÍNIMA: ZigZag importado x ", DoubleToString(InpDistMinFatorZigZag, 2));
   Print("  ⏱️ ANTI PISCA-PISCA: ", InpTempoAssentamento, " barras");
   Print("  ✅ ALTURA MÁXIMA: ", InpMaxATRPercent, "% ATR");
   Print("  ⚠️ FILTRO RIGOROSO: SÓ barras acima desvio padrão");
   Print("════════════════════════════════════════");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(g_zigzagHandle != INVALID_HANDLE) {
      IndicatorRelease(g_zigzagHandle);
      g_zigzagHandle = INVALID_HANDLE;
   }
   if(g_prevChartForegroundValid) {
      ChartSetInteger(g_chartID, CHART_FOREGROUND, g_prevChartForeground);
   }
   LimparObjetos();
   Comment("");
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   
   if(rates_total < InpPeriodoMedia + ObterBarrasExtrasHistorico()) return(0);
   
   // Determinar início do cálculo
   int start;
   if(prev_calculated == 0) {
      start = 0;
      g_profileDesenhado = false;
   } else {
      start = prev_calculated - 1;
      if(rates_total > prev_calculated) {
         start = prev_calculated;
      }
   }
   
   // Garantir tamanho correto do MediaBuffer
   if(ArraySize(MediaBuffer) != rates_total) {
      ArrayResize(MediaBuffer, rates_total);
   }
   
   // Calcular volume e limiar (média do dia x multiplicador)
   double somaMediaDia = 0.0;
   int contMediaDia = 0;
   datetime diaMediaAtual = 0;
   if(start > 0) {
      diaMediaAtual = time[start] - (time[start] % 86400);
      for(int k = start - 1; k >= 0; k--) {
         datetime dk = time[k] - (time[k] % 86400);
         if(dk != diaMediaAtual) break;
         somaMediaDia += VolumeBuffer[k];
         contMediaDia++;
      }
   }

   for(int i = start; i < rates_total; i++) {
      VolumeBuffer[i] = (double)tick_volume[i];
      ZeroBuffer[i] = 0;

      datetime diaI = time[i] - (time[i] % 86400);
      if(i == start) {
         if(start == 0 || diaI != diaMediaAtual) {
            diaMediaAtual = diaI;
            somaMediaDia = 0.0;
            contMediaDia = 0;
         }
      } else if(diaI != diaMediaAtual) {
         diaMediaAtual = diaI;
         somaMediaDia = 0.0;
         contMediaDia = 0;
      }

      somaMediaDia += VolumeBuffer[i];
      contMediaDia++;
      MediaBuffer[i] = (contMediaDia > 0) ? (somaMediaDia / contMediaDia) : VolumeBuffer[i];
      BandaSuperiorBuffer[i] = MediaBuffer[i] * InpMultiplicadorDesvio;
      
      // Colorir volume
      if(VolumeBuffer[i] > BandaSuperiorBuffer[i]) {
         VolumeColorBuffer[i] = 2; // Vermelho - Volume Alto
      } else if(VolumeBuffer[i] > MediaBuffer[i]) {
         VolumeColorBuffer[i] = 1; // Verde - Volume Médio
      } else {
         VolumeColorBuffer[i] = 0; // Azul - Volume Baixo
      }
   }

   AtualizarReferenciasDiarias(rates_total, time, high, low);
   
   // Processar zonas em modo barra 0 fixa (sem "andar")
   if(InpMostrarProfile) {
      SDV4_ModuloCentralProcessar(rates_total, prev_calculated, time, open, high, low, close, tick_volume);
   }

   AtualizarLinhaMaiorMaxima(rates_total, high);
   AtualizarLinhaMenorMinima(rates_total, low);
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calcular percentuais de volume para progress bars               |
//+------------------------------------------------------------------+
#include "modules_v6/SupDemVol_ModulePercentuais_v5.mqh"
#include "modules_v6/SupDemVol_ModuleRuntimeOps_v5.mqh"

//+------------------------------------------------------------------+
//| Desenhar os pivôs com PROGRESS BARS no gráfico                 |
//+------------------------------------------------------------------+
#include "modules_v6/SupDemVol_ModuleVisual_v5.mqh"

#include "modules_v6/SupDemVol_ModuleCentral_v5.mqh"

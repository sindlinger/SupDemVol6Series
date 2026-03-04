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

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
// Parâmetros do Volume
input int      InpPeriodoMedia = 20;                // Período para Média do Volume
input double   InpMultiplicadorDesvio = 2.0;        // Multiplicador do Desvio Padrão
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
input bool     InpMostrarProgressBar = false;       // (Desativado) Progress Bar de Volume
input bool     InpExibirFaixaVolumeDireita = false; // Exibe a faixa de progresso no recuo direito
input bool     InpDesenharZonaAteRecuo = true;      // Estende a zona ate o recuo direito (sem progress bar)
input bool     InpExibirPainelVolume = true;        // Exibir painel de volume (histograma/banda/zero) ao carregar
input bool     InpAtualizarUIApenasBarraNova = true; // Reduz pisca-pisca: atualiza UI só em barra nova/mudança
input bool     InpLogDetalhado = true;              // Log detalhado (pode deixar lento/ruidoso)
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
input string   InpSeparadorOrganizacaoDiaria = "═══ ORGANIZACAO DIARIA DAS ZONAS ═══";
input bool     InpOrganizacaoDiariaAtiva = true;    // Ativa a organizacao 1x por dia (sem turncoat)
input bool     InpOrganizacaoEmBarraFechada = true; // Organiza em toda barra fechada (nao apenas no inicio do dia)
input int      InpOrganizacaoDiariaMaxMerges = 2;   // Maximo de merges por organizacao diaria
input bool     InpOrganizacaoDiariaPorFaixa = true; // Se true, tenta condensar por superior/meio/inferior antes do fallback geral
input string   InpSeparadorAvancado = "═══ AJUSTES AVANÇADOS EXPOSTOS ═══";
input bool     InpHabilitarCompactacaoOverflow = true; // Compactacao quando ativos > alvo + margem
input int      InpFaixaExtraZonas = 2;              // Banda dinâmica ao redor do alvo (N-Extra..N+Extra)
input int      InpBarrasProtecaoZonaRecemCriada = 1; // Proteção contra absorção imediata
input bool     InpHabilitarMergeMesmaBarra = true;  // Permite merge quando uma barra toca mais de uma zona
input bool     InpPermitirRemoverZonasNoMerge = true; // Se false, merges que apagam zona ficam bloqueados
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
input double   InpPesoOrigemVolume = 0.70;          // Peso do volume na espessura da zona de origem
input double   InpPesoOrigemSombra = 0.25;          // Peso da sombra dominante na espessura
input double   InpPesoOrigemCorpo = 0.05;           // Peso do corpo do candle na espessura
input double   InpToleranciaDominioSombra = 0.05;   // Tolerancia para definir sombra dominante
input bool     InpDistribuicaoSomentePico = true;   // Distribuição usa só barras acima da banda
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
string g_prefixo = "VProfile7_v4_";
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
datetime g_tempoUltimaCriacaoBarra = 0;
int g_zigzagHandle = INVALID_HANDLE;
bool g_prevChartForeground = false;
bool g_prevChartForegroundValid = false;
datetime g_tempoEventoMerge = 0;
bool g_mergeExecutadoNoEvento = false;
bool g_mergeCorretivoPendente = false;
datetime g_tempoCriacaoOverflow = 0;
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
   double volumeDistribuicao;       // Volume usado para percentual (somente picos, se ativo)
   double scoreOrigem;              // Score da barra de origem (volume+sombra+corpo)
   int espessuraZona;               // Espessura visual derivada do score de origem
   double volumeMaximo;              // Volume máximo global
   double percentualVolume;          // Percentual em relação ao máximo
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
      volumeDistribuicao = 0;
      scoreOrigem = 0.0;
      espessuraZona = 1;
      volumeMaximo = 0;
      percentualVolume = 0;
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
      volumeDistribuicao = other.volumeDistribuicao;
      scoreOrigem = other.scoreOrigem;
      espessuraZona = other.espessuraZona;
      volumeMaximo = other.volumeMaximo;
      percentualVolume = other.percentualVolume;
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
#include "SupDemVol_MergeRules_v4.mqh"

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

int ObterPeriodoLinhaMaiorMaxima() {
   int p = InpPeriodoLinhaMaiorMaxima;
   if(p < 1) p = 1;
   if(p > 5000) p = 5000;
   return p;
}

int ObterLarguraLinhaMaiorMaxima() {
   int largura = InpLarguraLinhaMaiorMaxima;
   if(largura < 1) largura = 1;
   if(largura > 5) largura = 5;
   return largura;
}

double ObterMaiorMaximaUltimosPeriodos(const int rates_total, const double &high[]) {
   if(rates_total <= 0) return 0.0;
   int periodo = ObterPeriodoLinhaMaiorMaxima();
   int inicio = rates_total - periodo;
   if(inicio < 0) inicio = 0;

   double maior = high[inicio];
   for(int i = inicio + 1; i < rates_total; i++) {
      if(high[i] > maior) maior = high[i];
   }
   return maior;
}

void AtualizarLinhaMaiorMaxima(const int rates_total, const double &high[]) {
   string nomeLinha = g_prefixo + "LinhaMaiorMaxima";
   if(!InpMostrarLinhaMaiorMaxima || rates_total <= 0) {
      if(ObjectFind(g_chartID, nomeLinha) >= 0) ObjectDelete(g_chartID, nomeLinha);
      return;
   }
   if(rates_total > ArraySize(high)) return;

   double maiorMaxima = ObterMaiorMaximaUltimosPeriodos(rates_total, high);
   if(!MathIsValidNumber(maiorMaxima) || maiorMaxima <= 0.0) return;

   double precoLinha = maiorMaxima;
   double tolerancia = _Point * 0.5;
   if(InpMaximaReal) {
      if(!g_maximaRealInicializada) {
         g_precoMaximaReal = maiorMaxima;
         g_maximaRealInicializada = true;
      } else {
         double highAtual = high[rates_total - 1];
         if(highAtual > g_precoMaximaReal + tolerancia) {
            g_precoMaximaReal = maiorMaxima;
         }
      }
      precoLinha = g_precoMaximaReal;
   } else {
      g_precoMaximaReal = maiorMaxima;
      g_maximaRealInicializada = false;
   }

   if(ObjectFind(g_chartID, nomeLinha) < 0) {
      ObjectCreate(g_chartID, nomeLinha, OBJ_HLINE, 0, 0, precoLinha);
   }
   ObjectSetDouble(g_chartID, nomeLinha, OBJPROP_PRICE, precoLinha);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_COLOR, InpCorLinhaMaiorMaxima);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_STYLE, InpEstiloLinhaMaiorMaxima);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_WIDTH, ObterLarguraLinhaMaiorMaxima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_BACK, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_HIDDEN, true);
   ObjectSetString(g_chartID, nomeLinha, OBJPROP_TOOLTIP,
                   StringFormat("Maior máxima (%d): %.5f | Máxima real: %s",
                                ObterPeriodoLinhaMaiorMaxima(),
                                precoLinha,
                                InpMaximaReal ? "SIM" : "NAO"));
}

int ObterPeriodoLinhaMenorMinima() {
   int p = InpPeriodoLinhaMenorMinima;
   if(p < 1) p = 1;
   if(p > 5000) p = 5000;
   return p;
}

int ObterLarguraLinhaMenorMinima() {
   int largura = InpLarguraLinhaMenorMinima;
   if(largura < 1) largura = 1;
   if(largura > 5) largura = 5;
   return largura;
}

double ObterMenorMinimaUltimosPeriodos(const int rates_total, const double &low[]) {
   if(rates_total <= 0) return 0.0;
   int periodo = ObterPeriodoLinhaMenorMinima();
   int inicio = rates_total - periodo;
   if(inicio < 0) inicio = 0;

   double menor = low[inicio];
   for(int i = inicio + 1; i < rates_total; i++) {
      if(low[i] < menor) menor = low[i];
   }
   return menor;
}

void AtualizarLinhaMenorMinima(const int rates_total, const double &low[]) {
   string nomeLinha = g_prefixo + "LinhaMenorMinima";
   if(!InpMostrarLinhaMenorMinima || rates_total <= 0) {
      if(ObjectFind(g_chartID, nomeLinha) >= 0) ObjectDelete(g_chartID, nomeLinha);
      return;
   }
   if(rates_total > ArraySize(low)) return;

   double menorMinima = ObterMenorMinimaUltimosPeriodos(rates_total, low);
   if(!MathIsValidNumber(menorMinima) || menorMinima <= 0.0) return;

   double precoLinha = menorMinima;
   double tolerancia = _Point * 0.5;
   if(InpMaximaReal) {
      if(!g_minimaRealInicializada) {
         g_precoMinimaReal = menorMinima;
         g_minimaRealInicializada = true;
      } else {
         double lowAtual = low[rates_total - 1];
         if(lowAtual < g_precoMinimaReal - tolerancia) {
            g_precoMinimaReal = menorMinima;
         }
      }
      precoLinha = g_precoMinimaReal;
   } else {
      g_precoMinimaReal = menorMinima;
      g_minimaRealInicializada = false;
   }

   if(ObjectFind(g_chartID, nomeLinha) < 0) {
      ObjectCreate(g_chartID, nomeLinha, OBJ_HLINE, 0, 0, precoLinha);
   }
   ObjectSetDouble(g_chartID, nomeLinha, OBJPROP_PRICE, precoLinha);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_COLOR, InpCorLinhaMenorMinima);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_STYLE, InpEstiloLinhaMenorMinima);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_WIDTH, ObterLarguraLinhaMenorMinima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_BACK, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_HIDDEN, true);
   ObjectSetString(g_chartID, nomeLinha, OBJPROP_TOOLTIP,
                   StringFormat("Menor mínima (%d): %.5f | Máxima real: %s",
                                ObterPeriodoLinhaMenorMinima(),
                                precoLinha,
                                InpMaximaReal ? "SIM" : "NAO"));
}

int ObterMaxMergesOrganizacaoDia() {
   int n = InpOrganizacaoDiariaMaxMerges;
   if(n < 0) n = 0;
   if(n > 20) n = 20;
   return n;
}

ENUM_LINE_TYPE ClassificarTipoPorExistencia(const int idx, const double precoReferencia) {
   if(idx < 0 || idx >= g_numeroZonas) return LINE_TOP;
   double sup = MathMax(g_pivos[idx].precoSuperior, g_pivos[idx].precoInferior);
   double inf = MathMin(g_pivos[idx].precoSuperior, g_pivos[idx].precoInferior);
   if(sup < precoReferencia) return LINE_BOTTOM; // zona abaixo do preço => suporte
   if(inf > precoReferencia) return LINE_TOP;    // zona acima do preço => resistência
   return g_pivos[idx].tipo;                     // sem turncoat: preserva tipo atual
}

int ClassificarFaixaOrganizacaoDiaria(const double preco, const double precoMin, const double precoMax) {
   double amplitude = precoMax - precoMin;
   if(amplitude <= _Point) return 1;

   double tercil = amplitude / 3.0;
   double limiteInferior = precoMin + tercil;
   double limiteSuperior = precoMin + (2.0 * tercil);

   if(preco <= limiteInferior) return 0; // inferior
   if(preco >= limiteSuperior) return 2; // superior
   return 1; // meio
}

int ClassificarBucketPreco(const double preco, const double precoMin, const double precoMax) {
   double amplitude = precoMax - precoMin;
   if(amplitude <= ObterFaixaEstreitaBucketPreco()) return 1; // Tudo no miolo quando a faixa for muito estreita.

   double tercil = amplitude / 3.0;
   double limiteInferior = precoMin + tercil;
   double limiteSuperior = precoMin + (tercil * 2.0);

   if(preco <= limiteInferior) return 0; // inferior
   if(preco >= limiteSuperior) return 2; // superior
   return 1; // meio
}

bool OrganizarZonasNoInicioDoDia(const double precoReferencia, const datetime tempoEvento) {
   if(!InpOrganizacaoDiariaAtiva) return false;
   if(!InpPermitirRemoverZonasNoMerge) return false;

   int limiteMerges = ObterMaxMergesOrganizacaoDia();
   if(limiteMerges <= 0) return false;

   bool houveMudanca = false;
   int merges = 0;
   while(merges < limiteMerges) {
      int idxKeep = -1;
      int idxDrop = -1;
      double melhorScoreDrop = -DBL_MAX;
      bool usouFallbackSemFaixa = false;

      int faixaZona[20];
      for(int f = 0; f < 20; f++) faixaZona[f] = 1;

      double precoMinAtivo = DBL_MAX;
      double precoMaxAtivo = -DBL_MAX;
      for(int z = 0; z < g_numeroZonas; z++) {
         if(g_pivos[z].estado == PIVO_REMOVIDO) continue;
         if(g_pivos[z].preco < precoMinAtivo) precoMinAtivo = g_pivos[z].preco;
         if(g_pivos[z].preco > precoMaxAtivo) precoMaxAtivo = g_pivos[z].preco;
      }
      if(precoMinAtivo == DBL_MAX || precoMaxAtivo == -DBL_MAX) break;
      for(int z = 0; z < g_numeroZonas; z++) {
         if(g_pivos[z].estado == PIVO_REMOVIDO) continue;
         faixaZona[z] = ClassificarFaixaOrganizacaoDiaria(g_pivos[z].preco, precoMinAtivo, precoMaxAtivo);
      }

      int tentativas = InpOrganizacaoDiariaPorFaixa ? 2 : 1;
      for(int tentativa = 0; tentativa < tentativas && idxKeep < 0; tentativa++) {
         bool exigirMesmaFaixa = (InpOrganizacaoDiariaPorFaixa && tentativa == 0);
         if(!exigirMesmaFaixa && InpOrganizacaoDiariaPorFaixa) usouFallbackSemFaixa = true;

         for(int i = 0; i < g_numeroZonas; i++) {
            if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
            for(int j = i + 1; j < g_numeroZonas; j++) {
               if(g_pivos[j].estado == PIVO_REMOVIDO) continue;

               // Regra atual: permite merge entre tipos diferentes (suporte x resistência).
               // Não bloqueia mais por cor/tipo.
               if(exigirMesmaFaixa && faixaZona[i] != faixaZona[j]) continue;

               double dist = DistanciaEntreFaixas(g_pivos[i].precoSuperior, g_pivos[i].precoInferior,
                                                  g_pivos[j].precoSuperior, g_pivos[j].precoInferior);
               if(dist > 0.0) continue; // princípio do Shved: condensa sobreposição

               int keep = i;
               int drop = j;
               bool protI = EhZonaProtegidaOrganizacao(i);
               bool protJ = EhZonaProtegidaOrganizacao(j);

               if(protI && !protJ) {
                  keep = i;
                  drop = j;
               } else if(protJ && !protI) {
                  keep = j;
                  drop = i;
               } else {
                  double forcaI =
                     (MathLog(1.0 + MathMax(0.0, g_pivos[i].volumeDistribuicao)) * 0.65) +
                     (ObterForcaFractalZona(i) * 0.35);
                  double forcaJ =
                     (MathLog(1.0 + MathMax(0.0, g_pivos[j].volumeDistribuicao)) * 0.65) +
                     (ObterForcaFractalZona(j) * 0.35);

                  if(forcaJ > forcaI + 1e-9) {
                     keep = j;
                     drop = i;
                  } else if(MathAbs(forcaJ - forcaI) <= 1e-9) {
                     double distI = MathAbs(g_pivos[i].preco - precoReferencia);
                     double distJ = MathAbs(g_pivos[j].preco - precoReferencia);
                     if(distJ < distI) {
                        keep = j;
                        drop = i;
                     }
                  }
               }

               if(EhZonaProtegidaOrganizacao(drop)) continue;

               double forcaDrop =
                  (MathLog(1.0 + MathMax(0.0, g_pivos[drop].volumeDistribuicao)) * 0.65) +
                  (ObterForcaFractalZona(drop) * 0.35);
               double scoreDrop = (MathAbs(g_pivos[drop].preco - precoReferencia) * 0.70) +
                                  ((forcaDrop > 0.0 ? (1.0 / forcaDrop) : 1.0) * 0.30);
               if(scoreDrop > melhorScoreDrop) {
                  melhorScoreDrop = scoreDrop;
                  idxKeep = keep;
                  idxDrop = drop;
               }
            }
         }
      }

      if(idxKeep < 0 || idxDrop < 0) break;
      if(!AbsorverZonaSemMoverAncora(idxKeep, idxDrop, tempoEvento)) break;

      houveMudanca = true;
      if(InpLogDetalhado && usouFallbackSemFaixa) {
         Print("ORGANIZAÇÃO_DIÁRIA: fallback sem faixa (superior/meio/inferior) nesta fusão.");
      }
      merges++;
   }

   return houveMudanca;
}

void ObterLimiaresIntensidadeVolume(double &medio, double &alto, double &extremo) {
   medio = InpVolumeRatioMedio;
   alto = InpVolumeRatioAlto;
   extremo = InpVolumeRatioExtremo;

   if(medio < 1.0) medio = 1.0;
   if(alto < medio) alto = medio;
   if(extremo < alto) extremo = alto;
}

void DefinirAncoraPivo(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return;
   g_pivos[idx].ancoraPreco = g_pivos[idx].preco;
   g_pivos[idx].ancoraSup = g_pivos[idx].precoSuperior;
   g_pivos[idx].ancoraInf = g_pivos[idx].precoInferior;
   g_pivos[idx].ancoraTempoInicio = g_pivos[idx].tempoInicio;
   g_pivos[idx].ancoraInicializada = true;
}

void AplicarTravaAncoraPivos() {
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(!g_pivos[i].ancoraInicializada) {
         DefinirAncoraPivo(i);
         continue;
      }

      // Guardrail forte: merge pode absorver volume, mas nunca deslocar a origem da zona.
      g_pivos[i].preco = g_pivos[i].ancoraPreco;
      g_pivos[i].precoSuperior = g_pivos[i].ancoraSup;
      g_pivos[i].precoInferior = g_pivos[i].ancoraInf;
      g_pivos[i].tempoInicio = g_pivos[i].ancoraTempoInicio;
   }
}

bool ZonaRecemCriadaProtegida(const int idx, const datetime tempoEvento, const int barrasProtecao = -1) {
   if(idx < 0 || idx >= g_numeroZonas) return false;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return false;
   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   int barras = (barrasProtecao >= 0) ? barrasProtecao : ObterBarrasProtecaoRecemCriada();
   if(barras <= 0) return false;
   datetime limite = tempoEvento - (datetime)(passo * barras);
   return (g_pivos[idx].tempoInicio >= limite);
}

bool SelecionarParMergeCorretivo(const double precoAtualRef,
                                 const datetime diaAtual,
                                 const datetime tempoEvento,
                                 int &idxDrop,
                                 int &idxKeep) {
   idxDrop = -1;
   idxKeep = -1;

   int ativos[20];
   int nAtivos = 0;
   double precoMin = DBL_MAX;
   double precoMax = -DBL_MAX;
   double maxVolume = 0.0;
   double maxDistPreco = 0.0;

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      ativos[nAtivos++] = i;
      if(g_pivos[i].preco < precoMin) precoMin = g_pivos[i].preco;
      if(g_pivos[i].preco > precoMax) precoMax = g_pivos[i].preco;
      if(g_pivos[i].volumeTotal > maxVolume) maxVolume = g_pivos[i].volumeTotal;
      double distPreco = MathAbs(g_pivos[i].preco - precoAtualRef);
      if(distPreco > maxDistPreco) maxDistPreco = distPreco;
   }

   if(nAtivos < 2) return false;
   if(maxVolume <= 0.0) maxVolume = 1.0;
   if(maxDistPreco <= 0.0) maxDistPreco = ObterFaixaEstreitaBucketPreco();

   double wProx = InpPesoScoreProximidade;
   double wDist = InpPesoScoreDistanciaPreco;
   double wVol = InpPesoScoreBaixoVolume;
   double wAge = InpPesoScoreAntiguidade;
   if(wProx < 0.0) wProx = 0.0;
   if(wDist < 0.0) wDist = 0.0;
   if(wVol < 0.0) wVol = 0.0;
   if(wAge < 0.0) wAge = 0.0;
   double somaPesos = wProx + wDist + wVol + wAge;
   if(somaPesos <= 0.0) {
      wProx = 0.35;
      wDist = 0.25;
      wVol = 0.25;
      wAge = 0.15;
      somaPesos = 1.0;
   }

   double menorDist[20];
   int bucketZona[20];
   double maxDistEntreZonas = 0.0;

   for(int a = 0; a < nAtivos; a++) {
      int idxA = ativos[a];
      bucketZona[a] = ClassificarBucketPreco(g_pivos[idxA].preco, precoMin, precoMax);
      menorDist[a] = DBL_MAX;

      for(int b = 0; b < nAtivos; b++) {
         if(a == b) continue;
         int idxB = ativos[b];
         if(g_pivos[idxB].estado == PIVO_REMOVIDO) continue;
         if(bucketZona[a] != ClassificarBucketPreco(g_pivos[idxB].preco, precoMin, precoMax)) continue;

         double d = DistanciaEntreFaixas(g_pivos[idxA].precoSuperior, g_pivos[idxA].precoInferior,
                                         g_pivos[idxB].precoSuperior, g_pivos[idxB].precoInferior);
         if(d < menorDist[a]) menorDist[a] = d;
      }

      if(menorDist[a] == DBL_MAX) {
         for(int b = 0; b < nAtivos; b++) {
            if(a == b) continue;
            int idxB = ativos[b];
            double d = DistanciaEntreFaixas(g_pivos[idxA].precoSuperior, g_pivos[idxA].precoInferior,
                                            g_pivos[idxB].precoSuperior, g_pivos[idxB].precoInferior);
            if(d < menorDist[a]) menorDist[a] = d;
         }
      }

      if(menorDist[a] == DBL_MAX) menorDist[a] = 0.0;
      if(menorDist[a] > maxDistEntreZonas) maxDistEntreZonas = menorDist[a];
   }

   if(maxDistEntreZonas <= 0.0) maxDistEntreZonas = ObterFaixaEstreitaBucketPreco();

   double melhorScore = -DBL_MAX;
   int bucketDrop = 1;
   datetime melhorDia = 0;
   double melhorDistPreco = 0.0;
   double melhorVol = DBL_MAX;
   bool encontrouElegivel = false;

   for(int a = 0; a < nAtivos; a++) {
      int idx = ativos[a];
      if(ZonaRecemCriadaProtegida(idx, tempoEvento)) continue; // Não apagar zona recém-criada.
      if(EhZonaProtegidaOrganizacao(idx)) continue;            // Preserva maior volume e maior fractal.

      double scoreProximidade = 1.0 - MathMin(1.0, menorDist[a] / maxDistEntreZonas);
      double scoreDistanciaPreco = MathMin(1.0, MathAbs(g_pivos[idx].preco - precoAtualRef) / maxDistPreco);
      double scoreBaixoVolume = 1.0 - MathMin(1.0, g_pivos[idx].volumeTotal / maxVolume);

      datetime diaZona = g_pivos[idx].tempoInicio - (g_pivos[idx].tempoInicio % 86400);
      double scoreAntiguidade = (diaZona < diaAtual) ? 1.0 : 0.0;

      double score = ((scoreProximidade * wProx) +
                      (scoreDistanciaPreco * wDist) +
                      (scoreBaixoVolume * wVol) +
                      (scoreAntiguidade * wAge)) / somaPesos;

      bool escolhe = false;
      if(score > melhorScore + 1e-9) {
         escolhe = true;
      } else if(MathAbs(score - melhorScore) <= 1e-9) {
         if(diaZona < melhorDia) escolhe = true;
         else if(diaZona == melhorDia) {
            double distAtual = MathAbs(g_pivos[idx].preco - precoAtualRef);
            if(distAtual > melhorDistPreco + 1e-9) escolhe = true;
            else if(MathAbs(distAtual - melhorDistPreco) <= 1e-9 && g_pivos[idx].volumeTotal < melhorVol) {
               escolhe = true;
            }
         }
      }

      if(escolhe) {
         melhorScore = score;
         idxDrop = idx;
         bucketDrop = bucketZona[a];
         melhorDia = diaZona;
         melhorDistPreco = MathAbs(g_pivos[idx].preco - precoAtualRef);
         melhorVol = g_pivos[idx].volumeTotal;
         encontrouElegivel = true;
      }
   }

   if(idxDrop < 0 || !encontrouElegivel) return false;

   double melhorDistPar = DBL_MAX;
   for(int a = 0; a < nAtivos; a++) {
      int idx = ativos[a];
      if(idx == idxDrop) continue;

      int bucket = ClassificarBucketPreco(g_pivos[idx].preco, precoMin, precoMax);
      if(bucket != bucketDrop) continue;

      double d = DistanciaEntreFaixas(g_pivos[idxDrop].precoSuperior, g_pivos[idxDrop].precoInferior,
                                      g_pivos[idx].precoSuperior, g_pivos[idx].precoInferior);
      if(d < melhorDistPar) {
         melhorDistPar = d;
         idxKeep = idx;
      }
   }

   if(idxKeep < 0) {
      for(int a = 0; a < nAtivos; a++) {
         int idx = ativos[a];
         if(idx == idxDrop) continue;

         double d = DistanciaEntreFaixas(g_pivos[idxDrop].precoSuperior, g_pivos[idxDrop].precoInferior,
                                         g_pivos[idx].precoSuperior, g_pivos[idx].precoInferior);
         if(d < melhorDistPar) {
            melhorDistPar = d;
            idxKeep = idx;
         }
      }
   }

   return (idxKeep >= 0);
}

bool AbsorverZonaSemMoverAncora(const int idxKeep, const int idxDrop, const datetime tempoEvento) {
   if(!InpPermitirRemoverZonasNoMerge) return false;
   if(idxKeep < 0 || idxKeep >= g_numeroZonas) return false;
   if(idxDrop < 0 || idxDrop >= g_numeroZonas) return false;
   if(idxKeep == idxDrop) return false;
   if(g_pivos[idxKeep].estado == PIVO_REMOVIDO) return false;
   if(g_pivos[idxDrop].estado == PIVO_REMOVIDO) return false;
   if(EhZonaProtegidaOrganizacao(idxDrop)) return false;

   PivoAtivo keep = g_pivos[idxKeep];
   PivoAtivo drop = g_pivos[idxDrop];

   // Regra central: preserva a origem (preço-âncora e tempo de criação) da zona sobrevivente.
   if(!g_pivos[idxKeep].ancoraInicializada) DefinirAncoraPivo(idxKeep);

   double fatorAbsorcao = InpFatorAbsorcaoMerge;
   if(fatorAbsorcao < 0.0) fatorAbsorcao = 0.0;
   if(fatorAbsorcao > 1.0) fatorAbsorcao = 1.0;

   double keepSupAnc = g_pivos[idxKeep].ancoraSup;
   double keepInfAnc = g_pivos[idxKeep].ancoraInf;
   double keepAltura = MathAbs(keepSupAnc - keepInfAnc);
   double alturaMinima = ObterAlturaMinimaZonaPreco();
   if(keepAltura < alturaMinima) keepAltura = alturaMinima;

   double dropSupRef = drop.ancoraInicializada ? drop.ancoraSup : drop.precoSuperior;
   double dropInfRef = drop.ancoraInicializada ? drop.ancoraInf : drop.precoInferior;
   double dropAltura = MathAbs(dropSupRef - dropInfRef);
   if(dropAltura < alturaMinima) dropAltura = alturaMinima;

   // Merge aumenta a zona sobrevivente em X% da zona absorvida, sem deslocar a âncora.
   double novaAltura = keepAltura + (dropAltura * fatorAbsorcao);
   if(novaAltura < alturaMinima) novaAltura = alturaMinima;

   double novoSup = keepSupAnc;
   double novoInf = keepInfAnc;
   if(keep.tipo == LINE_TOP) {
      double topoAncora = MathMax(keepSupAnc, keepInfAnc);
      novoSup = topoAncora;
      novoInf = topoAncora - novaAltura;
   } else {
      double fundoAncora = MathMin(keepSupAnc, keepInfAnc);
      novoInf = fundoAncora;
      novoSup = fundoAncora + novaAltura;
   }

   g_pivos[idxKeep].precoSuperior = novoSup;
   g_pivos[idxKeep].precoInferior = novoInf;
   g_pivos[idxKeep].preco = (keep.tipo == LINE_TOP) ? novoSup : novoInf;
   g_pivos[idxKeep].tempoInicio = g_pivos[idxKeep].ancoraTempoInicio;
   g_pivos[idxKeep].tipo = keep.tipo;
   g_pivos[idxKeep].tipoMajoritario = keep.tipoMajoritario;
   g_pivos[idxKeep].corAtual = ObterCorZona(keep.tipo);

   g_pivos[idxKeep].volumeTotal = keep.volumeTotal + drop.volumeTotal;
   g_pivos[idxKeep].volumeDistribuicao = keep.volumeDistribuicao + drop.volumeDistribuicao;
   double wKeepOrig = MathMax(1.0, keep.volumeDistribuicao);
   double wDropOrig = MathMax(1.0, drop.volumeDistribuicao);
   double wTotOrig = wKeepOrig + wDropOrig;
   if(wTotOrig <= 0.0) wTotOrig = 1.0;
   g_pivos[idxKeep].scoreOrigem = ((keep.scoreOrigem * wKeepOrig) + (drop.scoreOrigem * wDropOrig)) / wTotOrig;
   g_pivos[idxKeep].espessuraZona = ConverterScoreEmEspessura(g_pivos[idxKeep].scoreOrigem);
   g_pivos[idxKeep].quantidadeBarras = keep.quantidadeBarras + drop.quantidadeBarras;
   g_pivos[idxKeep].quantidadeTopos = keep.quantidadeTopos + drop.quantidadeTopos;
   g_pivos[idxKeep].quantidadeFundos = keep.quantidadeFundos + drop.quantidadeFundos;
   g_pivos[idxKeep].tempoMaisRecente = MathMax(MathMax(keep.tempoMaisRecente, drop.tempoMaisRecente), tempoEvento);
   g_pivos[idxKeep].ultimoTempoToqueContabilizado =
      MathMax(MathMax(keep.ultimoTempoToqueContabilizado, drop.ultimoTempoToqueContabilizado), tempoEvento);
   g_pivos[idxKeep].atr = (keep.atr + drop.atr) * 0.5;
   g_pivos[idxKeep].estado = PIVO_ATIVO;
   g_pivos[idxKeep].foiMergeada = true;
   g_pivos[idxKeep].ancoraInicializada = true;

   // Atualiza apenas a borda não-âncora para manter crescimento incremental sem desancorar.
   g_pivos[idxKeep].ancoraSup = novoSup;
   g_pivos[idxKeep].ancoraInf = novoInf;
   if(keep.tipo == LINE_TOP) g_pivos[idxKeep].ancoraPreco = novoSup;
   else g_pivos[idxKeep].ancoraPreco = novoInf;

   string idIncorp = (drop.pivoID > 0) ? IntegerToString(drop.pivoID) : "";
   if(StringLen(idIncorp) > 0) {
      if(StringLen(g_pivos[idxKeep].pivosIncorporados) > 0)
         g_pivos[idxKeep].pivosIncorporados += "," + idIncorp;
      else
         g_pivos[idxKeep].pivosIncorporados = idIncorp;
   }

   LimparSlotPivo(idxDrop);
   return true;
}

bool ExecutarMergeCorretivoOverflow(const double precoAtualRef,
                                    const datetime diaAtual,
                                    const datetime tempoEvento) {
   int idxDrop = -1;
   int idxKeep = -1;
   if(!SelecionarParMergeCorretivo(precoAtualRef, diaAtual, tempoEvento, idxDrop, idxKeep)) return false;
   return AbsorverZonaSemMoverAncora(idxKeep, idxDrop, tempoEvento);
}

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
   
   // Validar alvo e preparar faixa dinâmica (N-2..N+2).
   g_numeroZonasAlvo = InpNumeroPivos;
   if(g_numeroZonasAlvo < 2) g_numeroZonasAlvo = 2;
   if(g_numeroZonasAlvo > 20) g_numeroZonasAlvo = 20;
   int faixaExtra = ObterFaixaExtraZonas();
   g_numeroZonasMin = g_numeroZonasAlvo - faixaExtra;
   if(g_numeroZonasMin < 2) g_numeroZonasMin = 2;
   g_numeroZonasMax = g_numeroZonasAlvo + faixaExtra;
   if(g_numeroZonasMax > 20) g_numeroZonasMax = 20;

   // Capacidade operacional usa o teto da faixa, enquanto o alvo é usado para compactação.
   g_numeroZonas = g_numeroZonasMax;

   IndicatorSetString(INDICATOR_SHORTNAME,
                      StringFormat("Zonas alvo %d (faixa %d-%d, %d dias)",
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
      g_pivos[i].volumeDistribuicao = 0;
      g_pivos[i].scoreOrigem = 0.0;
      g_pivos[i].espessuraZona = 1;
      g_pivos[i].volumeMaximo = 0;
      g_pivos[i].percentualVolume = 0;
      g_pivos[i].ancoraInicializada = false;
   }
   
   g_volumeMaximoGlobal = 0.0;
   g_maximaRealInicializada = false;
   g_minimaRealInicializada = false;
   g_precoMaximaReal = 0.0;
   g_precoMinimaReal = 0.0;
   g_ultimoDiaOrganizado = 0;
   g_mergeCorretivoPendente = false;
   g_tempoCriacaoOverflow = 0;
   g_extremoMaxDiaAtual = 0.0;
   g_extremoMinDiaAtual = 0.0;
   g_extremoMaxDiaAnterior = 0.0;
   g_extremoMinDiaAnterior = 0.0;
   g_referenciaDiaAtual = 0;
   g_referenciaDiaAnterior = 0;
   
   Print("════════════════════════════════════════");
   Print("  Alvo ", g_numeroZonasAlvo, " zonas | Faixa dinâmica ", g_numeroZonasMin, "..", g_numeroZonasMax, " com PROGRESS BAR v14.0");
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
//| Determinar intensidade do volume                                |
//+------------------------------------------------------------------+
ENUM_VOLUME_INTENSIDADE DeterminarIntensidadeVolume(double volume, double volumeMedia) {
   double ratio = volume / volumeMedia;

   double limiarMedio = 1.5;
   double limiarAlto = 2.0;
   double limiarExtremo = 3.0;
   ObterLimiaresIntensidadeVolume(limiarMedio, limiarAlto, limiarExtremo);

   if(ratio >= limiarExtremo) return VOLUME_EXTREMO;
   else if(ratio >= limiarAlto) return VOLUME_ALTO;
   else if(ratio >= limiarMedio) return VOLUME_MEDIO;
   else return VOLUME_BAIXO;                    // Abaixo de 150%
}

//+------------------------------------------------------------------+
//| Verificar se a barra toca/vara a faixa de preço                 |
//+------------------------------------------------------------------+
bool BarraInterseccionaFaixa(double barraHigh, double barraLow, double faixaSuperior, double faixaInferior) {
   double sup = faixaSuperior;
   double inf = faixaInferior;
   if(sup < inf) {
      double t = sup;
      sup = inf;
      inf = t;
   }
   return !(barraHigh < inf || barraLow > sup);
}

//+------------------------------------------------------------------+
//| Calcular percentuais de volume para progress bars               |
//+------------------------------------------------------------------+
void CalcularPercentuaisVolume() {
   g_volumeMaximoGlobal = 0.0;
   double volumePonderado[20];
   for(int i = 0; i < 20; i++) volumePonderado[i] = 0.0;

   double maxVolDiaAtual = 0.0;
   double maxVolDiaAnterior = 0.0;
   double eps = 1e-9;

   datetime diaAtual = g_referenciaDiaAtual;
   datetime diaAnterior = g_referenciaDiaAnterior;
   if(diaAtual <= 0) {
      diaAtual = ObterInicioDia(TimeCurrent());
      diaAnterior = diaAtual - 86400;
   }

   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   int janelaBarras = ObterJanelaInicioDiaBarras();
   datetime limiteInicioDia = diaAtual + (datetime)(passo * janelaBarras);
   bool inicioDoDia = (janelaBarras > 0 && TimeCurrent() <= limiteInicioDia);

   // 1) Descobrir maximos de volume de distribuicao por dia (atual/anterior).
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

      datetime diaZona = ObterInicioDia(g_pivos[i].tempoInicio);
      if(diaZona != diaAtual && diaZona != diaAnterior) continue;

      double volBase = InpDistribuicaoSomentePico ? g_pivos[i].volumeDistribuicao
                                                  : MathMax(g_pivos[i].volumeDistribuicao, g_pivos[i].volumeTotal);
      if(volBase < 0.0) volBase = 0.0;
      if(diaZona == diaAtual && volBase > maxVolDiaAtual) maxVolDiaAtual = volBase;
      if(diaZona == diaAnterior && volBase > maxVolDiaAnterior) maxVolDiaAnterior = volBase;
   }

   // 2) Calcular volume ponderado com regras diarias e estado da zona.
   double pesoMaxAnterior = ObterPesoMaxVolDiaAnterior();
   double pesoMaxAtual = ObterPesoMaxVolDiaAtual();
   double pesoExtremosDia = ObterPesoExtremosDia();
   double redutorZonaVencida = ObterRedutorZonaVencida();

   double faixaAtual = MathAbs(g_extremoMaxDiaAtual - g_extremoMinDiaAtual);
   double faixaAnterior = MathAbs(g_extremoMaxDiaAnterior - g_extremoMinDiaAnterior);
   double tolAtual = MathMax(_Point * 10.0, faixaAtual * 0.05);
   double tolAnterior = MathMax(_Point * 10.0, faixaAnterior * 0.05);

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

      datetime diaZona = ObterInicioDia(g_pivos[i].tempoInicio);
      double volBase = InpDistribuicaoSomentePico ? g_pivos[i].volumeDistribuicao
                                                  : MathMax(g_pivos[i].volumeDistribuicao, g_pivos[i].volumeTotal);
      if(volBase < 0.0) volBase = 0.0;

      // Regra principal: distribuicao considera apenas dia atual e anterior.
      if(diaZona != diaAtual && diaZona != diaAnterior) volBase = 0.0;

      double peso = 1.0;
      if(volBase > 0.0) {
         if(diaZona == diaAtual && maxVolDiaAtual > eps && volBase >= (maxVolDiaAtual - eps)) {
            peso *= pesoMaxAtual;
         }
         if(diaZona == diaAnterior && maxVolDiaAnterior > eps && volBase >= (maxVolDiaAnterior - eps)) {
            if(inicioDoDia) peso *= pesoMaxAnterior;
            else peso *= pesoMaxAtual;
         }

         double precoZona = g_pivos[i].preco;
         bool pertoExtremoAtual =
            (g_extremoMaxDiaAtual > 0.0 && MathAbs(precoZona - g_extremoMaxDiaAtual) <= tolAtual) ||
            (g_extremoMinDiaAtual > 0.0 && MathAbs(precoZona - g_extremoMinDiaAtual) <= tolAtual);
         bool pertoExtremoAnterior =
            (g_extremoMaxDiaAnterior > 0.0 && MathAbs(precoZona - g_extremoMaxDiaAnterior) <= tolAnterior) ||
            (g_extremoMinDiaAnterior > 0.0 && MathAbs(precoZona - g_extremoMinDiaAnterior) <= tolAnterior);
         if(pertoExtremoAtual || pertoExtremoAnterior) {
            peso *= pesoExtremosDia;
         }
      }

      if(g_pivos[i].estado == PIVO_CONFIRMADO || g_pivos[i].precoAssentado) {
         peso *= redutorZonaVencida;
      }

      volumePonderado[i] = volBase * peso;
      if(volumePonderado[i] > g_volumeMaximoGlobal) {
         g_volumeMaximoGlobal = volumePonderado[i];
      }
   }

   // 3) Converter para percentual (0..100) no universo ativo.
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      g_pivos[i].volumeMaximo = g_volumeMaximoGlobal;
      if(g_volumeMaximoGlobal > 0.0) {
         g_pivos[i].percentualVolume = (volumePonderado[i] / g_volumeMaximoGlobal) * 100.0;
      } else g_pivos[i].percentualVolume = 0.0;
   }

   if(InpLogDetalhado) {
      Print("📊 Distribuicao diária: maxAtual=", DoubleToString(maxVolDiaAtual, 0),
            " | maxAnterior=", DoubleToString(maxVolDiaAnterior, 0),
            " | maxGlobal=", DoubleToString(g_volumeMaximoGlobal, 0));
   }
}

ENUM_LINE_TYPE ObterTipoVisualZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return LINE_TOP;
   return g_pivos[idx].tipo;
}

//+------------------------------------------------------------------+
//| Criar progress bar dentro da zona                               |
//+------------------------------------------------------------------+
void CriarProgressBar(int pivoIndex, datetime tempoInicio, datetime tempoFim, double precoSuperior, double precoInferior) {
   string nomeProgressBar = g_prefixo + "Progress_" + IntegerToString(pivoIndex);
   // Progress bar removida por pedido do usuário.
   if(ObjectFind(g_chartID, nomeProgressBar) >= 0) ObjectDelete(g_chartID, nomeProgressBar);
}

void RemoverProgressBarsResiduais() {
   int total = ObjectsTotal(g_chartID);
   string token = g_prefixo + "Progress_";
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, token) == 0) {
         ObjectDelete(g_chartID, nome);
      }
   }
}

void RemoverObjetosOrfaosV4() {
   int total = ObjectsTotal(g_chartID);
   string tokenPivo = g_prefixo + "Pivo_";
   string nomeLinhaMax = g_prefixo + "LinhaMaiorMaxima";
   string nomeLinhaMin = g_prefixo + "LinhaMenorMinima";
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, g_prefixo) != 0) continue;

      if(nome == nomeLinhaMax || nome == nomeLinhaMin) continue;

      if(StringFind(nome, tokenPivo) == 0) {
         string resto = StringSubstr(nome, StringLen(tokenPivo));
         int posUnd = StringFind(resto, "_");
         string numero = (posUnd >= 0) ? StringSubstr(resto, 0, posUnd) : resto;
         if(StringLen(numero) <= 0) {
            ObjectDelete(g_chartID, nome);
            continue;
         }

         int idx = (int)StringToInteger(numero);
         bool invalido = (idx < 0 || idx >= g_numeroZonas);
         if(!invalido && g_pivos[idx].estado == PIVO_REMOVIDO) invalido = true;

         if(posUnd >= 0) {
            string sufixo = StringSubstr(resto, posUnd);
            if(sufixo != "_Text") invalido = true;
         }

         if(invalido) {
            ObjectDelete(g_chartID, nome);
         }
         continue;
      }

      // Remove qualquer objeto legado deste prefixo (ex.: barras antigas).
      ObjectDelete(g_chartID, nome);
   }
}

//+------------------------------------------------------------------+
//| Obter cor baseada na intensidade do volume                     |
//+------------------------------------------------------------------+
color ObterCorPorVolume(ENUM_VOLUME_INTENSIDADE intensidade) {
   switch(intensidade) {
      case VOLUME_EXTREMO: return g_palCorVolExtremo;  // Volume extremo
      case VOLUME_ALTO:    return g_palCorVolAlto;     // Volume alto
      case VOLUME_MEDIO:   return g_palCorVolMedio;    // Volume médio
      case VOLUME_BAIXO:   
      default:             return g_palCorVolBaixo;    // Volume baixo
   }
}

//+------------------------------------------------------------------+
//| Cor elegante por tipo de zona                                   |
//+------------------------------------------------------------------+
color ObterCorZona(ENUM_LINE_TYPE tipo) {
   if(tipo == LINE_TOP) return g_palCorResistencia;
   return g_palCorSuporte;
}

//+------------------------------------------------------------------+
//| Atualizar coordenadas dos pivôs                                 |
//+------------------------------------------------------------------+
void AtualizarCoordenadasPivos(int rates_total, const datetime &time[]) {
   if(!g_pivosInicializados || rates_total < 1) return;
   
   // Verificação de segurança para o array time
   if(rates_total > ArraySize(time)) {
      Print("⚠️ rates_total maior que array time: ", rates_total, " > ", ArraySize(time));
      return;
   }
   
   datetime tempoAtual = time[rates_total - 1];
   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   datetime tempoFim = tempoAtual;
   if(DeveDesenharZonaAteRecuo()) {
      tempoFim = tempoAtual + (datetime)(passo * ObterExtensaoTemporalCoordenada());
   }
   
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      
      string nomeObj = g_prefixo + "Pivo_" + IntegerToString(i);
      
      if(ObjectFind(g_chartID, nomeObj) >= 0) {
         // ATUALIZAR apenas a coordenada temporal final para manter pivô visível
         ObjectSetInteger(g_chartID, nomeObj, OBJPROP_TIME, 1, tempoFim);
      }
   }
}

//+------------------------------------------------------------------+
//| Verificar rompimentos com ANTI PISCA-PISCA                     |
//+------------------------------------------------------------------+
bool VerificarRompimentosEAssentamento(int rates_total, const double &close[]) {
   if(rates_total < 2 || !g_pivosInicializados) return false;
   
   // Verificação de segurança para o array close
   if(rates_total > ArraySize(close)) {
      Print("⚠️ rates_total maior que array close: ", rates_total, " > ", ArraySize(close));
      return false;
   }
   
   double precoAtual = close[rates_total - 1];
   bool houveMudanca = false;
   
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      
      // Verificar se foi rompido
      bool foiRompido = false;
      if(g_pivos[i].tipo == LINE_TOP && precoAtual > g_pivos[i].preco) {
         foiRompido = true;
      } else if(g_pivos[i].tipo == LINE_BOTTOM && precoAtual < g_pivos[i].preco) {
         foiRompido = true;
      }
      
      if(foiRompido && g_pivos[i].estado == PIVO_ATIVO) {
         g_pivos[i].estado = PIVO_ROMPIDO;
         g_pivos[i].barraRompimento = rates_total - 1;
         g_pivos[i].barrasAposRompimento = 0;
         g_pivos[i].precoAssentado = false;
         // Mantém cor estável por tipo da zona (evita troca visual sem critério).
         g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
         houveMudanca = true;
         Print("🔸 Pivô ", i+1, " rompido: ", g_pivos[i].preco, " - Aguardando assentamento");
      }
      
      // ANTI PISCA-PISCA: Contar barras após rompimento
      if(g_pivos[i].estado == PIVO_ROMPIDO) {
         g_pivos[i].barrasAposRompimento++;
         
         // Verificar se preço está realmente "assentado" na nova região
         bool precoEstabilizado = false;
         if(g_pivos[i].tipo == LINE_TOP) {
            // Para resistência rompida: preço deve permanecer ACIMA
            precoEstabilizado = (precoAtual > g_pivos[i].precoSuperior);
         } else {
            // Para suporte rompido: preço deve permanecer ABAIXO
            precoEstabilizado = (precoAtual < g_pivos[i].precoInferior);
         }
         
         // SÓ MUDA COR após tempo de assentamento E preço estabilizado
         if(g_pivos[i].barrasAposRompimento >= InpTempoAssentamento && precoEstabilizado) {
            g_pivos[i].estado = PIVO_CONFIRMADO;
            g_pivos[i].precoAssentado = true;
            
            // Volta para a cor elegante por tipo (suporte/resistência).
            g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
            houveMudanca = true;
            
            Print("✅ Pivô ", i+1, " confirmado após assentamento: ", g_pivos[i].preco);
         } else if(g_pivos[i].barrasAposRompimento >= InpTempoAssentamento && !precoEstabilizado) {
            // Falso rompimento, voltar ao normal
            g_pivos[i].estado = PIVO_ATIVO;
            g_pivos[i].barrasAposRompimento = 0;
            g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
            houveMudanca = true;
            
            Print("🔄 Pivô ", i+1, " - falso rompimento, voltando ao normal: ", g_pivos[i].preco);
         }
      }
   }
   return houveMudanca;
}

//+------------------------------------------------------------------+
//| Calcular ATR                                                     |
//+------------------------------------------------------------------+
double CalcularATR(int barra, const double &high[], const double &low[], const double &close[]) {
   int periodo = ObterPeriodoATR();
   int arraySize = ArraySize(high);
   
   // Verificações de segurança
   if(barra < 0 || barra >= arraySize) {
      Print("⚠️ Índice inválido em CalcularATR: ", barra, " / ", arraySize);
      return ObterAtrFallbackEmErro(); // Valor padrão para evitar divisão por zero
   }
   
   if(barra < periodo) {
      return (high[barra] - low[barra]); // ATR simples se não há histórico suficiente
   }
   
   double soma = 0;
   for(int i = 0; i < periodo; i++) {
      int index = barra - i;
      
      // Verificação de limite para cada acesso ao array
      if(index < 0 || index >= arraySize) continue;
      
      double tr1 = high[index] - low[index];
      double tr2 = (index > 0 && index-1 >= 0) ? MathAbs(high[index] - close[index - 1]) : 0;
      double tr3 = (index > 0 && index-1 >= 0) ? MathAbs(low[index] - close[index - 1]) : 0;
      double tr = MathMax(tr1, MathMax(tr2, tr3));
      soma += tr;
   }
   
   return soma / periodo;
}

//+------------------------------------------------------------------+
//| Distância média usando pivôs do ZigZag importado                |
//+------------------------------------------------------------------+
double CalcularDistanciaMediaPivosZigZagImportado(const int rates_total,
                                                  const int idxRef,
                                                  const datetime &time[]) {
   if(g_zigzagHandle == INVALID_HANDLE) return 0.0;
   if(rates_total < 3 || idxRef <= 0 || idxRef >= rates_total) return 0.0;

   int maxBarras = InpZigZagMaxBarras;
   int minBarras = ObterMinBarrasZigZagMedia();
   if(maxBarras < minBarras) maxBarras = minBarras;

   datetime diaRef = time[idxRef] - (time[idxRef] % 86400);
   int inicio = idxRef;
   int cont = 0;
   while(inicio > 0 && cont < maxBarras) {
      datetime diaPrev = time[inicio - 1] - (time[inicio - 1] % 86400);
      if(diaPrev != diaRef) break;
      inicio--;
      cont++;
   }

   double pivPrices[];
   int n = 0;
   double ultimoValido = EMPTY_VALUE;

   for(int i = inicio; i <= idxRef; i++) {
      int shift = idxRef - i;
      double zz1[];
      ArrayResize(zz1, 1);
      int copiados = CopyBuffer(g_zigzagHandle, 0, shift, 1, zz1);
      if(copiados != 1) continue;

      double valor = zz1[0];
      if(valor == EMPTY_VALUE || valor == 0.0) continue;

      // Evita duplicidade quando o mesmo pivô reaparece no mesmo nível.
      if(ultimoValido != EMPTY_VALUE &&
         MathAbs(valor - ultimoValido) <= ObterToleranciaDuplicidadePivotPreco())
         continue;

      ArrayResize(pivPrices, n + 1);
      pivPrices[n] = valor;
      n++;
      ultimoValido = valor;
   }

   if(n < 2) return 0.0;

   double somaDist = 0.0;
   int qtdDist = 0;
   for(int k = 1; k < n; k++) {
      somaDist += MathAbs(pivPrices[k] - pivPrices[k - 1]);
      qtdDist++;
   }
   if(qtdDist <= 0) return 0.0;

   double mediaDist = somaDist / qtdDist;
   mediaDist *= InpDistMinFatorZigZag;
   if(mediaDist <= 0.0) return 0.0;
   return mediaDist;
}

ENUM_LINE_TYPE DeterminarTipoPorPosicaoNoDia(const int barra, const double &high[], const double &low[]) {
   int arraySize = ArraySize(high);
   if(barra < 0 || barra >= arraySize) return LINE_TOP;

   double topoDia = g_extremoMaxDiaAtual;
   double fundoDia = g_extremoMinDiaAtual;
   if(!(topoDia > fundoDia)) {
      topoDia = g_extremoMaxDiaAnterior;
      fundoDia = g_extremoMinDiaAnterior;
   }

   double meioBarra = (high[barra] + low[barra]) * 0.5;
   if(topoDia > fundoDia) {
      double pos = (meioBarra - fundoDia) / (topoDia - fundoDia);
      if(pos <= 0.45) return LINE_BOTTOM;
      if(pos >= 0.55) return LINE_TOP;
   }

   // Desempate no miolo da faixa diária.
   double sombraSup = high[barra] - meioBarra;
   double sombraInf = meioBarra - low[barra];
   if(sombraInf > sombraSup) return LINE_BOTTOM;
   return LINE_TOP;
}

//+------------------------------------------------------------------+
//| Determinar tipo de linha                                        |
//+------------------------------------------------------------------+
ENUM_LINE_TYPE DeterminarTipoLinha(int barra, const double &high[], const double &low[]) {
   int arraySize = ArraySize(high);
   int vizinhanca = ObterVizinhancaPivot();
   
   // Verificações de segurança
   if(barra < 0 || barra >= arraySize) {
      Print("⚠️ Índice inválido em DeterminarTipoLinha: ", barra, " / ", arraySize);
      return LINE_TOP; // Default seguro
   }
   
   if(barra < vizinhanca || barra >= arraySize - vizinhanca)
      return DeterminarTipoPorPosicaoNoDia(barra, high, low);
   
   // Verificar se é topo
   bool ehTopo = true;
   for(int j = 1; j <= vizinhanca; j++) {
      int indexAntes = barra - j;
      int indexDepois = barra + j;
      
      // Verificar limites antes de acessar
      if(indexAntes < 0 || indexAntes >= arraySize || 
         indexDepois < 0 || indexDepois >= arraySize) {
         ehTopo = false;
         break;
      }
      
      if(high[barra] <= high[indexAntes] || high[barra] <= high[indexDepois]) {
         ehTopo = false;
         break;
      }
   }
   
   if(ehTopo) return LINE_TOP;
   
   // Verificar se é fundo
   bool ehFundo = true;
   for(int j = 1; j <= vizinhanca; j++) {
      int indexAntes = barra - j;
      int indexDepois = barra + j;
      
      // Verificar limites antes de acessar
      if(indexAntes < 0 || indexAntes >= arraySize || 
         indexDepois < 0 || indexDepois >= arraySize) {
         ehFundo = false;
         break;
      }
      
      if(low[barra] >= low[indexAntes] || low[barra] >= low[indexDepois]) {
         ehFundo = false;
         break;
      }
   }
   
   if(ehFundo) return LINE_BOTTOM;
   
   // Se não é nem topo nem fundo claro, usar posição relativa no dia.
   return DeterminarTipoPorPosicaoNoDia(barra, high, low);
}

//+------------------------------------------------------------------+
//| Desenhar os pivôs com PROGRESS BARS no gráfico                 |
//+------------------------------------------------------------------+
void DesenharPivos(int rates_total, const datetime &time[]) {
   if(!g_pivosInicializados || rates_total < 1) return;
   
   // Verificação de segurança para o array time
   if(rates_total > ArraySize(time)) {
      Print("⚠️ rates_total maior que array time em DesenharPivos: ", rates_total, " > ", ArraySize(time));
      return;
   }
   
   datetime tempoBarraZero = time[rates_total - 1];
   datetime tempoFim = tempoBarraZero;
   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   if(DeveDesenharZonaAteRecuo()) {
      tempoFim = tempoBarraZero + (datetime)(passo * ObterExtensaoTemporalZona());
   }
   int pivosDesenhados = 0;

   // Segurança: remove qualquer progress bar residual de versões anteriores.
   RemoverProgressBarsResiduais();
   // Segurança: remove retângulos/textos órfãos que geram "tiras flutuantes".
   RemoverObjetosOrfaosV4();
   
   for(int i = 0; i < g_numeroZonas; i++) {
      string nomeObj = g_prefixo + "Pivo_" + IntegerToString(i);
      string nomeTexto = nomeObj + "_Text";
      string nomeProgress = g_prefixo + "Progress_" + IntegerToString(i);

      if(g_pivos[i].estado == PIVO_REMOVIDO) {
         if(ObjectFind(g_chartID, nomeObj) >= 0) ObjectDelete(g_chartID, nomeObj);
         if(ObjectFind(g_chartID, nomeTexto) >= 0) ObjectDelete(g_chartID, nomeTexto);
         if(ObjectFind(g_chartID, nomeProgress) >= 0) ObjectDelete(g_chartID, nomeProgress);
         continue;
      }
      
      // Regra visual fixa por posição diária: acima = vermelho, abaixo = azul.
      ENUM_LINE_TYPE tipoVisual = ObterTipoVisualZona(i);
      g_pivos[i].corAtual = ObterCorZona(tipoVisual);

      // 1) Zona: criar uma vez, atualizar sempre (sem delete/create por tick)
      if(ObjectFind(g_chartID, nomeObj) < 0) {
         ObjectCreate(g_chartID, nomeObj, OBJ_RECTANGLE, 0,
                      g_pivos[i].tempoInicio, g_pivos[i].precoSuperior,
                      tempoFim, g_pivos[i].precoInferior);
      }
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_TIME, 0, g_pivos[i].tempoInicio);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_TIME, 1, tempoFim);
      ObjectSetDouble(g_chartID, nomeObj, OBJPROP_PRICE, 0, g_pivos[i].precoSuperior);
      ObjectSetDouble(g_chartID, nomeObj, OBJPROP_PRICE, 1, g_pivos[i].precoInferior);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_COLOR, g_pivos[i].corAtual);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_STYLE, STYLE_SOLID);
      bool origemVolAlto = (g_pivos[i].volumeDistribuicao > 0.0);
      int larguraZona = g_pivos[i].espessuraZona;
      if(larguraZona < 1) larguraZona = ConverterScoreEmEspessura(g_pivos[i].scoreOrigem);
      if(larguraZona < 1) larguraZona = 1;
      if(larguraZona > 10) larguraZona = 10;
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_WIDTH, larguraZona);
      bool preencherZona = true;
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_FILL, preencherZona);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BACK, true);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_SELECTABLE, false);

      if(preencherZona) {
         uint alpha = (uint)InpTransparenciaZonas;
         if(alpha > 255) alpha = 255;
         color corComTransparencia = (color)((g_pivos[i].corAtual & 0x00FFFFFF) | (alpha << 24));
         ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BGCOLOR, corComTransparencia);
      } else {
         ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BGCOLOR, g_pivos[i].corAtual);
      }
      string tipoZona = (tipoVisual == LINE_TOP) ? "Venda" : "Compra";
      string estadoZona = (g_pivos[i].estado == PIVO_CONFIRMADO || g_pivos[i].precoAssentado) ? "Vencida" : "Ativa";
      ObjectSetString(g_chartID, nomeObj, OBJPROP_TOOLTIP,
                      StringFormat("%s | %s | Pct: %.1f%% | VolDist: %.0f | Origem: %s",
                                   tipoZona,
                                   estadoZona,
                                   g_pivos[i].percentualVolume,
                                   g_pivos[i].volumeDistribuicao,
                                   (origemVolAlto ? "VOL_ALTO" : "NORMAL")));
      pivosDesenhados++;

      // 2) Progress bar removida.
      if(ObjectFind(g_chartID, nomeProgress) >= 0) ObjectDelete(g_chartID, nomeProgress);

      // Percentual simples (sem barra de progresso).
      if(InpMostrarVolumeTexto) {
         double precoTexto = (MathMax(g_pivos[i].precoSuperior, g_pivos[i].precoInferior) +
                              MathMin(g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) * 0.5;
         string textoPct = StringFormat("%.0f%%", g_pivos[i].percentualVolume);
         if(ObjectFind(g_chartID, nomeTexto) < 0) {
            ObjectCreate(g_chartID, nomeTexto, OBJ_TEXT, 0, tempoFim, precoTexto);
         }
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_TIME, 0, tempoFim);
         ObjectSetDouble(g_chartID, nomeTexto, OBJPROP_PRICE, 0, precoTexto);
         ObjectSetString(g_chartID, nomeTexto, OBJPROP_TEXT, textoPct);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_COLOR, g_pivos[i].corAtual);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_FONTSIZE, ObterTamanhoFonteTextoZona());
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_BACK, false);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_HIDDEN, true);
      } else if(ObjectFind(g_chartID, nomeTexto) >= 0) {
         ObjectDelete(g_chartID, nomeTexto);
      }
   }
   
   string info = StringFormat("📊 %d zonas ativas (alvo %d | faixa %d-%d) | Volume Máximo: %.0f",
                             pivosDesenhados,
                             g_numeroZonasAlvo,
                             g_numeroZonasMin,
                             g_numeroZonasMax,
                             g_volumeMaximoGlobal);
   if(info != g_ultimoCommentInfo) {
      Comment(info);
      g_ultimoCommentInfo = info;
   }
   ChartRedraw(g_chartID);
}

//+------------------------------------------------------------------+
//| Limpar objetos dos pivôs                                        |
//+------------------------------------------------------------------+
void LimparProfile() {
   for(int i = 0; i < 20; i++) {
      string nomePivo = g_prefixo + "Pivo_" + IntegerToString(i);
      string nomeTexto = nomePivo + "_Text";
      string nomeProgress = g_prefixo + "Progress_" + IntegerToString(i);
      
      if(ObjectFind(g_chartID, nomePivo) >= 0) {
         ObjectDelete(g_chartID, nomePivo);
      }
      
      if(ObjectFind(g_chartID, nomeTexto) >= 0) {
         ObjectDelete(g_chartID, nomeTexto);
      }
      
      if(ObjectFind(g_chartID, nomeProgress) >= 0) {
         ObjectDelete(g_chartID, nomeProgress);
      }
   }
   
   ChartRedraw(g_chartID);
}

//+------------------------------------------------------------------+
//| Limpar todos os objetos                                         |
//+------------------------------------------------------------------+
void LimparObjetos() {
   int total = ObjectsTotal(g_chartID);
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, g_prefixo) == 0) {
         ObjectDelete(g_chartID, nome);
      }
   }
   
   ChartRedraw(g_chartID);
}

#include "SupDemVol_ModuleCentral_v4.mqh"

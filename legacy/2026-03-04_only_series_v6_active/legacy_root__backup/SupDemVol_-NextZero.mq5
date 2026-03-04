//+------------------------------------------------------------------+
//|                                    VolumeProfile_HighVolumeOnly.mq5 |
//|                       Volume Profile - 7 Zonas Dinâmicas        |
//+------------------------------------------------------------------+
#property copyright "Volume Profile - 7 Zonas Dinâmicas"
#property version   "14.01"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3

// Plot do histograma de volume
#property indicator_label1  "Volume"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  C'120,127,140', C'92,106,130', C'130,95,80'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

// Plot da banda superior
#property indicator_label2  "Banda Superior"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'92,106,130'
#property indicator_style2  STYLE_DASH
#property indicator_width2  2

// Plot da linha zero
#property indicator_label3  "Zero"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkGray
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
input bool     InpPintarBarrasPreco = true;         // Pintar Barras de Preço quando Volume Alto
input color    InpCorBarraAltoVolume = C'142,108,88';  // Cor das Barras de Preço com Volume Alto
input ENUM_PALETA_PREMIUM InpPaletaVisual = PALETA_PREMIUM_ATRATO;
input bool     InpUsarPaletaPremium = true;         // Ignora cor manual e usa tema premium selecionado

// Parâmetros dos Pivôs
input string   InpSeparador1 = "═══ PIVÔS DINÂMICOS ═══";           // ═══════════════════════
input bool     InpMostrarProfile = true;            // Mostrar os Pivôs
input int      InpNumeroPivos = 7;                  // Número de Pivôs (máximo 20)
input double   InpMaxATRPercent = 35.0;             // Máximo % do ATR para ALTURA do pivô
input string   InpSeparadorMerge = "═══ REGRAS DE MERGE SEGURAS ═══";
input double   InpMergeATRPercent = 80.0;           // % do ATR para MERGE automático de pivôs próximos
input double   InpDistanciaMinATR = 50.0;           // Distância mínima entre pivôs (% do ATR)  
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
input color    InpCorVolumeBaixo = C'120,127,140';   // Cor para Volume Baixo (ardosia fria)
input color    InpCorVolumeMedio = C'92,106,130';    // Cor para Volume Médio (azul aco)
input color    InpCorVolumeAlto = C'163,126,102';    // Cor para Volume Alto (cobre fosco)
input color    InpCorVolumeExtremo = C'130,95,80';   // Cor para Volume Extremo (argila escura)
input color    InpCorZonaSuporte = C'70,102,145';    // Azul profundo (suporte)
input color    InpCorZonaResistencia = C'162,112,86'; // Bronze quente (resistência)
input color    InpCorRompido = C'122,126,133';       // Cor neutra para pivô rompido (temporário)
input color    InpCorProgressBar = C'95,113,146';    // Cor da barra de progresso do volume (neutra)
input int      InpLarguraLinhas = 2;                // Largura das Linhas
input int      InpTransparenciaZonas = 120;         // Transparência das Zonas (0-255)
input int      InpTransparenciaProgress = 80;       // Transparência da Progress Bar (0-255)
input bool     InpMostrarVolumeTexto = true;        // Mostrar Volume como Texto
input bool     InpMostrarProgressBar = true;        // Mostrar Progress Bar de Volume
input bool     InpExibirPainelVolume = true;        // Exibir painel de volume (histograma/banda/zero) ao carregar
input bool     InpAtualizarUIApenasBarraNova = true; // Reduz pisca-pisca: atualiza UI só em barra nova/mudança
input bool     InpLogDetalhado = false;             // Log detalhado (pode deixar lento/ruidoso)

// Buffers
double VolumeBuffer[];
double VolumeColorBuffer[];
double BandaSuperiorBuffer[];
double ZeroBuffer[];
double MediaBuffer[];

// Variáveis globais
string g_prefixo = "VProfile7_";
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

// Paleta runtime (tema visual premium escolhido no input).
color g_palCorSuporte = C'70,102,145';
color g_palCorResistencia = C'162,112,86';
color g_palCorRompido = C'122,126,133';
color g_palCorProgress = C'95,113,146';
color g_palCorVolBaixo = C'120,127,140';
color g_palCorVolMedio = C'92,106,130';
color g_palCorVolAlto = C'163,126,102';
color g_palCorVolExtremo = C'130,95,80';

void AplicarPaletaVisual() {
   if(!InpUsarPaletaPremium) {
      g_palCorSuporte = InpCorZonaSuporte;
      g_palCorResistencia = InpCorZonaResistencia;
      g_palCorRompido = InpCorRompido;
      g_palCorProgress = InpCorProgressBar;
      g_palCorVolBaixo = InpCorVolumeBaixo;
      g_palCorVolMedio = InpCorVolumeMedio;
      g_palCorVolAlto = InpCorVolumeAlto;
      g_palCorVolExtremo = InpCorVolumeExtremo;
      return;
   }

   switch(InpPaletaVisual) {
      case PALETA_PREMIUM_SOMBRA:
         g_palCorSuporte = C'78,104,132';
         g_palCorResistencia = C'138,107,88';
         g_palCorRompido = C'122,126,133';
         g_palCorProgress = C'96,116,143';
         g_palCorVolBaixo = C'119,126,136';
         g_palCorVolMedio = C'90,104,124';
         g_palCorVolAlto = C'154,121,100';
         g_palCorVolExtremo = C'126,96,82';
         break;

      case PALETA_PREMIUM_COBRE:
         g_palCorSuporte = C'74,98,138';
         g_palCorResistencia = C'170,116,86';
         g_palCorRompido = C'122,126,133';
         g_palCorProgress = C'92,111,143';
         g_palCorVolBaixo = C'124,129,138';
         g_palCorVolMedio = C'95,106,126';
         g_palCorVolAlto = C'170,126,97';
         g_palCorVolExtremo = C'136,96,76';
         break;

      case PALETA_PREMIUM_ATRATO:
      default:
         g_palCorSuporte = C'70,102,145';
         g_palCorResistencia = C'162,112,86';
         g_palCorRompido = C'122,126,133';
         g_palCorProgress = C'95,113,146';
         g_palCorVolBaixo = C'120,127,140';
         g_palCorVolMedio = C'92,106,130';
         g_palCorVolAlto = C'163,126,102';
         g_palCorVolExtremo = C'130,95,80';
         break;
   }
}

// Estrutura para os pivôs ativos
struct PivoAtivo {
   double preco;
   double precoSuperior;
   double precoInferior;
   datetime tempoInicio;
   datetime tempoMaisRecente;
   double volumeTotal;
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

// Regras de merge (módulo dedicado).
#include "SupDemVol_MergeRules.mqh"

int ContarZonasAtivas() {
   int total = 0;
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado != PIVO_REMOVIDO) total++;
   }
   return total;
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

bool ZonaRecemCriadaProtegida(const int idx, const datetime tempoEvento, const int barrasProtecao = 1) {
   if(idx < 0 || idx >= g_numeroZonas) return false;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return false;
   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   datetime limite = tempoEvento - (datetime)(passo * barrasProtecao);
   return (g_pivos[idx].tempoInicio >= limite);
}

int ClassificarBucketPreco(const double preco, const double precoMin, const double precoMax) {
   double amplitude = precoMax - precoMin;
   if(amplitude <= (_Point * 10.0)) return 1; // Tudo no miolo quando a faixa for muito estreita.

   double tercil = amplitude / 3.0;
   double limiteInferior = precoMin + tercil;
   double limiteSuperior = precoMin + (tercil * 2.0);

   if(preco <= limiteInferior) return 0; // inferior
   if(preco >= limiteSuperior) return 2; // superior
   return 1; // meio
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
   if(maxDistPreco <= 0.0) maxDistPreco = _Point * 10.0;

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

   if(maxDistEntreZonas <= 0.0) maxDistEntreZonas = _Point * 10.0;

   double melhorScore = -DBL_MAX;
   int bucketDrop = 1;
   datetime melhorDia = 0;
   double melhorDistPreco = 0.0;
   double melhorVol = DBL_MAX;
   bool encontrouElegivel = false;

   for(int a = 0; a < nAtivos; a++) {
      int idx = ativos[a];
      if(ZonaRecemCriadaProtegida(idx, tempoEvento, 1)) continue; // Não apagar zona recém-criada.

      double scoreProximidade = 1.0 - MathMin(1.0, menorDist[a] / maxDistEntreZonas);
      double scoreDistanciaPreco = MathMin(1.0, MathAbs(g_pivos[idx].preco - precoAtualRef) / maxDistPreco);
      double scoreBaixoVolume = 1.0 - MathMin(1.0, g_pivos[idx].volumeTotal / maxVolume);

      datetime diaZona = g_pivos[idx].tempoInicio - (g_pivos[idx].tempoInicio % 86400);
      double scoreAntiguidade = (diaZona < diaAtual) ? 1.0 : 0.0;

      // Priorização pedida: proximidade de outra zona + distância do preço + baixo volume + legado do dia anterior.
      double score = (scoreProximidade * 0.35) +
                     (scoreDistanciaPreco * 0.25) +
                     (scoreBaixoVolume * 0.25) +
                     (scoreAntiguidade * 0.15);

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
   if(idxKeep < 0 || idxKeep >= g_numeroZonas) return false;
   if(idxDrop < 0 || idxDrop >= g_numeroZonas) return false;
   if(idxKeep == idxDrop) return false;
   if(g_pivos[idxKeep].estado == PIVO_REMOVIDO) return false;
   if(g_pivos[idxDrop].estado == PIVO_REMOVIDO) return false;

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
   if(keepAltura < (_Point * 2.0)) keepAltura = _Point * 2.0;

   double dropSupRef = drop.ancoraInicializada ? drop.ancoraSup : drop.precoSuperior;
   double dropInfRef = drop.ancoraInicializada ? drop.ancoraInf : drop.precoInferior;
   double dropAltura = MathAbs(dropSupRef - dropInfRef);
   if(dropAltura < (_Point * 2.0)) dropAltura = _Point * 2.0;

   // Merge aumenta a zona sobrevivente em X% da zona absorvida, sem deslocar a âncora.
   double novaAltura = keepAltura + (dropAltura * fatorAbsorcao);
   if(novaAltura < (_Point * 2.0)) novaAltura = _Point * 2.0;

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
   g_numeroZonasMin = g_numeroZonasAlvo - 2;
   if(g_numeroZonasMin < 2) g_numeroZonasMin = 2;
   g_numeroZonasMax = g_numeroZonasAlvo + 2;
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
      g_pivos[i].volumeMaximo = 0;
      g_pivos[i].percentualVolume = 0;
      g_pivos[i].ancoraInicializada = false;
   }
   
   g_volumeMaximoGlobal = 0.0;
   g_mergeCorretivoPendente = false;
   g_tempoCriacaoOverflow = 0;
   
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
   
   if(rates_total < InpPeriodoMedia + 10) return(0);
   
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
         
         if(InpPintarBarrasPreco && i < rates_total - 1) {
            PintarBarraPreco(time[i], high[i], low[i], g_palCorResistencia);
         }
      } else if(VolumeBuffer[i] > MediaBuffer[i]) {
         VolumeColorBuffer[i] = 1; // Verde - Volume Médio
      } else {
         VolumeColorBuffer[i] = 0; // Azul - Volume Baixo
      }
   }
   
   // Processar zonas em modo barra 0 fixa (sem "andar")
   if(InpMostrarProfile) {
      bool deveRecalcular = false;
      bool barraNova = (prev_calculated > 0 && rates_total > prev_calculated);
      bool houveMudancaEstado = false;
      bool houveCriacaoNova = false;
      bool houveIncrementoVolumeToque = false;

      // Reseta flags temporárias para não travar merges em barras seguintes.
      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         g_pivos[i].foiMergeada = false;
      }
      
      // Verificar se mudou o dia
      datetime agora = time[rates_total - 1];
      datetime hojeMidnight = agora - (agora % 86400); // Meia-noite de hoje
      
      if(prev_calculated == 0) {
         g_ultimoDiaAnalise = hojeMidnight;
         if(InpLogDetalhado) Print("Primeira execução");
      } else if(g_ultimoDiaAnalise != hojeMidnight) {
         g_ultimoDiaAnalise = hojeMidnight;
         if(InpLogDetalhado) Print("Novo dia detectado");
      }

      // <editor-fold defaultstate="collapsed" desc="FLUXO_DE_MERGE_E_CRIAÇÃO">
      // Criação: SOMENTE barra 0, zona fica fixa na barra de criação.
      int idx0 = rates_total - 1;
      if(idx0 >= InpPeriodoMedia) {
         bool gatilho = (BandaSuperiorBuffer[idx0] > 0.0 && VolumeBuffer[idx0] > BandaSuperiorBuffer[idx0]);
         if(gatilho && g_tempoUltimaCriacaoBarra != time[idx0]) {
            ENUM_LINE_TYPE tipo = DeterminarTipoLinha(idx0, high, low);
            double precoZona = (tipo == LINE_TOP) ? high[idx0] : low[idx0];
            double atrAtual = CalcularATR(idx0, high, low, close);

            // Candidata da barra de origem: zona fina ancorada no topo/fundo.
            double fatorAltura = InpFatorAlturaBarraOrigem;
            if(fatorAltura < 0.05) fatorAltura = 0.05;
            if(fatorAltura > 1.00) fatorAltura = 1.00;
            double alturaBarraOrigem = MathAbs(high[idx0] - low[idx0]);
            double alturaZonaCand = alturaBarraOrigem * fatorAltura;
            double alturaMaximaZona = ObterLimiarDistanciaATR(atrAtual, InpMaxATRPercent);
            if(alturaZonaCand > alturaMaximaZona) alturaZonaCand = alturaMaximaZona;
            if(alturaZonaCand < _Point * 2.0) alturaZonaCand = _Point * 2.0;
            if(alturaZonaCand > alturaBarraOrigem) alturaZonaCand = alturaBarraOrigem;
            double candSup = (tipo == LINE_TOP) ? high[idx0] : (low[idx0] + alturaZonaCand);
            double candInf = (tipo == LINE_TOP) ? (high[idx0] - alturaZonaCand) : low[idx0];

            // 1) Regras de criação e merge com controle de distância.
            int idxZonaAli = -1;
            int idxZonaMaisProxima = -1;
            double menorDistFaixa = DBL_MAX;
            double menorDistToque = DBL_MAX;
            double limiarMinCriacao = ObterLimiarDistanciaATR(atrAtual, InpDistanciaMinATR);

            for(int i = 0; i < g_numeroZonas; i++) {
               if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

               double distFaixa = DistanciaEntreFaixas(candSup, candInf,
                                                      g_pivos[i].precoSuperior,
                                                      g_pivos[i].precoInferior);
               if(distFaixa < menorDistFaixa) {
                  menorDistFaixa = distFaixa;
                  idxZonaMaisProxima = i;
               }

               if(BarraInterseccionaFaixa(candSup, candInf,
                                          g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) {
                  double distToque = DistanciaEntreFaixas(candSup, candInf,
                                                         g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
                  if(distToque < menorDistToque) {
                     menorDistToque = distToque;
                     idxZonaAli = i;
                  }
               }
            }

            bool mergeExecutadoNestaCriacao = false;
            bool podeMergeEvento = PodeProcessarMergeDoEvento(time[idx0]);
            if(idxZonaAli >= 0) {
               MergeQuandoCriacaoProxima(idxZonaAli,
                                         tipo,
                                         time[idx0],
                                         (double)tick_volume[idx0]);
               mergeExecutadoNestaCriacao = true;
               podeMergeEvento = false;
               if(InpLogDetalhado) Print("MERGE[sobreposicao]: absorção sem mover âncora da zona.");
            }

            if(!mergeExecutadoNestaCriacao &&
               podeMergeEvento &&
               idxZonaMaisProxima >= 0 &&
               !g_pivos[idxZonaMaisProxima].foiMergeada &&
               menorDistFaixa <= limiarMinCriacao) {
               MergeQuandoCriacaoProxima(idxZonaMaisProxima,
                                         tipo,
                                         time[idx0],
                                         (double)tick_volume[idx0]);
               mergeExecutadoNestaCriacao = true;
               podeMergeEvento = false;
               if(InpLogDetalhado) {
                  Print("MERGE[proxima]: absorção sem mover âncora (",
                        DoubleToString(menorDistFaixa / _Point, 1), " pts).");
               }
            }

            if(!mergeExecutadoNestaCriacao) {
               int idxLivre = -1;
               for(int i = 0; i < g_numeroZonas; i++) {
                  if(g_pivos[i].estado == PIVO_REMOVIDO) { idxLivre = i; break; }
               }

               if(idxLivre >= 0) {
                  if(menorDistFaixa > limiarMinCriacao) {
                     ENUM_VOLUME_INTENSIDADE intensidade = DeterminarIntensidadeVolume((double)tick_volume[idx0], MathMax(MediaBuffer[idx0], 1.0));
                     g_pivos[idxLivre].preco = precoZona;
                     g_pivos[idxLivre].precoSuperior = candSup;
                     g_pivos[idxLivre].precoInferior = candInf;
                     g_pivos[idxLivre].tempoInicio = time[idx0];
                     g_pivos[idxLivre].tempoMaisRecente = time[idx0];
                     g_pivos[idxLivre].volumeTotal = (double)tick_volume[idx0];
                     g_pivos[idxLivre].volumeMaximo = 0.0;
                     g_pivos[idxLivre].percentualVolume = 0.0;
                     g_pivos[idxLivre].quantidadeBarras = 1;
                     g_pivos[idxLivre].quantidadeTopos = (tipo == LINE_TOP) ? 1 : 0;
                     g_pivos[idxLivre].quantidadeFundos = (tipo == LINE_BOTTOM) ? 1 : 0;
                     g_pivos[idxLivre].tipo = tipo;
                     g_pivos[idxLivre].tipoMajoritario = tipo;
                     g_pivos[idxLivre].estado = PIVO_ATIVO;
                     g_pivos[idxLivre].corAtual = ObterCorZona(tipo);
                     g_pivos[idxLivre].atr = atrAtual;
                     g_pivos[idxLivre].barraInicio = idx0;
                     g_pivos[idxLivre].barraRompimento = 0;
                     g_pivos[idxLivre].tempoRompimento = 0;
                     g_pivos[idxLivre].barrasAposRompimento = 0;
                     g_pivos[idxLivre].precoAssentado = false;
                     g_pivos[idxLivre].distanciaPrecoAtual = 0.0;
                     g_pivos[idxLivre].score = 0.0;
                     g_pivos[idxLivre].foiMergeada = false;
                     g_pivos[idxLivre].pivoID = g_proximoPivoID++;
                     g_pivos[idxLivre].pivosIncorporados = "";
                     g_pivos[idxLivre].intensidadeVolume = intensidade;
                     g_pivos[idxLivre].ultimoTempoToqueContabilizado = time[idx0];
                     DefinirAncoraPivo(idxLivre);

                     g_tempoUltimaCriacaoBarra = time[idx0];
                     g_pivosInicializados = true;
                     houveCriacaoNova = true;
                     deveRecalcular = true;

                     int zonasAtivas = ContarZonasAtivas();
                     if(zonasAtivas > g_numeroZonasAlvo) {
                        g_mergeCorretivoPendente = true;
                        g_tempoCriacaoOverflow = time[idx0];
                        if(InpLogDetalhado) {
                           Print("OVERFLOW: ", zonasAtivas, " zonas ativas (alvo ", g_numeroZonasAlvo,
                                 "). Merge corretivo será tentado na próxima barra fechada.");
                        }
                     }
                  } else if(InpLogDetalhado) {
                     Print("CRIAÇÃO: bloqueada por distância mínima entre zonas (",
                           DoubleToString(menorDistFaixa / _Point, 1), " pts).");
                  }
                  g_tempoUltimaCriacaoBarra = time[idx0];
               } else {
                  if(InpLogDetalhado) {
                     Print("MERGE[sem-slot]: bloqueado por segurança de merge/limite de distância.");
                  }
                  g_tempoUltimaCriacaoBarra = time[idx0];
               }
            } else {
               g_tempoUltimaCriacaoBarra = time[idx0];
               g_pivosInicializados = true;
               deveRecalcular = true;
            }

         }
      }

      // Incremento de volume: só barras que TOCARAM a zona, e apenas uma vez por barra.
      if(g_pivosInicializados && barraNova && rates_total >= 2) {
         int idxFechada = rates_total - 2;
         if(idxFechada >= 0) {
            int zonasTocadas[20];
            int totalZonasTocadas = 0;

            // Primeiro: detectar todas as zonas tocadas pela barra fechada.
            for(int i = 0; i < g_numeroZonas; i++) {
               if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
               if(time[idxFechada] <= g_pivos[i].tempoInicio) continue; // só outra barra
               if(BarraInterseccionaFaixa(high[idxFechada], low[idxFechada],
                                          g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) {
                  if(totalZonasTocadas < 20) zonasTocadas[totalZonasTocadas++] = i;
               }
            }

            // Regra de merge por barra: somente UM merge por evento de fechamento.
            // Uma zona pode participar de no máximo um merge por evento (sem cascata).
            bool podeMergeFechamento = PodeProcessarMergeDoEvento(time[idxFechada]);
            if(totalZonasTocadas > 1 && podeMergeFechamento) {
               int idxCandA = -1, idxCandB = -1;
               double melhorDist = DBL_MAX;

               for(int a = 0; a < totalZonasTocadas; a++) {
                  int idxA = zonasTocadas[a];
                  if(idxA < 0 || idxA >= g_numeroZonas) continue;
                  if(g_pivos[idxA].estado == PIVO_REMOVIDO) continue;
                  if(g_pivos[idxA].foiMergeada) continue;
                  if(ZonaRecemCriadaProtegida(idxA, time[idxFechada], 1)) continue;

                  for(int b = a + 1; b < totalZonasTocadas; b++) {
                     int idxB = zonasTocadas[b];
                     if(idxB < 0 || idxB >= g_numeroZonas) continue;
                     if(g_pivos[idxB].estado == PIVO_REMOVIDO) continue;
                     if(g_pivos[idxB].foiMergeada) continue;
                     if(ZonaRecemCriadaProtegida(idxB, time[idxFechada], 1)) continue;

                     double supA = MathMax(g_pivos[idxA].precoSuperior, g_pivos[idxA].precoInferior);
                     double infA = MathMin(g_pivos[idxA].precoSuperior, g_pivos[idxA].precoInferior);
                     double supB = MathMax(g_pivos[idxB].precoSuperior, g_pivos[idxB].precoInferior);
                     double infB = MathMin(g_pivos[idxB].precoSuperior, g_pivos[idxB].precoInferior);
                     double distEntre = DistanciaEntreFaixas(supA, infA, supB, infB);

                     if(distEntre < melhorDist) {
                        melhorDist = distEntre;
                        idxCandA = idxA;
                        idxCandB = idxB;
                     }
                  }
               }

               if(idxCandA >= 0 && idxCandB >= 0) {
                  int idxManter = idxCandA;
                  int idxAbsorver = idxCandB;
                  if(g_pivos[idxCandA].tipo == LINE_TOP) {
                     if(g_pivos[idxCandB].precoSuperior > g_pivos[idxCandA].precoSuperior) {
                        idxManter = idxCandB;
                        idxAbsorver = idxCandA;
                     }
                  } else {
                     if(g_pivos[idxCandB].precoInferior < g_pivos[idxCandA].precoInferior) {
                        idxManter = idxCandB;
                        idxAbsorver = idxCandA;
                     }
                  }

                  bool manterProtegido = ZonaRecemCriadaProtegida(idxManter, time[idxFechada], 1);
                  bool absorverProtegido = ZonaRecemCriadaProtegida(idxAbsorver, time[idxFechada], 1);
                  if(absorverProtegido && !manterProtegido) {
                     int tmp = idxManter;
                     idxManter = idxAbsorver;
                     idxAbsorver = tmp;
                  } else if(absorverProtegido && manterProtegido) {
                     if(InpLogDetalhado) {
                        Print("MERGE[mesma-barra][SKIP]: par protegido por recém-criação.");
                     }
                     idxCandA = -1;
                     idxCandB = -1;
                  }

                  if(idxCandA < 0 || idxCandB < 0) {
                     // Par bloqueado por proteção de recém-criação.
                  } else if(AbsorverZonaSemMoverAncora(idxManter, idxAbsorver, time[idxFechada])) {
                     // Garante que uma única fusão ocorre nesse fechamento.
                     houveIncrementoVolumeToque = true;
                     MarcarMergeProcessadoNoEvento(time[idxFechada]);
                     if(InpLogDetalhado) {
                        Print("MERGE[mesma-barra][", (g_pivos[idxManter].tipo == LINE_TOP ? "TOP" : "BOTTOM"),
                              "]: zonas ", idxAbsorver, " + ", idxManter, " absorvidas sem deslocar âncora. dist=", 
                              DoubleToString(melhorDist / _Point, 1), " pts.");
                     }
                  } else if(InpLogDetalhado) {
                     Print("MERGE[mesma-barra][", (g_pivos[idxCandA].tipo == LINE_TOP ? "TOP" : "BOTTOM"),
                           "]: tentativa bloqueada para par ", idxCandA, "/", idxCandB, ".");
                  }
               } else if(InpLogDetalhado) {
                  Print("MERGE[mesma-barra][SKIP]: sem par válido para fusão. total tocadas=", totalZonasTocadas);
               }
            } else if(totalZonasTocadas > 1 && InpLogDetalhado) {
               Print("MERGE[mesma-barra][SKIP]: limite de um merge por evento já foi consumido.");
            }

            // Agora acumula volume apenas uma vez por barra nas zonas sobreviventes.
            for(int k = 0; k < totalZonasTocadas; k++) {
               int i = zonasTocadas[k];
               if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
               if(g_pivos[i].ultimoTempoToqueContabilizado == time[idxFechada]) continue;
               g_pivos[i].volumeTotal += (double)tick_volume[idxFechada];
               g_pivos[i].quantidadeBarras++;
               g_pivos[i].tempoMaisRecente = MathMax(g_pivos[i].tempoMaisRecente, time[idxFechada]);
               g_pivos[i].ultimoTempoToqueContabilizado = time[idxFechada];
               houveIncrementoVolumeToque = true;
            }

            // Overflow suave: só compacta no fechamento seguinte à criação acima do alvo.
            if(g_mergeCorretivoPendente &&
               time[idxFechada] > g_tempoCriacaoOverflow &&
               ContarZonasAtivas() > g_numeroZonasAlvo) {
                  bool podeMergeCorretivo = PodeProcessarMergeDoEvento(time[idxFechada]);
                  if(podeMergeCorretivo) {
                     datetime diaFechada = time[idxFechada] - (time[idxFechada] % 86400);
                     if(ExecutarMergeCorretivoOverflow(close[idxFechada], diaFechada, time[idxFechada])) {
                        MarcarMergeProcessadoNoEvento(time[idxFechada]);
                        deveRecalcular = true;
                        houveIncrementoVolumeToque = true;
                     if(InpLogDetalhado) {
                        Print("MERGE[overflow]: compactação corretiva aplicada na barra seguinte.");
                     }
                  } else if(InpLogDetalhado) {
                     Print("MERGE[overflow][SKIP]: nenhum par válido para compactação nesta barra.");
                  }
               }
            }

            if(ContarZonasAtivas() <= g_numeroZonasAlvo) {
               g_mergeCorretivoPendente = false;
               g_tempoCriacaoOverflow = 0;
            }
         }
      }
      // </editor-fold>

      if(g_pivosInicializados) {
         AplicarTravaAncoraPivos();
      }

      // Validação de rompimento apenas quando necessário.
      if(g_pivosInicializados && (barraNova || !InpAtualizarUIApenasBarraNova))
         houveMudancaEstado = VerificarRompimentosEAssentamento(rates_total, close);

      if(g_pivosInicializados && (deveRecalcular || houveCriacaoNova || houveIncrementoVolumeToque))
         CalcularPercentuaisVolume();

      bool deveAtualizarUI = deveRecalcular || houveCriacaoNova || houveIncrementoVolumeToque ||
                             houveMudancaEstado || barraNova || !InpAtualizarUIApenasBarraNova;
      if(deveAtualizarUI) {
         DesenharPivos(rates_total, time);
         AtualizarCoordenadasPivos(rates_total, time);
      }
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Determinar intensidade do volume                                |
//+------------------------------------------------------------------+
ENUM_VOLUME_INTENSIDADE DeterminarIntensidadeVolume(double volume, double volumeMedia) {
   double ratio = volume / volumeMedia;
   
   if(ratio >= 3.0) return VOLUME_EXTREMO;      // 300% da média
   else if(ratio >= 2.0) return VOLUME_ALTO;    // 200% da média  
   else if(ratio >= 1.5) return VOLUME_MEDIO;   // 150% da média
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
   // Encontrar o volume máximo entre todos os pivôs ativos
   g_volumeMaximoGlobal = 0.0;
   
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(g_pivos[i].volumeTotal > g_volumeMaximoGlobal) {
         g_volumeMaximoGlobal = g_pivos[i].volumeTotal;
      }
   }
   
   // Calcular percentual de cada pivô em relação ao máximo
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      
      g_pivos[i].volumeMaximo = g_volumeMaximoGlobal;
      
      if(g_volumeMaximoGlobal > 0) {
         g_pivos[i].percentualVolume = (g_pivos[i].volumeTotal / g_volumeMaximoGlobal) * 100.0;
      } else {
         g_pivos[i].percentualVolume = 0.0;
      }
   }
   
   Print("📊 Volume máximo global: ", g_volumeMaximoGlobal, " - Percentuais calculados");
}

//+------------------------------------------------------------------+
//| Criar progress bar dentro da zona                               |
//+------------------------------------------------------------------+
void CriarProgressBar(int pivoIndex, datetime tempoInicio, datetime tempoFim, double precoSuperior, double precoInferior) {
   string nomeProgressBar = g_prefixo + "Progress_" + IntegerToString(pivoIndex);
   if(!InpMostrarProgressBar || g_pivos[pivoIndex].percentualVolume <= 0) {
      if(ObjectFind(g_chartID, nomeProgressBar) >= 0) ObjectDelete(g_chartID, nomeProgressBar);
      return;
   }
   
   // Calcular tamanho da barra baseado no percentual (0-100%)
   double percentual = g_pivos[pivoIndex].percentualVolume;
   if(percentual < 0) percentual = 0;
   if(percentual > 100) percentual = 100; // Limitar a 100%
   
   // Calcular largura da barra (percentual do tempo total da zona)
   datetime tempoTotalZona = tempoFim - tempoInicio;
   datetime larguraBarra = (datetime)(tempoTotalZona * (percentual / 100.0));
   datetime tempoFimBarra = tempoInicio + larguraBarra;
   
   // Calcular altura da barra (ocupar 80% da altura da zona, centralizada)
   double alturaZona = precoSuperior - precoInferior;
   if(alturaZona <= 0.0) alturaZona = MathMax(g_pivos[pivoIndex].atr * 0.10, _Point * 10.0);
   double margemVertical = alturaZona * 0.1;     // 10% margem em cima e embaixo
   
   double precoSuperiorBarra = precoSuperior - margemVertical;
   double precoInferiorBarra = precoInferior + margemVertical;
   
   // Criar uma vez e depois apenas atualizar propriedades (evita pisca-pisca).
   if(ObjectFind(g_chartID, nomeProgressBar) < 0) {
      ObjectCreate(g_chartID, nomeProgressBar, OBJ_RECTANGLE, 0,
                   tempoInicio, precoInferiorBarra,
                   tempoFimBarra, precoSuperiorBarra);
   }
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_TIME, 0, tempoInicio);
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_TIME, 1, tempoFimBarra);
   ObjectSetDouble(g_chartID, nomeProgressBar, OBJPROP_PRICE, 0, precoInferiorBarra);
   ObjectSetDouble(g_chartID, nomeProgressBar, OBJPROP_PRICE, 1, precoSuperiorBarra);
   
   // Configurar visual da progress bar
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_COLOR, g_palCorProgress);
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_BACK, true);  // Atrás do gráfico (preço na frente)
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_HIDDEN, true);
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_WIDTH, 1);
   
   // Aplicar transparência específica para progress bar
   uint alpha = (uint)InpTransparenciaProgress;
   if(alpha > 255) alpha = 255;
   color corComTransparencia = (color)((g_palCorProgress & 0x00FFFFFF) | (alpha << 24));
   ObjectSetInteger(g_chartID, nomeProgressBar, OBJPROP_BGCOLOR, corComTransparencia);
   
   // Tooltip informativo
   string tooltip = StringFormat("Volume: %.0f (%.1f%% do máximo)", 
                                 g_pivos[pivoIndex].volumeTotal, 
                                 g_pivos[pivoIndex].percentualVolume);
   ObjectSetString(g_chartID, nomeProgressBar, OBJPROP_TOOLTIP, tooltip);
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
   datetime tempoFim = tempoAtual + PeriodSeconds() * 100; // Estender 100 períodos no futuro
   
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
         g_pivos[i].corAtual = g_palCorRompido; // Neutro temporário
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
   int periodo = 14;
   int arraySize = ArraySize(high);
   
   // Verificações de segurança
   if(barra < 0 || barra >= arraySize) {
      Print("⚠️ Índice inválido em CalcularATR: ", barra, " / ", arraySize);
      return 0.01; // Valor padrão para evitar divisão por zero
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
   if(maxBarras < 20) maxBarras = 20;

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
      if(ultimoValido != EMPTY_VALUE && MathAbs(valor - ultimoValido) <= (_Point * 0.5))
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

//+------------------------------------------------------------------+
//| Determinar tipo de linha                                        |
//+------------------------------------------------------------------+
ENUM_LINE_TYPE DeterminarTipoLinha(int barra, const double &high[], const double &low[]) {
   int arraySize = ArraySize(high);
   
   // Verificações de segurança
   if(barra < 0 || barra >= arraySize) {
      Print("⚠️ Índice inválido em DeterminarTipoLinha: ", barra, " / ", arraySize);
      return LINE_TOP; // Default seguro
   }
   
   if(barra < 2 || barra >= arraySize - 2) {
      // Default baseado na posição na barra
      double meio = (high[barra] + low[barra]) / 2.0;
      return (high[barra] - meio >= meio - low[barra]) ? LINE_TOP : LINE_BOTTOM;
   }
   
   // Verificar se é topo
   bool ehTopo = true;
   for(int j = 1; j <= 2; j++) {
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
   for(int j = 1; j <= 2; j++) {
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
   
   // Se não é nem topo nem fundo claro, usar critério da barra
   double meio = (high[barra] + low[barra]) / 2.0;
   return (high[barra] - meio >= meio - low[barra]) ? LINE_TOP : LINE_BOTTOM;
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
   datetime tempoFim = tempoBarraZero + PeriodSeconds() * 50; // Estender no futuro
   int pivosDesenhados = 0;
   
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
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_WIDTH, 1);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_FILL, true);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BACK, true);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_SELECTABLE, false);

      uint alpha = (uint)InpTransparenciaZonas;
      if(alpha > 255) alpha = 255;
      color corComTransparencia = (color)((g_pivos[i].corAtual & 0x00FFFFFF) | (alpha << 24));
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BGCOLOR, corComTransparencia);
      pivosDesenhados++;

      // 2) Progress bar da zona
      CriarProgressBar(i, g_pivos[i].tempoInicio, tempoFim,
                       g_pivos[i].precoSuperior, g_pivos[i].precoInferior);

      // 3) Texto
      if(InpMostrarVolumeTexto) {
         datetime tempoTexto = g_pivos[i].tempoInicio + (tempoFim - g_pivos[i].tempoInicio) / 2;
         double precoTexto = (g_pivos[i].precoSuperior + g_pivos[i].precoInferior) / 2;
         if(ObjectFind(g_chartID, nomeTexto) < 0) {
            ObjectCreate(g_chartID, nomeTexto, OBJ_TEXT, 0, tempoTexto, precoTexto);
         }
         string tipoStr = (g_pivos[i].tipo == LINE_TOP) ? "R" : "S";
         string estadoStr = "";
         if(g_pivos[i].estado == PIVO_ROMPIDO) estadoStr = "!";
         else if(g_pivos[i].estado == PIVO_CONFIRMADO) estadoStr = "*";
         string texto = StringFormat("%s%s:%d Vol:%.0f (%.1f%%)",
                                     tipoStr, estadoStr, i+1,
                                     g_pivos[i].volumeTotal,
                                     g_pivos[i].percentualVolume);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_TIME, 0, tempoTexto);
         ObjectSetDouble(g_chartID, nomeTexto, OBJPROP_PRICE, 0, precoTexto);
         ObjectSetString(g_chartID, nomeTexto, OBJPROP_TEXT, texto);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_ANCHOR, ANCHOR_CENTER);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_BACK, false);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_SELECTABLE, false);
      } else {
         if(ObjectFind(g_chartID, nomeTexto) >= 0) ObjectDelete(g_chartID, nomeTexto);
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
//| Pintar barra de preço                                           |
//+------------------------------------------------------------------+
void PintarBarraPreco(datetime time, double high, double low, color cor) {
   string nome = g_prefixo + "Bar_" + TimeToString(time, TIME_DATE|TIME_MINUTES);
   
   if(ObjectFind(g_chartID, nome) >= 0) return;
   
   if(ObjectCreate(g_chartID, nome, OBJ_TREND, 0, time, high, time, low)) {
      ObjectSetInteger(g_chartID, nome, OBJPROP_COLOR, cor);
      ObjectSetInteger(g_chartID, nome, OBJPROP_WIDTH, 3);
      ObjectSetInteger(g_chartID, nome, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(g_chartID, nome, OBJPROP_RAY, false);
      ObjectSetInteger(g_chartID, nome, OBJPROP_BACK, true);
      ObjectSetInteger(g_chartID, nome, OBJPROP_SELECTABLE, false);
   }
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

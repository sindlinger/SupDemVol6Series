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
input group "01. Basico"
input bool     InpModoLowCostTotal = false;         // Modo super barato: somente faixas (sem painel/textos/logs/intrabar)
input int      InpPeriodoMedia = 20;                // Periodo da media de volume
input double   InpMultiplicadorDesvio = 3.5;        // Multiplicador do desvio padrao
input bool     InpMostrarProfile = true;            // Exibe zonas no grafico
input int      InpDiasAnalise = 3;                  // Janela principal de analise (dias)
input int      InpPeriodoATR = 14;                  // Periodo ATR interno (fallback tecnico)

input group "02. Criacao e Merge"
input double   InpMaxATRPercent = 35.0;             // Altura maxima da zona (escala relativa; com SemATR usa faixa do dia)
input double   InpDistanciaMinATR = 50.0;           // Distancia minima entre zonas (escala relativa; com SemATR usa faixa do dia)
input double   InpFatorDistanciaMinCriacao = 1.60;  // Multiplicador da distancia minima de criacao
input double   InpFatorGapPorSomaMerge = 1.00;      // Gap maximo por soma de alturas (0..1)
input double   InpFatorAlturaBarraOrigem = 0.35;    // Fracao da barra origem para altura da zona
input double   InpFatorAbsorcaoMerge = 0.30;        // Fracao da zona absorvida incorporada
input int      InpBarrasProtecaoZonaRecemCriada = 1; // Bloqueio de absorcao imediata
input bool     InpEnriquecimentoToqueSomenteAcimaBanda = false; // Toque so enriquece com volume acima da banda
input ENUM_MODO_CONFLITO_SINAL_ENRIQ InpModoConflitoSinalEnriquecimento = CONFLITO_SINAL_MIX_SOMBRA; // Regra de conflito buy/sell
input int      InpTempoAssentamento = 20;           // Barras para confirmar assentamento
input bool     InpHabilitarTravaAncora = true;      // Reaplica ancora das zonas a cada ciclo

input group "03. Organizacao Continua"
input bool     InpOrganizacaoEmBarraFechada = true; // Roda organizacao em barra fechada
input int      InpOrganizacaoGatilhoZonas = 6;      // A partir deste total, organiza agressivo
input int      InpOrganizacaoLimiteDuroZonas = 18;  // Limite absoluto de zonas
input int      InpOrganizacaoAlvoNormal = 7;        // Alvo quando ha gap elegivel
input int      InpOrganizacaoAlvoSemGap = 5;        // Alvo quando nao ha gap elegivel
input double   InpOrganizacaoFatorGapMaiorZona = 2.5; // Gap elegivel relativo a maior zona
input int      InpOrganizacaoMaxAcoesPorBarra = 20; // Maximo de acoes por ciclo
input double   InpShvedFractalFastFactor = 3.0;     // Fator fractal rapido (inspiracao Shved)
input double   InpShvedFractalSlowFactor = 6.0;     // Fator fractal lento (inspiracao Shved)
input int      InpShvedLookbackBarras = 1000;       // Lookback de fractais

input group "04. Percentuais e Distribuicao"
input bool     InpDistribuicaoSomentePico = true;   // Distribuicao baseada em barras acima da banda
input bool     InpConservacaoVolumeAltoEstrita = true; // Conserva massa de volume alto na janela
input bool     InpAplicarRateioRetroativoNasZonas = false; // Reescreve volume da zona com rateio
input bool     InpPercentualNominalSimples = true;  // Percentual nominal simples entre zonas
input bool     InpEscalaRelativaSemATR = true;      // Usa faixa diaria no lugar de ATR
input double   InpEscalaRelativaFatorFaixaDia = 0.10; // Fator da faixa diaria
input double   InpEscalaRelativaMinPctPreco = 0.05; // Piso da escala relativa em % do preco
input int      InpJanelaInicioDiaBarras = 2;        // Janela de prioridade no inicio do dia
input double   InpPesoMaxVolDiaAnterior = 1.20;     // Peso para maximo de volume do dia anterior
input double   InpPesoMaxVolDiaAtual = 1.08;        // Peso para maximo de volume do dia atual
input double   InpPesoExtremosDia = 1.06;           // Peso para zonas perto de extremos diarios
input double   InpRedutorZonaVencida = 0.92;        // Redutor de zonas vencidas

input group "05. Visual Zonas"
input color    InpCorPaletaElegante = C'46,123,214'; // Cor base BUY
input color    InpCorPaletaVermelha = C'188,36,52';  // Cor base SELL
input int      InpLarguraLinhas = 2;                // Largura base das zonas
input int      InpTransparenciaZonas = 120;         // Transparencia das zonas (0-255)
input int      InpAlturaMinimaZonaPontos = 2;       // Altura minima da zona em pontos
input int      InpExtensaoTemporalZona = 50;        // Extensao horizontal ao desenhar
input int      InpExtensaoTemporalCoordenada = 100; // Extensao horizontal para atualizar coordenadas
input bool     InpDesenharZonaAteRecuo = true;      // Estende zona ate o recuo direito
input bool     InpExibirFaixaVolumeDireita = false; // Exibe faixa no recuo direito
input bool     InpExibirValoresZona = true;         // Exibe valores nas zonas
input bool     InpDesligarArteEnriquecimentoVisual = true; // Temporario: corta updates visuais intrabar do enriquecimento
input bool     InpDesabilitarTextosZonaTemporario = false; // Temporario: oculta os textos das zonas
input ENUM_POSICAO_HORIZONTAL_TEXTO_ZONA InpPosicaoHorizontalTextoZona = TEXTO_ZONA_DIREITA; // Posicao horizontal dos valores
input double   InpPosicaoVerticalTextoZona = 0.50;  // Posicao vertical dos valores (0..1)
input int      InpDeslocamentoTextoBarras = 0;      // Deslocamento horizontal dos valores em barras
input int      InpTamanhoFonteTextoZona = 8;        // Fonte do texto das zonas
input bool     InpAtualizarUIApenasBarraNova = true; // Atualiza UI apenas em barra nova

input group "06. Linhas de Referencia"
input bool     InpMostrarLinhaMaiorMaxima = true;   // Exibe linha da maior maxima
input int      InpPeriodoLinhaMaiorMaxima = 14;     // Periodo da maior maxima
input color    InpCorLinhaMaiorMaxima = C'188,36,52'; // Cor da linha maior maxima
input ENUM_LINE_STYLE InpEstiloLinhaMaiorMaxima = STYLE_DASHDOT; // Estilo da linha maior maxima
input int      InpLarguraLinhaMaiorMaxima = 1;      // Largura da linha maior maxima
input bool     InpMaximaReal = true;                // Ancora max/min ate violacao
input bool     InpMostrarLinhaMenorMinima = true;   // Exibe linha da menor minima
input int      InpPeriodoLinhaMenorMinima = 14;     // Periodo da menor minima
input color    InpCorLinhaMenorMinima = C'46,123,214'; // Cor da linha menor minima
input ENUM_LINE_STYLE InpEstiloLinhaMenorMinima = STYLE_DOT; // Estilo da linha menor minima
input int      InpLarguraLinhaMenorMinima = 1;      // Largura da linha menor minima

input group "07. Painel e Logs"
input bool     InpExibirPainelVolume = false;       // Exibe subjanela de volume ao iniciar
input bool     InpLogDetalhado = false;             // Log detalhado geral
input bool     InpLogBloqueiosMerge = false;        // Log especifico de bloqueios de merge
input bool     InpExibirLogEnriquecimentoNoGrafico = false; // Exibe ultimos eventos no chart
input int      InpLinhasLogEnriquecimento = 6;      // Linhas no painel de enriquecimento
input ENUM_POSICAO_PAINEL_LOG InpPosicaoPainelLogEnriquecimento = PAINEL_LOG_SUP_ESQ; // Canto do painel de log
input int      InpPainelLogOffsetX = 12;            // Offset X do painel de log
input int      InpPainelLogOffsetY = 40;            // Offset Y do painel de log
input int      InpPainelLogFonteTamanho = 9;        // Fonte do painel de log
input color    InpPainelLogCorTexto = clrBlack;     // Cor do painel de log
input bool     InpExibirPainelBalanceCV = true;     // Exibe painel BUY/SELL geral
input int      InpPainelBalanceOffsetX = 5;         // Offset X do painel BUY/SELL
input int      InpPainelBalanceOffsetY = 12;        // Offset Y do painel BUY/SELL
input int      InpPainelBalanceFonteTamanho = 16;   // Fonte do painel BUY/SELL

input group "08. Tecnico (Avancado)"
input int      InpVizinhancaPivotBarras = 2;        // Vizinhanca para classificar topo/fundo
input int      InpZigZagDepth = 12;                 // ZigZag depth
input int      InpZigZagDeviation = 5;              // ZigZag deviation
input int      InpZigZagBackstep = 3;               // ZigZag backstep
input double   InpDistMinFatorZigZag = 1.0;         // Fator da distancia zigzag
input double   InpVolumeRatioMedio = 1.5;           // Limiar de volume medio
input double   InpVolumeRatioAlto = 2.0;            // Limiar de volume alto
input double   InpVolumeRatioExtremo = 3.0;         // Limiar de volume extremo
input int      InpDiasReferenciaOrigem = 2;         // Dias para score de origem
input double   InpPesoOrigemVolume = 0.70;          // Peso de volume no score de origem
input double   InpPesoOrigemSombra = 0.30;          // Peso da sombra no score de origem
input double   InpPesoOrigemCorpo = 0.00;           // Peso do corpo no score de origem
input double   InpToleranciaDominioSombra = 0.05;   // Tolerancia para sombra dominante
input int      InpBarrasExtrasHistorico = 10;       // Barras extras para liberar calculos
input double   InpFatorAlturaMinBarraOrigem = 0.05; // Clamp minimo do fator de altura
input double   InpFatorAlturaMaxBarraOrigem = 1.00; // Clamp maximo do fator de altura
input double   InpAtrFallbackEmErro = 0.01;         // ATR fallback em erro

input group "09. Volume Real (Feed Externo)"
input bool     InpUsarVolumeRealFeed = false;       // Lê volume real de arquivo no Common\\Files (produzido por bridge HTTP/WS)
input string   InpArquivoVolumeRealFeed = "SupDemVol/real_volume_feed.csv"; // symbol,period_sec,bar_time_unix,volume,source_time_unix
input bool     InpVolumeRealFeedBarraFechada = true; // Aplica no candle fechado (mais estável)
input int      InpVolumeRealFeedRefreshMs = 1000;   // Intervalo mínimo entre leituras do arquivo
input int      InpVolumeRealFeedMaxAtrasoSeg = 300; // Se source_time vier atrasado acima disso, ignora
input bool     InpLogVolumeRealFeed = false;        // Log de depuração da leitura do feed externo

input group "10. Book Real (DOM)"
input bool     InpBookAtivo = false;                // Ativa leitura do DOM nativo (MarketBook)
input bool     InpBookDesenhar = false;             // Desenha niveis do book no chart principal
input bool     InpBookAcumularReducaoComoExecutado = true; // Quando nivel reduz/some, acumula no preco (execucao estimada)
input int      InpBookMaxNiveisDesenho = 40;        // Maximo de niveis desenhados por refresh
input double   InpBookVolumeMinimoExibicao = 1.0;   // Volume minimo para exibir nivel
input int      InpBookOffsetDireitaBarras = 8;      // Distancia horizontal dos blocos DOM
input int      InpBookLarguraBarras = 2;            // Largura horizontal dos blocos DOM
input int      InpBookAlturaPontos = 12;            // Altura vertical dos blocos DOM (pontos)
input int      InpBookFonte = 8;                    // Fonte do valor dos niveis DOM
input int      InpBookPollMs = 300;                 // Polling fallback no OnCalculate
input int      InpBookRefreshVisualMs = 250;        // Throttle da renderizacao DOM
input int      InpBookMaxNiveisMemoria = 1200;      // Capacidade interna de niveis por preco
input bool     InpBookLog = false;                  // Log de depuracao do modulo DOM

// Buffers
double VolumeBuffer[];
double VolumeColorBuffer[];
double BandaSuperiorBuffer[];
double ZeroBuffer[];
double MediaBuffer[];

// Variáveis globais
string g_prefixo = "VProfile7_v5_";
long g_chartID;
bool g_profileDesenhado = false;
datetime g_ultimaAtualizacao = 0;
datetime g_ultimoDiaAnalise = 0;
int g_numeroZonas = 7;  // Sera inicializado com limite duro de organizacao
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
datetime g_tempoBarraFechadaCriacaoProcessada = 0;
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
long g_mergeCooldownTicketGlobal = 0;
datetime g_volumeRealCacheBarTime = 0;
double g_volumeRealCacheValor = 0.0;
bool g_volumeRealCacheValido = false;
ulong g_volumeRealCacheMs = 0;
datetime g_volumeRealCacheSourceTime = 0;

enum ENUM_SDV4_EXEC_MODULO {
   SDV4_EXEC_MOD_ORGANIZACAO = 0,
   SDV4_EXEC_MOD_CRIACAO = 1,
   SDV4_EXEC_MOD_MERGE = 2,
   SDV4_EXEC_MOD_COUNT = 3
};

enum ENUM_SDV4_EXEC_FASE {
   SDV4_EXEC_FASE_NONE = 0,
   SDV4_EXEC_FASE_ORG_PRE = 1,
   SDV4_EXEC_FASE_CRIACAO = 2,
   SDV4_EXEC_FASE_MERGE = 3,
   SDV4_EXEC_FASE_ORG_POS = 4,
   SDV4_EXEC_FASE_ORG_DEMANDA = 5
};

ulong g_execCycleId = 0;
ENUM_SDV4_EXEC_FASE g_execFaseAtual = SDV4_EXEC_FASE_NONE;
ulong g_execTokenModulo[SDV4_EXEC_MOD_COUNT];
ENUM_SDV4_EXEC_FASE g_execFasePermitida[SDV4_EXEC_MOD_COUNT];
ulong g_execUltimoCycleModulo[SDV4_EXEC_MOD_COUNT];
datetime g_execUltimoTempoModulo[SDV4_EXEC_MOD_COUNT];
ENUM_SDV4_EXEC_FASE g_execUltimaFaseModulo[SDV4_EXEC_MOD_COUNT];
bool g_execSolicitacaoOrganizacao = false;
string g_execMotivoSolicitacaoOrganizacao = "";

string SDV4_ExecNomeModulo(const int modulo) {
   if(modulo == SDV4_EXEC_MOD_ORGANIZACAO) return "ORGANIZACAO";
   if(modulo == SDV4_EXEC_MOD_CRIACAO) return "CRIACAO";
   if(modulo == SDV4_EXEC_MOD_MERGE) return "MERGE";
   return "DESCONHECIDO";
}

string SDV4_ExecNomeFase(const ENUM_SDV4_EXEC_FASE fase) {
   if(fase == SDV4_EXEC_FASE_ORG_PRE) return "ORG_PRE";
   if(fase == SDV4_EXEC_FASE_CRIACAO) return "CRIACAO";
   if(fase == SDV4_EXEC_FASE_MERGE) return "MERGE";
   if(fase == SDV4_EXEC_FASE_ORG_POS) return "ORG_POS";
   if(fase == SDV4_EXEC_FASE_ORG_DEMANDA) return "ORG_DEMANDA";
   return "NONE";
}

void SDV4_ExecIniciarCiclo() {
   g_execCycleId++;
   if(g_execCycleId == 0) g_execCycleId = 1;
   g_execFaseAtual = SDV4_EXEC_FASE_NONE;
   for(int i = 0; i < SDV4_EXEC_MOD_COUNT; i++) {
      g_execTokenModulo[i] = 0;
      g_execFasePermitida[i] = SDV4_EXEC_FASE_NONE;
   }
}

void SDV4_ExecDefinirFaseAtual(const ENUM_SDV4_EXEC_FASE fase) {
   g_execFaseAtual = fase;
}

void SDV4_ExecConcederModulo(const int modulo, const ENUM_SDV4_EXEC_FASE fase) {
   if(modulo < 0 || modulo >= SDV4_EXEC_MOD_COUNT) return;
   g_execTokenModulo[modulo] = g_execCycleId;
   g_execFasePermitida[modulo] = fase;
}

void SDV4_ExecSolicitarOrganizacao(const string origem) {
   string tag = origem;
   if(StringLen(tag) <= 0) tag = "SEM_ORIGEM";
   if(!g_execSolicitacaoOrganizacao || StringLen(g_execMotivoSolicitacaoOrganizacao) <= 0) {
      g_execMotivoSolicitacaoOrganizacao = tag;
   } else if(StringFind(g_execMotivoSolicitacaoOrganizacao, tag) < 0) {
      g_execMotivoSolicitacaoOrganizacao += " | " + tag;
      if(StringLen(g_execMotivoSolicitacaoOrganizacao) > 240) {
         g_execMotivoSolicitacaoOrganizacao = StringSubstr(g_execMotivoSolicitacaoOrganizacao, 0, 240);
      }
   }
   g_execSolicitacaoOrganizacao = true;
   if(!InpModoLowCostTotal && InpLogDetalhado) {
      Print("EXEC-GATE[REQUEST-ORG]: ", tag);
   }
}

bool SDV4_ExecConsumirSolicitacaoOrganizacao(string &motivo) {
   if(!g_execSolicitacaoOrganizacao) return false;
   motivo = g_execMotivoSolicitacaoOrganizacao;
   g_execSolicitacaoOrganizacao = false;
   g_execMotivoSolicitacaoOrganizacao = "";
   return true;
}

bool SDV4_ExecAutorizarEntrada(const int modulo,
                               const datetime tempoEvento,
                               const string origem) {
   if(modulo < 0 || modulo >= SDV4_EXEC_MOD_COUNT) return false;

   if(g_execTokenModulo[modulo] != g_execCycleId ||
      g_execFasePermitida[modulo] != g_execFaseAtual) {
      if(modulo == SDV4_EXEC_MOD_ORGANIZACAO) {
         SDV4_ExecSolicitarOrganizacao(origem);
      }
      if(!InpModoLowCostTotal && InpLogDetalhado) {
         PrintFormat("EXEC-GATE[BLOCK]: modulo=%s origem=%s faseAtual=%s fasePermitida=%s ciclo=%I64u token=%I64u",
                     SDV4_ExecNomeModulo(modulo),
                     origem,
                     SDV4_ExecNomeFase(g_execFaseAtual),
                     SDV4_ExecNomeFase(g_execFasePermitida[modulo]),
                     g_execCycleId,
                     g_execTokenModulo[modulo]);
      }
      return false;
   }

   if(g_execUltimoCycleModulo[modulo] == g_execCycleId &&
      g_execUltimoTempoModulo[modulo] == tempoEvento &&
      g_execUltimaFaseModulo[modulo] == g_execFaseAtual) {
      if(!InpModoLowCostTotal && InpLogDetalhado) {
         PrintFormat("EXEC-GATE[REPEAT]: modulo=%s fase=%s tempo=%s origem=%s",
                     SDV4_ExecNomeModulo(modulo),
                     SDV4_ExecNomeFase(g_execFaseAtual),
                     TimeToString(tempoEvento, TIME_DATE|TIME_MINUTES),
                     origem);
      }
      return false;
   }

   g_execUltimoCycleModulo[modulo] = g_execCycleId;
   g_execUltimoTempoModulo[modulo] = tempoEvento;
   g_execUltimaFaseModulo[modulo] = g_execFaseAtual;
   return true;
}

bool PodeProcessarMergeDoEvento(const datetime tempoEvento) {
   if(g_tempoEventoMerge != tempoEvento) {
      g_tempoEventoMerge = tempoEvento;
      g_mergeExecutadoNoEvento = false;
   }
   return !g_mergeExecutadoNoEvento;
}


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
   long cooldownMergeTicket;
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
      cooldownMergeTicket = 0;
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
      cooldownMergeTicket = other.cooldownMergeTicket;
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

#include "regras/SupDemVol_ModuleRegras_v6.mqh"

// Regras de merge (módulo dedicado).
#include "merge/SupDemVol_MergeRules_v5.mqh"
#include "book/SupDemVol_ModuleBook_v1.mqh"

bool SDV4_MergeCooldownPodeMesclarZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return false;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return false;
   if(g_pivos[idx].cooldownMergeTicket <= 0) return true;
   return (g_mergeCooldownTicketGlobal > g_pivos[idx].cooldownMergeTicket);
}

void SDV4_MergeCooldownMarcarZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return;
   if(g_pivos[idx].estado == PIVO_REMOVIDO) return;
   g_mergeCooldownTicketGlobal++;
   if(g_mergeCooldownTicketGlobal <= 0) g_mergeCooldownTicketGlobal = 1;
   g_pivos[idx].cooldownMergeTicket = g_mergeCooldownTicketGlobal;
}

int ContarZonasAtivas() {
   int total = 0;
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado != PIVO_REMOVIDO) total++;
   }
   return total;
}

void SDV4_ResetarFlagsMergeTemporarias() {
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      g_pivos[i].foiMergeada = false;
   }
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

int ObterVizinhancaPivot() {
   int v = InpVizinhancaPivotBarras;
   if(v < 1) v = 1;
   if(v > 10) v = 10;
   return v;
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

string SDV4_Trim(const string s) {
   int len = StringLen(s);
   if(len <= 0) return "";
   int iIni = 0;
   while(iIni < len) {
      int ch = StringGetCharacter(s, iIni);
      if(ch > 32) break;
      iIni++;
   }
   int iFim = len - 1;
   while(iFim >= iIni) {
      int ch = StringGetCharacter(s, iFim);
      if(ch > 32) break;
      iFim--;
   }
   if(iFim < iIni) return "";
   return StringSubstr(s, iIni, iFim - iIni + 1);
}

bool SDV4_LerUltimaLinhaFeedVolumeReal(string &linha) {
   linha = "";
   if(!InpUsarVolumeRealFeed) return false;
   if(StringLen(InpArquivoVolumeRealFeed) <= 0) return false;

   int h = FileOpen(InpArquivoVolumeRealFeed, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE) {
      if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
         Print("VOLUME-REAL: não abriu arquivo feed: ", InpArquivoVolumeRealFeed, " err=", GetLastError());
      }
      return false;
   }

   string ultima = "";
   while(!FileIsEnding(h)) {
      string l = SDV4_Trim(FileReadString(h));
      if(StringLen(l) <= 0) continue;
      if(StringGetCharacter(l, 0) == '#') continue;
      ultima = l;
   }
   FileClose(h);

   if(StringLen(ultima) <= 0) return false;
   linha = ultima;
   return true;
}

bool SDV4_ParseUltimaLinhaFeedVolumeReal(const string linha,
                                         string &sym,
                                         int &periodoSeg,
                                         datetime &tempoBarra,
                                         double &volumeReal,
                                         datetime &sourceTime) {
   sym = "";
   periodoSeg = 0;
   tempoBarra = 0;
   volumeReal = 0.0;
   sourceTime = 0;

   string campos[];
   int n = StringSplit(linha, ',', campos);
   if(n < 4) return false;

   sym = SDV4_Trim(campos[0]);
   string perTxt = SDV4_Trim(campos[1]);
   string barTxt = SDV4_Trim(campos[2]);
   string volTxt = SDV4_Trim(campos[3]);
   if(StringLen(sym) <= 0 || StringLen(barTxt) <= 0 || StringLen(volTxt) <= 0) return false;

   // Ignora header acidental.
   string symUpper = sym;
   StringToUpper(symUpper);
   if(symUpper == "SYMBOL") return false;

   periodoSeg = (int)StringToInteger(perTxt);
   tempoBarra = (datetime)StringToInteger(barTxt);
   volumeReal = StringToDouble(volTxt);
   if(!MathIsValidNumber(volumeReal) || volumeReal < 0.0) return false;
   if(tempoBarra <= 0) return false;

   if(n >= 5) {
      sourceTime = (datetime)StringToInteger(SDV4_Trim(campos[4]));
      if(sourceTime < 0) sourceTime = 0;
   }
   return true;
}

bool SDV4_ObterVolumeRealFeedParaBarra(const int idxBarra,
                                       const datetime &time[],
                                       double &volumeOut) {
   volumeOut = 0.0;
   if(!InpUsarVolumeRealFeed) return false;
   if(idxBarra < 0 || idxBarra >= ArraySize(time)) return false;

   datetime tempoBarraAlvo = time[idxBarra];
   ulong agoraMs = GetTickCount();
   int refreshMs = InpVolumeRealFeedRefreshMs;
   if(refreshMs < 100) refreshMs = 100;
   if(refreshMs > 60000) refreshMs = 60000;

   if(g_volumeRealCacheBarTime == tempoBarraAlvo &&
      g_volumeRealCacheMs > 0 &&
      (agoraMs - g_volumeRealCacheMs) < (ulong)refreshMs) {
      if(g_volumeRealCacheValido) {
         volumeOut = g_volumeRealCacheValor;
         return true;
      }
      return false;
   }

   g_volumeRealCacheBarTime = tempoBarraAlvo;
   g_volumeRealCacheMs = agoraMs;
   g_volumeRealCacheValido = false;
   g_volumeRealCacheValor = 0.0;
   g_volumeRealCacheSourceTime = 0;

   string linha = "";
   if(!SDV4_LerUltimaLinhaFeedVolumeReal(linha)) return false;

   string sym = "";
   int perSeg = 0;
   datetime tBar = 0;
   double vol = 0.0;
   datetime tSrc = 0;
   if(!SDV4_ParseUltimaLinhaFeedVolumeReal(linha, sym, perSeg, tBar, vol, tSrc)) {
      if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
         Print("VOLUME-REAL: parse inválido: ", linha);
      }
      return false;
   }

   if(sym != "*" && sym != _Symbol) {
      if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
         Print("VOLUME-REAL: símbolo diferente (feed=", sym, ", chart=", _Symbol, ")");
      }
      return false;
   }

   int periodoAtual = (int)PeriodSeconds();
   if(perSeg > 0 && periodoAtual > 0 && perSeg != periodoAtual) {
      if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
         Print("VOLUME-REAL: período diferente (feed=", perSeg, ", chart=", periodoAtual, ")");
      }
      return false;
   }

   if(tBar != tempoBarraAlvo) {
      if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
         Print("VOLUME-REAL: barra diferente (feed=", TimeToString(tBar, TIME_DATE|TIME_MINUTES),
               ", alvo=", TimeToString(tempoBarraAlvo, TIME_DATE|TIME_MINUTES), ")");
      }
      return false;
   }

   int maxAtraso = InpVolumeRealFeedMaxAtrasoSeg;
   if(maxAtraso < 0) maxAtraso = 0;
   if(maxAtraso > 86400) maxAtraso = 86400;
   if(maxAtraso > 0 && tSrc > 0) {
      int atraso = (int)(TimeCurrent() - tSrc);
      if(atraso > maxAtraso) {
         if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
            Print("VOLUME-REAL: feed atrasado (", atraso, "s > ", maxAtraso, "s)");
         }
         return false;
      }
   }

   g_volumeRealCacheValido = true;
   g_volumeRealCacheValor = vol;
   g_volumeRealCacheSourceTime = tSrc;
   volumeOut = vol;

   if(InpLogVolumeRealFeed && !InpModoLowCostTotal) {
      Print("VOLUME-REAL: aplicado ", DoubleToString(vol, 0),
            " em ", TimeToString(tempoBarraAlvo, TIME_DATE|TIME_MINUTES));
   }
   return true;
}

int ObterLinhasLogEnriquecimentoNoGrafico() {
   if(InpModoLowCostTotal) return 0;
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
   if(InpModoLowCostTotal) return false;
   return InpExibirPainelBalanceCV;
}

bool DeveExibirPainelVolume() {
   if(InpModoLowCostTotal) return false;
   return InpExibirPainelVolume;
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
   if(InpModoLowCostTotal || !InpExibirLogEnriquecimentoNoGrafico) return;
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
   if(InpModoLowCostTotal || !InpExibirLogEnriquecimentoNoGrafico) return;

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
   if(InpModoLowCostTotal || !InpExibirLogEnriquecimentoNoGrafico) return;
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
   if(InpModoLowCostTotal || !InpExibirLogEnriquecimentoNoGrafico) return;

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
   if(InpModoLowCostTotal || !InpExibirLogEnriquecimentoNoGrafico) return;

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
   if(InpModoLowCostTotal || !InpExibirLogEnriquecimentoNoGrafico) return "";
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

#include "visual/SupDemVol_ModuleLinhasReferencia_v5.mqh"

#include "organizacao/SupDemVol_ModuleOrganizacaoCore_v5.mqh"

//+------------------------------------------------------------------+
int OnInit() {
   AplicarPaletaVisual();

   // Configurar buffers
   SetIndexBuffer(0, VolumeBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, VolumeColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, BandaSuperiorBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, ZeroBuffer, INDICATOR_DATA);

   if(!DeveExibirPainelVolume()) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);
      IndicatorSetInteger(INDICATOR_HEIGHT, 1);
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
   g_volumeRealCacheBarTime = 0;
   g_volumeRealCacheValor = 0.0;
   g_volumeRealCacheValido = false;
   g_volumeRealCacheMs = 0;
   g_volumeRealCacheSourceTime = 0;
   g_execCycleId = 0;
   g_execFaseAtual = SDV4_EXEC_FASE_NONE;
   g_execSolicitacaoOrganizacao = false;
   g_execMotivoSolicitacaoOrganizacao = "";
   SDV4_BookInit();
   for(int iExec = 0; iExec < SDV4_EXEC_MOD_COUNT; iExec++) {
      g_execTokenModulo[iExec] = 0;
      g_execFasePermitida[iExec] = SDV4_EXEC_FASE_NONE;
      g_execUltimoCycleModulo[iExec] = 0;
      g_execUltimoTempoModulo[iExec] = 0;
      g_execUltimaFaseModulo[iExec] = SDV4_EXEC_FASE_NONE;
   }
   
   if(!InpModoLowCostTotal) {
      Print("════════════════════════════════════════");
      Print("  Organização contínua: gatilho ", ObterGatilhoOrganizacaoZonas(),
            " | alvo ", g_numeroZonasAlvo, "/", g_numeroZonasMin,
            " | limite duro ", g_numeroZonasMax);
      Print("════════════════════════════════════════");
      Print("  🎯 COR POR VOLUME: Paleta premium de baixa saturação");
      Print("  📊 PROGRESS BAR: Mostra volume acumulado visualmente");
      Print("  ✅ MERGE IMEDIATO: ativo por regra de gap/distance");
      Print("  ✅ DISTÂNCIA MÍNIMA: ZigZag importado x ", DoubleToString(InpDistMinFatorZigZag, 2));
      Print("  ⏱️ ANTI PISCA-PISCA: ", InpTempoAssentamento, " barras");
      Print("  ✅ ALTURA MÁXIMA: ", InpMaxATRPercent, "% ATR");
      Print("  ⚠️ FILTRO RIGOROSO: SÓ barras acima desvio padrão");
      Print("════════════════════════════════════════");
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   SDV4_BookDeinit();
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

void OnBookEvent(const string &symbol) {
   SDV4_BookProcessarEvento(symbol);
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
   bool barraNova = (prev_calculated > 0 && rates_total > prev_calculated);
   if(InpModoLowCostTotal && prev_calculated > 0 && !barraNova) {
      return(rates_total);
   }
   
   // Determinar início do cálculo
   int start;
   if(prev_calculated == 0) {
      start = 0;
      g_profileDesenhado = false;
   } else {
      start = prev_calculated - 1;
      if(rates_total > prev_calculated) {
         start = prev_calculated;
         if(InpModoLowCostTotal) {
            start = prev_calculated - 1;
            if(start < 0) start = 0;
         }
      }
   }

   // Volume real externo: aplica apenas na barra alvo (aberta ou fechada).
   int idxBarraVolumeReal = -1;
   bool usarVolumeRealNaBarra = false;
   double volumeRealBarra = 0.0;
   if(InpUsarVolumeRealFeed) {
      idxBarraVolumeReal = InpVolumeRealFeedBarraFechada ? (rates_total - 2) : (rates_total - 1);
      if(idxBarraVolumeReal >= 0 && idxBarraVolumeReal < rates_total) {
         usarVolumeRealNaBarra = SDV4_ObterVolumeRealFeedParaBarra(idxBarraVolumeReal, time, volumeRealBarra);
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
      double volCalc = (double)tick_volume[i];
      if(usarVolumeRealNaBarra && i == idxBarraVolumeReal) {
         volCalc = volumeRealBarra;
      }
      if(!MathIsValidNumber(volCalc) || volCalc < 0.0) volCalc = 0.0;
      VolumeBuffer[i] = volCalc;
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
   SDV4_BookOnCalculate(rates_total, time, close);
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calcular percentuais de volume para progress bars               |
//+------------------------------------------------------------------+
#include "enriquecimento/SupDemVol_ModulePercentuais_v5.mqh"
#include "visual/SupDemVol_ModuleRuntimeOps_v5.mqh"

//+------------------------------------------------------------------+
//| Desenhar os pivôs com PROGRESS BARS no gráfico                 |
//+------------------------------------------------------------------+
#include "visual/SupDemVol_ModuleVisual_v5.mqh"

#include "SupDemVol_ModuleCentral_v5.mqh"

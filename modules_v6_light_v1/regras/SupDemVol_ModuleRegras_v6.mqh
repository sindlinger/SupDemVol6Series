#ifndef SUPDEMVOL_MODULE_REGRAS_V6_MQH
#define SUPDEMVOL_MODULE_REGRAS_V6_MQH

enum ENUM_SDV4_REGRA_MODULO {
   SDV4_REGRA_MOD_CENTRAL = 0,
   SDV4_REGRA_MOD_ORGANIZACAO = 1,
   SDV4_REGRA_MOD_CRIACAO = 2,
   SDV4_REGRA_MOD_MERGE = 3,
   SDV4_REGRA_MOD_ENRIQUECIMENTO = 4,
   SDV4_REGRA_MOD_VISUAL = 5
};

enum ENUM_SDV4_REGRA_ACAO {
   SDV4_REGRA_ACAO_ENTRADA = 0,
   SDV4_REGRA_ACAO_ORGANIZAR = 1,
   SDV4_REGRA_ACAO_CRIAR_ZONA = 2,
   SDV4_REGRA_ACAO_MERGE_ZONA = 3,
   SDV4_REGRA_ACAO_ENRIQUECER_ZONA = 4,
   SDV4_REGRA_ACAO_CALCULAR_PERCENTUAIS = 5,
   SDV4_REGRA_ACAO_DESENHAR = 6,
   SDV4_REGRA_ACAO_ATUALIZAR_COORD = 7
};

string SDV4_RegraNomeModulo(const ENUM_SDV4_REGRA_MODULO modulo) {
   if(modulo == SDV4_REGRA_MOD_ORGANIZACAO) return "ORGANIZACAO";
   if(modulo == SDV4_REGRA_MOD_CRIACAO) return "CRIACAO";
   if(modulo == SDV4_REGRA_MOD_MERGE) return "MERGE";
   if(modulo == SDV4_REGRA_MOD_ENRIQUECIMENTO) return "ENRIQUECIMENTO";
   if(modulo == SDV4_REGRA_MOD_VISUAL) return "VISUAL";
   return "CENTRAL";
}

string SDV4_RegraNomeAcao(const ENUM_SDV4_REGRA_ACAO acao) {
   if(acao == SDV4_REGRA_ACAO_ENTRADA) return "ENTRADA";
   if(acao == SDV4_REGRA_ACAO_ORGANIZAR) return "ORGANIZAR";
   if(acao == SDV4_REGRA_ACAO_CRIAR_ZONA) return "CRIAR_ZONA";
   if(acao == SDV4_REGRA_ACAO_MERGE_ZONA) return "MERGE_ZONA";
   if(acao == SDV4_REGRA_ACAO_ENRIQUECER_ZONA) return "ENRIQUECER_ZONA";
   if(acao == SDV4_REGRA_ACAO_CALCULAR_PERCENTUAIS) return "CALCULAR_PERCENTUAIS";
   if(acao == SDV4_REGRA_ACAO_DESENHAR) return "DESENHAR";
   if(acao == SDV4_REGRA_ACAO_ATUALIZAR_COORD) return "ATUALIZAR_COORD";
   return "ACAO";
}

ENUM_SDV4_REGRA_MODULO SDV4_RegraMapearModuloExec(const int moduloExec) {
   if(moduloExec == SDV4_EXEC_MOD_ORGANIZACAO) return SDV4_REGRA_MOD_ORGANIZACAO;
   if(moduloExec == SDV4_EXEC_MOD_CRIACAO) return SDV4_REGRA_MOD_CRIACAO;
   if(moduloExec == SDV4_EXEC_MOD_MERGE) return SDV4_REGRA_MOD_MERGE;
   return SDV4_REGRA_MOD_CENTRAL;
}

bool SDV4_RegraIndiceValido(const int idx, const bool exigirAtivo = true) {
   if(idx < 0 || idx >= g_numeroZonas) return false;
   if(exigirAtivo && g_pivos[idx].estado == PIVO_REMOVIDO) return false;
   return true;
}

bool SDV4_RegrasLowCostTotalAtivo() {
   return InpModoLowCostTotal;
}

bool SDV4_RegrasLogDetalhadoAtivo() {
   if(SDV4_RegrasLowCostTotalAtivo()) return false;
   return InpLogDetalhado;
}

bool SDV4_RegrasLogBloqueiosMergeAtivo() {
   if(SDV4_RegrasLowCostTotalAtivo()) return false;
   return InpLogBloqueiosMerge;
}

void SDV4_RegrasLogBloqueioMerge(const string motivo,
                                 const int idxA = -1,
                                 const int idxB = -1,
                                 const string extra = "") {
   if(!SDV4_RegrasLogBloqueiosMergeAtivo()) return;
   string msg = "MERGE[BLOCK][" + motivo + "]";
   if(idxA >= 0 && idxA < g_numeroZonas) {
      msg += StringFormat(" A=Z%d(%.5f)", idxA + 1, g_pivos[idxA].preco);
   }
   if(idxB >= 0 && idxB < g_numeroZonas) {
      msg += StringFormat(" B=Z%d(%.5f)", idxB + 1, g_pivos[idxB].preco);
   }
   if(StringLen(extra) > 0) msg += " | " + extra;
   Print(msg);
}

bool SDV4_RegrasHabilitarTravaAncora() {
   return InpHabilitarTravaAncora;
}

bool SDV4_RegrasAtualizarUIApenasBarraNova() {
   if(SDV4_RegrasLowCostTotalAtivo()) return true;
   return InpAtualizarUIApenasBarraNova;
}

bool SDV4_RegrasOrganizacaoEmBarraFechada() {
   return InpOrganizacaoEmBarraFechada;
}

int SDV4_RegrasPeriodoMedia() {
   int p = InpPeriodoMedia;
   if(p < 1) p = 1;
   if(p > 10000) p = 10000;
   return p;
}

ENUM_MODO_CONFLITO_SINAL_ENRIQ SDV4_RegrasModoConflitoSinalEnriquecimento() {
   return InpModoConflitoSinalEnriquecimento;
}

bool SDV4_RegrasModoConflitoMixSombra() {
   return (SDV4_RegrasModoConflitoSinalEnriquecimento() == CONFLITO_SINAL_MIX_SOMBRA);
}

bool SDV4_RegrasModoConflitoSubtrair() {
   return (SDV4_RegrasModoConflitoSinalEnriquecimento() == CONFLITO_SINAL_SUBTRAIR);
}

bool SDV4_RegrasEnriquecimentoToqueSomenteAcimaBanda() {
   return InpEnriquecimentoToqueSomenteAcimaBanda;
}

int SDV4_RegrasTempoAssentamento() {
   int t = InpTempoAssentamento;
   if(t < 1) t = 1;
   if(t > 5000) t = 5000;
   return t;
}

double SDV4_RegrasDistanciaMinATR() {
   double v = InpDistanciaMinATR;
   if(!MathIsValidNumber(v) || v < 0.0) v = 0.0;
   if(v > 1000.0) v = 1000.0;
   return v;
}

double SDV4_RegrasFatorAlturaBarraOrigem() {
   double f = InpFatorAlturaBarraOrigem;
   if(!MathIsValidNumber(f)) f = 0.35;
   if(f < 0.01) f = 0.01;
   if(f > 5.0) f = 5.0;
   return f;
}

double SDV4_RegrasMaxATRPercent() {
   double p = InpMaxATRPercent;
   if(!MathIsValidNumber(p)) p = 35.0;
   if(p < 0.0) p = 0.0;
   if(p > 5000.0) p = 5000.0;
   return p;
}

double SDV4_RegrasEscalaRelativaFatorFaixaDia() {
   double f = InpEscalaRelativaFatorFaixaDia;
   if(!MathIsValidNumber(f)) f = 0.10;
   if(f < 0.01) f = 0.01;
   if(f > 1.00) f = 1.00;
   return f;
}

double SDV4_RegrasEscalaRelativaMinPctPreco() {
   double p = InpEscalaRelativaMinPctPreco;
   if(!MathIsValidNumber(p)) p = 0.05;
   if(p < 0.0001) p = 0.0001;
   if(p > 5.0) p = 5.0;
   return p;
}

bool SDV4_RegrasEscalaRelativaSemATR() {
   return InpEscalaRelativaSemATR;
}

double SDV4_RegrasFatorGapPorSomaMerge() {
   double f = InpFatorGapPorSomaMerge;
   if(!MathIsValidNumber(f)) f = 1.0;
   if(f < 0.0) f = 0.0;
   if(f > 1.0) f = 1.0;
   return f;
}

double SDV4_RegrasFatorAbsorcaoMerge() {
   double f = InpFatorAbsorcaoMerge;
   if(!MathIsValidNumber(f)) f = 0.30;
   if(f < 0.0) f = 0.0;
   if(f > 1.0) f = 1.0;
   return f;
}

int SDV4_RegrasOrganizacaoGatilhoZonas() {
   int v = InpOrganizacaoGatilhoZonas;
   if(v < 2) v = 2;
   if(v > 20) v = 20;
   return v;
}

int SDV4_RegrasOrganizacaoLimiteDuroZonas() {
   int v = InpOrganizacaoLimiteDuroZonas;
   if(v < 2) v = 2;
   if(v > 20) v = 20;
   return v;
}

int SDV4_RegrasOrganizacaoAlvoNormal() {
   int alvo = InpOrganizacaoAlvoNormal;
   if(alvo < 1) alvo = 1;
   int limite = SDV4_RegrasOrganizacaoLimiteDuroZonas();
   if(alvo > limite) alvo = limite;
   return alvo;
}

int SDV4_RegrasOrganizacaoAlvoSemGap() {
   int alvo = InpOrganizacaoAlvoSemGap;
   if(alvo < 1) alvo = 1;
   int alvoNormal = SDV4_RegrasOrganizacaoAlvoNormal();
   if(alvo > alvoNormal) alvo = alvoNormal;
   return alvo;
}

int SDV4_RegrasOrganizacaoMaxAcoesPorBarra() {
   int n = InpOrganizacaoMaxAcoesPorBarra;
   if(n < 1) n = 1;
   if(n > 100) n = 100;
   return n;
}

double SDV4_RegrasOrganizacaoFatorGapMaiorZona() {
   double f = InpOrganizacaoFatorGapMaiorZona;
   if(!MathIsValidNumber(f)) f = 2.0;
   if(f < 0.10) f = 0.10;
   if(f > 10.0) f = 10.0;
   return f;
}

double SDV4_RegrasShvedFractalFastFactor() {
   double f = InpShvedFractalFastFactor;
   if(!MathIsValidNumber(f) || f < 1.0) f = 1.0;
   if(f > 20.0) f = 20.0;
   return f;
}

double SDV4_RegrasShvedFractalSlowFactor() {
   double f = InpShvedFractalSlowFactor;
   if(!MathIsValidNumber(f) || f < 1.0) f = 1.0;
   if(f > 20.0) f = 20.0;
   return f;
}

int SDV4_RegrasShvedLookbackBarras() {
   int lookback = InpShvedLookbackBarras;
   if(lookback < 100) lookback = 100;
   if(lookback > 5000) lookback = 5000;
   return lookback;
}

bool SDV4_RegrasPercentualNominalSimples() {
   return InpPercentualNominalSimples;
}

bool SDV4_RegrasConservacaoVolumeAltoEstrita() {
   return InpConservacaoVolumeAltoEstrita;
}

bool SDV4_RegrasAplicarRateioRetroativoNasZonas() {
   return InpAplicarRateioRetroativoNasZonas;
}

double SDV4_RegrasVolumeRatioMedio() {
   double v = InpVolumeRatioMedio;
   if(!MathIsValidNumber(v) || v <= 0.0) v = 1.5;
   return v;
}

double SDV4_RegrasVolumeRatioAlto() {
   double v = InpVolumeRatioAlto;
   if(!MathIsValidNumber(v) || v <= 0.0) v = 2.0;
   return v;
}

double SDV4_RegrasVolumeRatioExtremo() {
   double v = InpVolumeRatioExtremo;
   if(!MathIsValidNumber(v) || v <= 0.0) v = 3.0;
   return v;
}

bool SDV4_RegrasExibirValoresZona() {
   if(SDV4_RegrasLowCostTotalAtivo()) return false;
   return InpExibirValoresZona;
}

double SDV4_RegrasPosicaoVerticalTextoZona() {
   double p = InpPosicaoVerticalTextoZona;
   if(!MathIsValidNumber(p)) p = 0.50;
   if(p < 0.0) p = 0.0;
   if(p > 1.0) p = 1.0;
   return p;
}

int SDV4_RegrasDeslocamentoTextoBarras() {
   int d = InpDeslocamentoTextoBarras;
   if(d < -500) d = -500;
   if(d > 500) d = 500;
   return d;
}

ENUM_POSICAO_HORIZONTAL_TEXTO_ZONA SDV4_RegrasPosicaoHorizontalTextoZona() {
   return InpPosicaoHorizontalTextoZona;
}

uint SDV4_RegrasTransparenciaZonas() {
   int v = InpTransparenciaZonas;
   if(v < 0) v = 0;
   if(v > 255) v = 255;
   return (uint)v;
}

bool SDV4_RegrasMostrarLinhaMaiorMaxima() {
   return InpMostrarLinhaMaiorMaxima;
}

int SDV4_RegrasPeriodoLinhaMaiorMaxima() {
   int p = InpPeriodoLinhaMaiorMaxima;
   if(p < 1) p = 1;
   if(p > 5000) p = 5000;
   return p;
}

color SDV4_RegrasCorLinhaMaiorMaxima() {
   return InpCorLinhaMaiorMaxima;
}

ENUM_LINE_STYLE SDV4_RegrasEstiloLinhaMaiorMaxima() {
   return InpEstiloLinhaMaiorMaxima;
}

int SDV4_RegrasLarguraLinhaMaiorMaxima() {
   int largura = InpLarguraLinhaMaiorMaxima;
   if(largura < 1) largura = 1;
   if(largura > 5) largura = 5;
   return largura;
}

bool SDV4_RegrasMostrarLinhaMenorMinima() {
   return InpMostrarLinhaMenorMinima;
}

int SDV4_RegrasPeriodoLinhaMenorMinima() {
   int p = InpPeriodoLinhaMenorMinima;
   if(p < 1) p = 1;
   if(p > 5000) p = 5000;
   return p;
}

color SDV4_RegrasCorLinhaMenorMinima() {
   return InpCorLinhaMenorMinima;
}

ENUM_LINE_STYLE SDV4_RegrasEstiloLinhaMenorMinima() {
   return InpEstiloLinhaMenorMinima;
}

int SDV4_RegrasLarguraLinhaMenorMinima() {
   int largura = InpLarguraLinhaMenorMinima;
   if(largura < 1) largura = 1;
   if(largura > 5) largura = 5;
   return largura;
}

bool SDV4_RegrasMaximaReal() {
   return InpMaximaReal;
}

void SDV4_RegrasLogBloqueio(const ENUM_SDV4_REGRA_MODULO modulo,
                            const ENUM_SDV4_REGRA_ACAO acao,
                            const string origem,
                            const string motivo) {
   if(!SDV4_RegrasLogDetalhadoAtivo()) return;
   Print("REGRAS[BLOCK] ", SDV4_RegraNomeModulo(modulo), "/", SDV4_RegraNomeAcao(acao),
         " origem=", origem, " motivo=", motivo);
}

bool SDV4_RegrasPermitirEntradaModulo(const int moduloExec,
                                      const datetime tempoEvento,
                                      const string origem) {
   ENUM_SDV4_REGRA_MODULO modulo = SDV4_RegraMapearModuloExec(moduloExec);
   if(tempoEvento <= 0) {
      SDV4_RegrasLogBloqueio(modulo, SDV4_REGRA_ACAO_ENTRADA, origem, "tempo_evento_invalido");
      return false;
   }
   if(!SDV4_ExecAutorizarEntrada(moduloExec, tempoEvento, origem)) {
      SDV4_RegrasLogBloqueio(modulo, SDV4_REGRA_ACAO_ENTRADA, origem, "gate_exec");
      return false;
   }
   return true;
}

bool SDV4_RegrasPermitirCriacaoZona(const int idxSlot,
                                    const datetime tempoEvento,
                                    const double volume,
                                    const string origem) {
   if(tempoEvento <= 0) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_CRIACAO, SDV4_REGRA_ACAO_CRIAR_ZONA, origem, "tempo_evento_invalido");
      return false;
   }
   if(volume <= 1e-9) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_CRIACAO, SDV4_REGRA_ACAO_CRIAR_ZONA, origem, "volume_invalido");
      return false;
   }
   if(idxSlot < 0 || idxSlot >= g_numeroZonas) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_CRIACAO, SDV4_REGRA_ACAO_CRIAR_ZONA, origem, "slot_invalido");
      return false;
   }
   if(g_pivos[idxSlot].estado != PIVO_REMOVIDO) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_CRIACAO, SDV4_REGRA_ACAO_CRIAR_ZONA, origem, "slot_ocupado");
      return false;
   }
   return true;
}

bool SDV4_RegrasPermitirMergeZona(const int idxZona,
                                  const datetime tempoEvento,
                                  const double volume,
                                  const string origem) {
   if(tempoEvento <= 0) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_MERGE, SDV4_REGRA_ACAO_MERGE_ZONA, origem, "tempo_evento_invalido");
      return false;
   }
   if(volume <= 1e-9) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_MERGE, SDV4_REGRA_ACAO_MERGE_ZONA, origem, "volume_invalido");
      return false;
   }
   if(!SDV4_RegraIndiceValido(idxZona, true)) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_MERGE, SDV4_REGRA_ACAO_MERGE_ZONA, origem, "zona_invalida");
      return false;
   }
   return true;
}

bool SDV4_RegrasPermitirEnriquecimentoZona(const int idxZona,
                                           const datetime tempoEvento,
                                           const double volume,
                                           const string origem) {
   if(tempoEvento <= 0) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_ENRIQUECIMENTO, SDV4_REGRA_ACAO_ENRIQUECER_ZONA, origem, "tempo_evento_invalido");
      return false;
   }
   if(volume <= 1e-9) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_ENRIQUECIMENTO, SDV4_REGRA_ACAO_ENRIQUECER_ZONA, origem, "volume_invalido");
      return false;
   }
   if(!SDV4_RegraIndiceValido(idxZona, true)) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_ENRIQUECIMENTO, SDV4_REGRA_ACAO_ENRIQUECER_ZONA, origem, "zona_invalida");
      return false;
   }
   return true;
}

bool SDV4_RegrasPermitirAcaoVisual(const ENUM_SDV4_REGRA_ACAO acao,
                                   const int rates_total,
                                   const string origem) {
   if(rates_total < 1) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_VISUAL, acao, origem, "rates_total");
      return false;
   }
   if(!g_pivosInicializados) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_VISUAL, acao, origem, "sem_pivos");
      return false;
   }
   return true;
}

bool SDV4_RegrasPermitirCalculoPercentuais(const int rates_total, const string origem) {
   if(rates_total < 1) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_ENRIQUECIMENTO, SDV4_REGRA_ACAO_CALCULAR_PERCENTUAIS, origem, "rates_total");
      return false;
   }
   if(!g_pivosInicializados) {
      SDV4_RegrasLogBloqueio(SDV4_REGRA_MOD_ENRIQUECIMENTO, SDV4_REGRA_ACAO_CALCULAR_PERCENTUAIS, origem, "sem_pivos");
      return false;
   }
   return true;
}

#endif

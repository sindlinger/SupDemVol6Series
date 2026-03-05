#ifndef SUPDEMVOL_MODULE_ORGANIZACAO_CORE_V5_MQH
#define SUPDEMVOL_MODULE_ORGANIZACAO_CORE_V5_MQH

#include "SupDemVol_ModuleShvedFractal_v1.mqh"

int ObterGatilhoOrganizacaoZonas() {
   int v = SDV4_RegrasOrganizacaoGatilhoZonas();
   if(v < 2) v = 2;
   if(v > 20) v = 20;
   return v;
}

int ObterLimiteDuroOrganizacaoZonas() {
   int v = SDV4_RegrasOrganizacaoLimiteDuroZonas();
   if(v < 2) v = 2;
   if(v > 20) v = 20;
   return v;
}

int ObterAlvoNormalOrganizacaoZonas() {
   int alvo = SDV4_RegrasOrganizacaoAlvoNormal();
   if(alvo < 1) alvo = 1;
   int limite = ObterLimiteDuroOrganizacaoZonas();
   if(alvo > limite) alvo = limite;
   return alvo;
}

int ObterAlvoSemGapOrganizacaoZonas() {
   int alvo = SDV4_RegrasOrganizacaoAlvoSemGap();
   int alvoNormal = ObterAlvoNormalOrganizacaoZonas();
   if(alvo < 1) alvo = 1;
   if(alvo > alvoNormal) alvo = alvoNormal;
   return alvo;
}

int ObterMaxAcoesOrganizacaoPorBarra() {
   int n = SDV4_RegrasOrganizacaoMaxAcoesPorBarra();
   if(n < 1) n = 1;
   if(n > 100) n = 100;
   return n;
}

double ObterFatorGapMaiorZonaOrganizacao() {
   double f = SDV4_RegrasOrganizacaoFatorGapMaiorZona();
   if(!MathIsValidNumber(f)) f = 2.0;
   if(f < 0.10) f = 0.10;
   if(f > 10.0) f = 10.0;
   return f;
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
   // Mantém compatibilidade: trava só reafirma a âncora atual.
   // Como a organização atualiza a âncora após merge/reposicionamento,
   // não há retorno para posição antiga.
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(!g_pivos[i].ancoraInicializada) {
         DefinirAncoraPivo(i);
         continue;
      }
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

double SDV4_AlturaZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return ObterAlturaMinimaZonaPreco();
   double h = MathAbs(g_pivos[idx].precoSuperior - g_pivos[idx].precoInferior);
   double hMin = ObterAlturaMinimaZonaPreco();
   if(h < hMin) h = hMin;
   return h;
}

bool SDV4_GapElegivelPar(const int idxA,
                         const int idxB,
                         double &gap,
                         double &limiar) {
   gap = DistanciaEntreFaixas(g_pivos[idxA].precoSuperior,
                              g_pivos[idxA].precoInferior,
                              g_pivos[idxB].precoSuperior,
                              g_pivos[idxB].precoInferior);
   double hA = SDV4_AlturaZona(idxA);
   double hB = SDV4_AlturaZona(idxB);
   double hMaior = MathMax(hA, hB);
   limiar = hMaior * ObterFatorGapMaiorZonaOrganizacao();
   if(limiar < ObterAlturaMinimaZonaPreco()) limiar = ObterAlturaMinimaZonaPreco();
   return (gap < limiar);
}

bool SDV4_ExisteParGapElegivel() {
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      for(int j = i + 1; j < g_numeroZonas; j++) {
         if(g_pivos[j].estado == PIVO_REMOVIDO) continue;
         double gap = 0.0, limiar = 0.0;
         if(SDV4_GapElegivelPar(i, j, gap, limiar)) return true;
      }
   }
   return false;
}

int SDV4_SelecionarZonaMaisDistante(const double precoReferencia,
                                    const datetime tempoEvento,
                                    const bool permitirRecemCriada = false) {
   int idx = -1;
   double melhor = -1.0;

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(!permitirRecemCriada && ZonaRecemCriadaProtegida(i, tempoEvento)) continue;
      double d = MathAbs(g_pivos[i].preco - precoReferencia);
      if(d > melhor) {
         melhor = d;
         idx = i;
      }
   }

   if(idx >= 0) return idx;
   if(permitirRecemCriada) return -1;

   // Fallback: se todas forem recém-criadas, ainda assim pega a mais distante.
   return SDV4_SelecionarZonaMaisDistante(precoReferencia, tempoEvento, true);
}

bool SDV4_PosicaoLivreFaixa(const double sup,
                            const double inf,
                            const int idxIgnorarA,
                            const int idxIgnorarB,
                            const double distMinima) {
   for(int i = 0; i < g_numeroZonas; i++) {
      if(i == idxIgnorarA || i == idxIgnorarB) continue;
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      double d = DistanciaEntreFaixas(sup,
                                      inf,
                                      g_pivos[i].precoSuperior,
                                      g_pivos[i].precoInferior);
      if(d < distMinima - 1e-9) return false;
   }
   return true;
}

bool SDV4_AjustarParaPosicaoLivre(const double supBase,
                                  const double infBase,
                                  const int idxIgnorarA,
                                  const int idxIgnorarB,
                                  const double distMinimaEntrada,
                                  double &supOut,
                                  double &infOut) {
   double hMin = ObterAlturaMinimaZonaPreco();
   double distMinima = distMinimaEntrada;
   if(!MathIsValidNumber(distMinima) || distMinima <= 0.0) {
      distMinima = MathMax(hMin * 0.50, _Point * 2.0);
   }
   double passo = MathMax(MathMax(hMin * 0.50, _Point * 2.0), distMinima * 0.50);

   if(SDV4_PosicaoLivreFaixa(supBase, infBase, idxIgnorarA, idxIgnorarB, distMinima)) {
      supOut = supBase;
      infOut = infBase;
      return true;
   }

   int maxIter = 60;
   for(int k = 1; k <= maxIter; k++) {
      double delta = passo * (double)k;

      double supUp = supBase + delta;
      double infUp = infBase + delta;
      if(SDV4_PosicaoLivreFaixa(supUp, infUp, idxIgnorarA, idxIgnorarB, distMinima)) {
         supOut = supUp;
         infOut = infUp;
         return true;
      }

      double supDn = supBase - delta;
      double infDn = infBase - delta;
      if(SDV4_PosicaoLivreFaixa(supDn, infDn, idxIgnorarA, idxIgnorarB, distMinima)) {
         supOut = supDn;
         infOut = infDn;
         return true;
      }
   }

   return false;
}

bool SDV4_AjustarParaPosicaoLivre(const double supBase,
                                  const double infBase,
                                  const int idxIgnorarA,
                                  const int idxIgnorarB,
                                  double &supOut,
                                  double &infOut) {
   double hMin = ObterAlturaMinimaZonaPreco();
   double distMinimaPadrao = MathMax(hMin * 0.50, _Point * 2.0);
   return SDV4_AjustarParaPosicaoLivre(supBase,
                                       infBase,
                                       idxIgnorarA,
                                       idxIgnorarB,
                                       distMinimaPadrao,
                                       supOut,
                                       infOut);
}

bool SDV4_SelecionarParParaMerge(const double precoReferencia,
                                 const datetime tempoEvento,
                                 const int idxZonaDistante,
                                 const bool priorizarDistante,
                                 int &idxKeep,
                                 int &idxDrop,
                                 double &gapEscolhido) {
   idxKeep = -1;
   idxDrop = -1;
   gapEscolhido = DBL_MAX;

   double melhorScore = DBL_MAX;
   int bloqueiosCooldownZona = 0;
   int bloqueiosCooldownPar = 0;

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(!SDV4_MergeCooldownPodeMesclarZona(i)) {
         bloqueiosCooldownZona++;
         continue;
      }
      for(int j = i + 1; j < g_numeroZonas; j++) {
         if(g_pivos[j].estado == PIVO_REMOVIDO) continue;
         if(!SDV4_MergeCooldownPodeMesclarZona(j)) {
            bloqueiosCooldownPar++;
            continue;
         }

         if(priorizarDistante && idxZonaDistante >= 0 && i != idxZonaDistante && j != idxZonaDistante) continue;

         double gap = 0.0, limiar = 0.0;
         if(!SDV4_GapElegivelPar(i, j, gap, limiar)) continue;

         int keep = i;
         int drop = j;

         double forcaI = (MathMax(0.0, g_pivos[i].volumeDistribuicao) * 0.70) +
                         (MathMax(0.0, g_pivos[i].volumeTotal) * 0.25) +
                         (ObterForcaFractalZona(i) * 0.05);
         double forcaJ = (MathMax(0.0, g_pivos[j].volumeDistribuicao) * 0.70) +
                         (MathMax(0.0, g_pivos[j].volumeTotal) * 0.25) +
                         (ObterForcaFractalZona(j) * 0.05);

         if(forcaJ > forcaI + 1e-9) {
            keep = j;
            drop = i;
         } else if(MathAbs(forcaJ - forcaI) <= 1e-9) {
            double dI = MathAbs(g_pivos[i].preco - precoReferencia);
            double dJ = MathAbs(g_pivos[j].preco - precoReferencia);
            if(dJ < dI) {
               keep = j;
               drop = i;
            }
         }

         if(ZonaRecemCriadaProtegida(drop, tempoEvento)) {
            if(!ZonaRecemCriadaProtegida(keep, tempoEvento)) {
               int tmp = keep;
               keep = drop;
               drop = tmp;
            }
         }

         if(ZonaRecemCriadaProtegida(drop, tempoEvento)) continue;

         double volumePar = MathMax(0.0, g_pivos[i].volumeDistribuicao) + MathMax(0.0, g_pivos[j].volumeDistribuicao);
         double score = gap - (volumePar * 1e-9);

         if(score < melhorScore - 1e-9) {
            melhorScore = score;
            idxKeep = keep;
            idxDrop = drop;
            gapEscolhido = gap;
         }
      }
   }

   if(idxKeep < 0 && (bloqueiosCooldownZona > 0 || bloqueiosCooldownPar > 0)) {
      SDV4_RegrasLogBloqueioMerge("COOLDOWN-SELECAO",
                                  -1,
                                  -1,
                                  StringFormat("bloqZona=%d bloqPar=%d",
                                               bloqueiosCooldownZona,
                                               bloqueiosCooldownPar));
   }
   return (idxKeep >= 0 && idxDrop >= 0 && idxKeep != idxDrop);
}

bool AbsorverZonaSemMoverAncora(const int idxKeep, const int idxDrop, const datetime tempoEvento) {
   if(idxKeep < 0 || idxKeep >= g_numeroZonas) return false;
   if(idxDrop < 0 || idxDrop >= g_numeroZonas) return false;
   if(idxKeep == idxDrop) return false;
   if(g_pivos[idxKeep].estado == PIVO_REMOVIDO) return false;
   if(g_pivos[idxDrop].estado == PIVO_REMOVIDO) return false;
   if(!SDV4_MergeCooldownPodeMesclarZona(idxKeep)) {
      SDV4_RegrasLogBloqueioMerge("COOLDOWN-KEEP",
                                  idxKeep,
                                  idxDrop,
                                  StringFormat("ticket=%I64d global=%I64d",
                                               g_pivos[idxKeep].cooldownMergeTicket,
                                               g_mergeCooldownTicketGlobal));
      return false;
   }
   if(!SDV4_MergeCooldownPodeMesclarZona(idxDrop)) {
      SDV4_RegrasLogBloqueioMerge("COOLDOWN-DROP",
                                  idxKeep,
                                  idxDrop,
                                  StringFormat("ticket=%I64d global=%I64d",
                                               g_pivos[idxDrop].cooldownMergeTicket,
                                               g_mergeCooldownTicketGlobal));
      return false;
   }

   PivoAtivo keep = g_pivos[idxKeep];
   PivoAtivo drop = g_pivos[idxDrop];

   double supEnvelope = MathMax(MathMax(keep.precoSuperior, keep.precoInferior),
                                MathMax(drop.precoSuperior, drop.precoInferior));
   double infEnvelope = MathMin(MathMin(keep.precoSuperior, keep.precoInferior),
                                MathMin(drop.precoSuperior, drop.precoInferior));
   double altura = supEnvelope - infEnvelope;
   double alturaMin = ObterAlturaMinimaZonaPreco();
   if(altura < alturaMin) altura = alturaMin;
   double atrRefMerge = 0.0;
   if(keep.atr > 0.0 && drop.atr > 0.0) atrRefMerge = (keep.atr + drop.atr) * 0.5;
   else atrRefMerge = MathMax(keep.atr, drop.atr);
   if(atrRefMerge <= 0.0) atrRefMerge = MathAbs(keep.preco - drop.preco);
   if(atrRefMerge <= 0.0) atrRefMerge = MathAbs(supEnvelope - infEnvelope);
   double alturaMaxPermitida = ObterAlturaMaximaPermitidaMerge(atrRefMerge);
   if(MathIsValidNumber(alturaMaxPermitida) && alturaMaxPermitida > 0.0 && alturaMaxPermitida + 1e-9 < alturaMin) {
      SDV4_RegrasLogBloqueioMerge("ALTURA-MAX<MIN",
                                  idxKeep,
                                  idxDrop,
                                  StringFormat("hMin=%.5f hMax=%.5f atrRef=%.5f",
                                               alturaMin,
                                               alturaMaxPermitida,
                                               atrRefMerge));
      return false;
   }
   if(MathIsValidNumber(alturaMaxPermitida) && alturaMaxPermitida > 0.0) {
      if(altura > alturaMaxPermitida) altura = alturaMaxPermitida;
      if(altura < alturaMin) altura = MathMin(alturaMin, alturaMaxPermitida);
   }
   if(altura < alturaMin) altura = alturaMin;
   double distMinPosMerge = MathMax(alturaMin,
                                    ObterLimiarDistanciaATR(atrRefMerge, SDV4_RegrasDistanciaMinATR()) * 0.35);
   if(!MathIsValidNumber(distMinPosMerge) || distMinPosMerge <= 0.0)
      distMinPosMerge = MathMax(alturaMin, _Point * 2.0);

   double wk = MathMax(1.0, keep.volumeDistribuicao);
   double wd = MathMax(1.0, drop.volumeDistribuicao);
   double pk = keep.ancoraInicializada ? keep.ancoraPreco : keep.preco;
   double pd = drop.ancoraInicializada ? drop.ancoraPreco : drop.preco;
   double precoAlvoAncora = ((pk * wk) + (pd * wd)) / (wk + wd);

   double precoAncoraShved = 0.0;
   ENUM_LINE_TYPE tipoAncoraShved = LINE_TOP;
   bool achouShved = SDV4_ShvedEscolherAncoraMerge(precoAlvoAncora,
                                                   precoAncoraShved,
                                                   tipoAncoraShved);

   double novoSup = supEnvelope;
   double novoInf = infEnvelope;

   if(achouShved) {
      if(tipoAncoraShved == LINE_TOP) {
         novoSup = precoAncoraShved;
         novoInf = precoAncoraShved - altura;
      } else {
         novoInf = precoAncoraShved;
         novoSup = precoAncoraShved + altura;
      }

      double supLivre = novoSup;
      double infLivre = novoInf;
      if(SDV4_AjustarParaPosicaoLivre(novoSup, novoInf, idxKeep, idxDrop, distMinPosMerge, supLivre, infLivre)) {
         novoSup = supLivre;
         novoInf = infLivre;
      } else {
         SDV4_RegrasLogBloqueioMerge("DIST-SHVED-SEM-ESPACO",
                                     idxKeep,
                                     idxDrop,
                                     StringFormat("distMin=%.5f sup=%.5f inf=%.5f",
                                                  distMinPosMerge,
                                                  novoSup,
                                                  novoInf));
         return false;
      }
   }

   if(!SDV4_PosicaoLivreFaixa(novoSup, novoInf, idxKeep, idxDrop, distMinPosMerge)) {
      double supLivre = novoSup;
      double infLivre = novoInf;
      if(!SDV4_AjustarParaPosicaoLivre(novoSup, novoInf, idxKeep, idxDrop, distMinPosMerge, supLivre, infLivre)) {
         SDV4_RegrasLogBloqueioMerge("DIST-FINAL-SEM-ESPACO",
                                     idxKeep,
                                     idxDrop,
                                     StringFormat("distMin=%.5f sup=%.5f inf=%.5f",
                                                  distMinPosMerge,
                                                  novoSup,
                                                  novoInf));
         return false;
      }
      novoSup = supLivre;
      novoInf = infLivre;
   }

   double precoRef = 0.0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_BID, precoRef) || precoRef <= 0.0) {
      precoRef = g_pivos[idxKeep].preco;
   }

   double volumeBuy = keep.volumeBuy + drop.volumeBuy;
   double volumeSell = keep.volumeSell + drop.volumeSell;

   ENUM_LINE_TYPE tipoFinal = keep.tipo;
   if(novoSup < precoRef) tipoFinal = LINE_BOTTOM;
   else if(novoInf > precoRef) tipoFinal = LINE_TOP;
   else tipoFinal = (volumeBuy >= volumeSell) ? LINE_BOTTOM : LINE_TOP;

   g_pivos[idxKeep].precoSuperior = novoSup;
   g_pivos[idxKeep].precoInferior = novoInf;
   g_pivos[idxKeep].preco = (tipoFinal == LINE_TOP) ? novoSup : novoInf;
   g_pivos[idxKeep].tipo = tipoFinal;
   g_pivos[idxKeep].tipoMajoritario = tipoFinal;
   g_pivos[idxKeep].corAtual = ObterCorZona(tipoFinal);

   g_pivos[idxKeep].tempoInicio = MathMin(keep.tempoInicio, drop.tempoInicio);
   g_pivos[idxKeep].tempoMaisRecente = MathMax(MathMax(keep.tempoMaisRecente, drop.tempoMaisRecente), tempoEvento);
   g_pivos[idxKeep].ultimoTempoToqueContabilizado =
      MathMax(MathMax(keep.ultimoTempoToqueContabilizado, drop.ultimoTempoToqueContabilizado), tempoEvento);

   g_pivos[idxKeep].volumeBuy = volumeBuy;
   g_pivos[idxKeep].volumeSell = volumeSell;
   g_pivos[idxKeep].volumeTotal = volumeBuy + volumeSell;
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
   g_pivos[idxKeep].atr = (keep.atr + drop.atr) * 0.5;
   g_pivos[idxKeep].estado = PIVO_ATIVO;
   g_pivos[idxKeep].foiMergeada = true;

   g_pivos[idxKeep].ancoraSup = novoSup;
   g_pivos[idxKeep].ancoraInf = novoInf;
   g_pivos[idxKeep].ancoraPreco = g_pivos[idxKeep].preco;
   g_pivos[idxKeep].ancoraTempoInicio = g_pivos[idxKeep].tempoInicio;
   g_pivos[idxKeep].ancoraInicializada = true;
   g_pivos[idxKeep].cooldownMergeTicket = 0;

   string idIncorp = (drop.pivoID > 0) ? IntegerToString(drop.pivoID) : "";
   if(StringLen(idIncorp) > 0) {
      if(StringLen(g_pivos[idxKeep].pivosIncorporados) > 0)
         g_pivos[idxKeep].pivosIncorporados += "," + idIncorp;
      else
         g_pivos[idxKeep].pivosIncorporados = idIncorp;
   }

   SDV4_MergeCooldownMarcarZona(idxKeep);
   LimparSlotPivo(idxDrop);
   return true;
}

bool SDV4_EliminarZonaMaisDistante(const double precoReferencia,
                                   const datetime tempoEvento) {
   int idxDrop = SDV4_SelecionarZonaMaisDistante(precoReferencia, tempoEvento, false);
   if(idxDrop < 0) idxDrop = SDV4_SelecionarZonaMaisDistante(precoReferencia, tempoEvento, true);
   if(idxDrop < 0) return false;

   LimparSlotPivo(idxDrop);
   return true;
}

bool OrganizarZonasNoInicioDoDia(const double precoReferencia, const datetime tempoEvento) {
   if(!g_pivosInicializados) return false;

   int ativos = ContarZonasAtivas();
   if(ativos < 2) return false;

   int gatilho = ObterGatilhoOrganizacaoZonas();
   int limiteDuro = ObterLimiteDuroOrganizacaoZonas();
   int alvoNormal = ObterAlvoNormalOrganizacaoZonas();
   int alvoSemGap = ObterAlvoSemGapOrganizacaoZonas();
   int maxAcoes = ObterMaxAcoesOrganizacaoPorBarra();

   bool houveMudanca = false;
   bool alternarModo = true;

   for(int acao = 0; acao < maxAcoes; acao++) {
      ativos = ContarZonasAtivas();
      if(ativos < 2) break;

      bool temGapElegivel = SDV4_ExisteParGapElegivel();
      bool acimaGatilho = (ativos > gatilho);
      bool acimaLimiteDuro = (ativos > limiteDuro);

      if(!temGapElegivel && !acimaGatilho && !acimaLimiteDuro) break;

      int idxKeep = -1;
      int idxDrop = -1;
      double gapEscolhido = DBL_MAX;
      bool mergeExecutado = false;

      if(temGapElegivel) {
         int idxDistante = SDV4_SelecionarZonaMaisDistante(precoReferencia, tempoEvento, false);
         bool priorizarDistante = (acimaLimiteDuro || alternarModo);
         if(SDV4_SelecionarParParaMerge(precoReferencia,
                                        tempoEvento,
                                        idxDistante,
                                        priorizarDistante,
                                        idxKeep,
                                        idxDrop,
                                        gapEscolhido)) {
            mergeExecutado = AbsorverZonaSemMoverAncora(idxKeep, idxDrop, tempoEvento);
            if(mergeExecutado && SDV4_RegrasLogDetalhadoAtivo()) {
               Print("ORGANIZACAO: MERGE idxKeep=", idxKeep,
                     " idxDrop=", idxDrop,
                     " gap=", DoubleToString(gapEscolhido, _Digits));
            }
         }
      }

      if(mergeExecutado) {
         houveMudanca = true;
         alternarModo = !alternarModo;
         continue;
      }

      // Sem gap elegível: reduzir mais distante até alvo sem-gap.
      int alvoReducao = temGapElegivel ? alvoNormal : alvoSemGap;
      if(ativos > limiteDuro) alvoReducao = MathMin(alvoReducao, limiteDuro);
      if(alvoReducao < 1) alvoReducao = 1;

      if(ativos > alvoReducao) {
         if(SDV4_EliminarZonaMaisDistante(precoReferencia, tempoEvento)) {
            houveMudanca = true;
            alternarModo = !alternarModo;
            if(SDV4_RegrasLogDetalhadoAtivo()) {
               Print("ORGANIZACAO: DROP zona mais distante | ativos=", ativos,
                     " alvo=", alvoReducao);
            }
            continue;
         }
      }

      break;
   }

   return houveMudanca;
}

#endif

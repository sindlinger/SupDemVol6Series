#ifndef SUPDEMVOL_MODULE_CRIACAO_CANDIDATA_V5_MQH
#define SUPDEMVOL_MODULE_CRIACAO_CANDIDATA_V5_MQH

#include "SupDemVol_ModuleCriacaoGatilho_v5.mqh"

struct SDV4_CriacaoCandidataContext {
   ENUM_LINE_TYPE tipo;
   double precoZona;
   double atrAtual;
   bool barraPicoVolumeDia;
   double scoreOrigem;
   int espessuraOrigem;
   double alturaZonaCand;
   double alturaMaximaZona;
   double alturaMinimaZona;
   double candSup;
   double candInf;
   double limiarMinCriacao;
   double limiarMergeProximo;
   double menorDistFaixa;
   int idxZonaPreferencial;
   double distZonaPreferencial;
   int idxZonaPreferencialEnriquecimento;
   int idxZonaSobreposicao;
};

void SDV4_CriacaoMontarCandidata(const SDV4_CriacaoEventoContext &evt,
                                 const datetime &time[],
                                 const double &open[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 SDV4_CriacaoCandidataContext &cand) {
   cand.tipo = evt.tipoAtualBarra;
   cand.precoZona = (cand.tipo == LINE_TOP) ? high[evt.idx0] : low[evt.idx0];
   cand.atrAtual = CalcularATR(evt.idx0, high, low, close);

   datetime diaAtual = (time[evt.idx0] - (time[evt.idx0] % 86400));
   double maxVolDia = 0.0;
   for(int i = evt.idx0; i >= 0; i--) {
      datetime diaI = (time[i] - (time[i] % 86400));
      if(diaI != diaAtual) break;
      if(VolumeBuffer[i] > maxVolDia) maxVolDia = VolumeBuffer[i];
   }
   cand.barraPicoVolumeDia = (maxVolDia > 0.0 && VolumeBuffer[evt.idx0] >= (maxVolDia - 1e-9));

   cand.scoreOrigem = CalcularScoreOrigemZona(evt.idx0, time, open, high, low, close);
   if(cand.barraPicoVolumeDia) cand.scoreOrigem = LimitarScoreUnitario(cand.scoreOrigem + 0.10);

   cand.espessuraOrigem = ConverterScoreEmEspessura(cand.scoreOrigem);
   int espessuraBase = ObterLarguraLinhasZona();
   if(cand.espessuraOrigem < espessuraBase) cand.espessuraOrigem = espessuraBase;
   if(cand.barraPicoVolumeDia) {
      int espessuraDestaque = espessuraBase + 2;
      if(cand.espessuraOrigem < espessuraDestaque) cand.espessuraOrigem = espessuraDestaque;
   }
   if(cand.espessuraOrigem > 10) cand.espessuraOrigem = 10;

   double fatorAlturaBase = SDV4_RegrasFatorAlturaBarraOrigem();
   double fatorAlturaMin = 0.0;
   double fatorAlturaMax = 0.0;
   ObterLimitesFatorAlturaBarraOrigem(fatorAlturaMin, fatorAlturaMax);
   if(fatorAlturaBase < fatorAlturaMin) fatorAlturaBase = fatorAlturaMin;
   if(fatorAlturaBase > fatorAlturaMax) fatorAlturaBase = fatorAlturaMax;

   double range = MathMax(high[evt.idx0] - low[evt.idx0], _Point);
   double sombraSup = high[evt.idx0] - MathMax(open[evt.idx0], close[evt.idx0]);
   double sombraInf = MathMin(open[evt.idx0], close[evt.idx0]) - low[evt.idx0];
   if(sombraSup < 0.0) sombraSup = 0.0;
   if(sombraInf < 0.0) sombraInf = 0.0;
   double corpo = MathAbs(close[evt.idx0] - open[evt.idx0]);
   double sombraDominante = (cand.tipo == LINE_BOTTOM) ? sombraInf : sombraSup;
   double scoreEstrutura = LimitarScoreUnitario(((sombraDominante / range) * 0.75) + ((corpo / range) * 0.25));
   double scoreAltura = LimitarScoreUnitario((cand.scoreOrigem * 0.70) + (scoreEstrutura * 0.30));
   double fatorAltura = MathMax(fatorAlturaBase, scoreAltura);
   if(fatorAltura < fatorAlturaMin) fatorAltura = fatorAlturaMin;
   if(fatorAltura > fatorAlturaMax) fatorAltura = fatorAlturaMax;

   double alturaBarraOrigem = MathAbs(high[evt.idx0] - low[evt.idx0]);
   cand.alturaZonaCand = alturaBarraOrigem * fatorAltura;
   double escalaReferenciaCriacao = ObterLimiarDistanciaATR(cand.atrAtual, 100.0);
   double alturaMinPorRelevancia = escalaReferenciaCriacao * (0.10 + (0.40 * scoreAltura));
   if(cand.barraPicoVolumeDia) alturaMinPorRelevancia *= 1.35;
   if(cand.alturaZonaCand < alturaMinPorRelevancia) cand.alturaZonaCand = alturaMinPorRelevancia;

   cand.alturaMaximaZona = ObterLimiarDistanciaATR(cand.atrAtual, SDV4_RegrasMaxATRPercent());
   if(cand.barraPicoVolumeDia) {
      double alturaMaxPico = ObterLimiarDistanciaATR(cand.atrAtual, SDV4_RegrasMaxATRPercent() * 2.0);
      if(alturaMaxPico > cand.alturaMaximaZona) cand.alturaMaximaZona = alturaMaxPico;
   }
   if(cand.alturaZonaCand > cand.alturaMaximaZona) cand.alturaZonaCand = cand.alturaMaximaZona;

   cand.alturaMinimaZona = ObterAlturaMinimaZonaPreco();
   if(cand.alturaZonaCand < cand.alturaMinimaZona) cand.alturaZonaCand = cand.alturaMinimaZona;

   cand.candSup = (cand.tipo == LINE_TOP) ? high[evt.idx0] : (low[evt.idx0] + cand.alturaZonaCand);
   cand.candInf = (cand.tipo == LINE_TOP) ? (high[evt.idx0] - cand.alturaZonaCand) : low[evt.idx0];

   cand.limiarMinCriacao = ObterLimiarDistanciaATR(cand.atrAtual, SDV4_RegrasDistanciaMinATR()) *
                           ObterFatorDistanciaMinCriacao();
   double distMinPorTamanhoMin = MathMax(cand.alturaMinimaZona, cand.alturaMinimaZona * 0.80);
   double distMinPorTamanhoMax = MathMax(distMinPorTamanhoMin, cand.alturaMaximaZona * 0.80);
   double distMinPorTamanhoCand = MathMax(distMinPorTamanhoMin, cand.alturaZonaCand * 0.80);
   if(distMinPorTamanhoCand > distMinPorTamanhoMax) distMinPorTamanhoCand = distMinPorTamanhoMax;
   if(cand.limiarMinCriacao < distMinPorTamanhoMin) cand.limiarMinCriacao = distMinPorTamanhoMin;
   if(cand.limiarMinCriacao > distMinPorTamanhoMax) cand.limiarMinCriacao = distMinPorTamanhoMax;
   if(cand.limiarMinCriacao < distMinPorTamanhoCand) cand.limiarMinCriacao = distMinPorTamanhoCand;

   cand.limiarMergeProximo = MathMax(cand.alturaMinimaZona * 0.35, cand.limiarMinCriacao * 0.45);
   double limiteMergePeloMax = MathMax(cand.alturaMinimaZona * 0.50, cand.alturaMaximaZona * 0.55);
   if(cand.limiarMergeProximo > limiteMergePeloMax) cand.limiarMergeProximo = limiteMergePeloMax;

   cand.menorDistFaixa = DBL_MAX;
   cand.idxZonaPreferencial = -1;
   cand.distZonaPreferencial = DBL_MAX;
   cand.idxZonaPreferencialEnriquecimento = -1;
   cand.idxZonaSobreposicao = -1;
}

void SDV4_CriacaoMapearDestinos(const SDV4_CriacaoEventoContext &evt,
                                const double &high[],
                                const double &low[],
                                SDV4_CriacaoCandidataContext &cand) {
   int idxZonaAli = -1;
   int idxZonaAliBarra = -1;
   int idxZonaAliBarraMesmoTipo = -1;
   int idxZonaMaisProxima = -1;
   int idxZonaMaisProximaMesmoTipo = -1;
   double menorDistFaixa = DBL_MAX;
   double menorDistFaixaMesmoTipo = DBL_MAX;
   double menorDistToque = DBL_MAX;
   double menorDistToqueBarra = DBL_MAX;
   double menorDistToqueBarraMesmoTipo = DBL_MAX;
   double menorDistDirecionalToqueBarra = DBL_MAX;
   double menorDistDirecionalToqueBarraMesmoTipo = DBL_MAX;
   double precoRefToqueBarra = (cand.tipo == LINE_BOTTOM) ? low[evt.idx0] : high[evt.idx0];

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      double supZonaI = MathMax(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
      double infZonaI = MathMin(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);

      double distFaixa = DistanciaEntreFaixas(cand.candSup, cand.candInf, supZonaI, infZonaI);
      if(distFaixa < menorDistFaixa) {
         menorDistFaixa = distFaixa;
         idxZonaMaisProxima = i;
      }
      if(g_pivos[i].tipo == cand.tipo && distFaixa < menorDistFaixaMesmoTipo) {
         menorDistFaixaMesmoTipo = distFaixa;
         idxZonaMaisProximaMesmoTipo = i;
      }

      if(BarraInterseccionaFaixa(cand.candSup, cand.candInf, supZonaI, infZonaI)) {
         double distToque = DistanciaEntreFaixas(cand.candSup, cand.candInf, supZonaI, infZonaI);
         if(distToque < menorDistToque) {
            menorDistToque = distToque;
            idxZonaAli = i;
         }
      }

      if(BarraInterseccionaFaixa(high[evt.idx0], low[evt.idx0], supZonaI, infZonaI)) {
         double distToqueBarra = DistanciaEntreFaixas(high[evt.idx0], low[evt.idx0], supZonaI, infZonaI);
         double distDirecionalToque = MathAbs(g_pivos[i].preco - precoRefToqueBarra);
         bool melhorToqueBarra = false;
         if(idxZonaAliBarra < 0 || distToqueBarra < menorDistToqueBarra - 1e-9) {
            melhorToqueBarra = true;
         } else if(MathAbs(distToqueBarra - menorDistToqueBarra) <= 1e-9) {
            bool tipoAtualPreferido = (g_pivos[i].tipo == cand.tipo);
            bool tipoMelhorPreferido = (idxZonaAliBarra >= 0 && g_pivos[idxZonaAliBarra].tipo == cand.tipo);
            if(tipoAtualPreferido && !tipoMelhorPreferido) {
               melhorToqueBarra = true;
            } else if(tipoAtualPreferido == tipoMelhorPreferido &&
                      distDirecionalToque < menorDistDirecionalToqueBarra - 1e-9) {
               melhorToqueBarra = true;
            }
         }
         if(melhorToqueBarra) {
            menorDistToqueBarra = distToqueBarra;
            menorDistDirecionalToqueBarra = distDirecionalToque;
            idxZonaAliBarra = i;
         }

         if(g_pivos[i].tipo == cand.tipo) {
            bool melhorToqueBarraMesmoTipo = false;
            if(idxZonaAliBarraMesmoTipo < 0 || distToqueBarra < menorDistToqueBarraMesmoTipo - 1e-9) {
               melhorToqueBarraMesmoTipo = true;
            } else if(MathAbs(distToqueBarra - menorDistToqueBarraMesmoTipo) <= 1e-9 &&
                      distDirecionalToque < menorDistDirecionalToqueBarraMesmoTipo - 1e-9) {
               melhorToqueBarraMesmoTipo = true;
            }
            if(melhorToqueBarraMesmoTipo) {
               menorDistToqueBarraMesmoTipo = distToqueBarra;
               menorDistDirecionalToqueBarraMesmoTipo = distDirecionalToque;
               idxZonaAliBarraMesmoTipo = i;
            }
         }
      }
   }

   cand.menorDistFaixa = menorDistFaixa;
   cand.idxZonaPreferencial = idxZonaMaisProxima;
   cand.distZonaPreferencial = menorDistFaixa;
   cand.idxZonaPreferencialEnriquecimento = idxZonaMaisProxima;

   if(idxZonaMaisProximaMesmoTipo >= 0) {
      cand.idxZonaPreferencial = idxZonaMaisProximaMesmoTipo;
      cand.distZonaPreferencial = menorDistFaixaMesmoTipo;
      cand.idxZonaPreferencialEnriquecimento = idxZonaMaisProximaMesmoTipo;
   }
   if(idxZonaAliBarraMesmoTipo >= 0) {
      cand.idxZonaPreferencialEnriquecimento = idxZonaAliBarraMesmoTipo;
   } else if(idxZonaAliBarra >= 0) {
      cand.idxZonaPreferencialEnriquecimento = idxZonaAliBarra;
   }
   if(idxZonaAli < 0 && idxZonaAliBarra >= 0) {
      idxZonaAli = idxZonaAliBarra;
   }

   cand.idxZonaSobreposicao = (idxZonaAliBarraMesmoTipo >= 0) ? idxZonaAliBarraMesmoTipo :
                              ((idxZonaAliBarra >= 0) ? idxZonaAliBarra : idxZonaAli);
}

#endif

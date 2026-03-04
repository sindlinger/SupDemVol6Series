#ifndef SUPDEMVOL_MODULE_CRIACAO_ALOCACAO_V5_MQH
#define SUPDEMVOL_MODULE_CRIACAO_ALOCACAO_V5_MQH

#include "SupDemVol_ModuleCriacaoCandidata_v5.mqh"

void SDV4_CriacaoExecutarAlocacaoPrincipal(const SDV4_CriacaoEventoContext &evt,
                                           const SDV4_CriacaoCandidataContext &cand,
                                           const datetime &time[],
                                           const double &close[],
                                           bool &deveRecalcular,
                                           bool &houveCriacaoNova,
                                           bool &mergeExecutadoNestaCriacao,
                                           int &idxZonaDestinoEvento,
   double &volumeAplicadoEvento) {
   if(!mergeExecutadoNestaCriacao) {
      int ativosAntes = ContarZonasAtivas();
      if(ativosAntes > ObterGatilhoOrganizacaoZonas() || ativosAntes >= ObterLimiteDuroOrganizacaoZonas()) {
         if(OrganizarZonasNoInicioDoDia(close[evt.idx0], time[evt.idx0])) {
            deveRecalcular = true;
         }
      }

      int idxLivre = -1;
      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) { idxLivre = i; break; }
      }

      if(idxLivre >= 0) {
         if(cand.menorDistFaixa > cand.limiarMinCriacao) {
            ENUM_VOLUME_INTENSIDADE intensidade = DeterminarIntensidadeVolume(evt.volumeAtualBarra, MathMax(MediaBuffer[evt.idx0], 1.0));
            if(cand.barraPicoVolumeDia) intensidade = VOLUME_EXTREMO;
            g_pivos[idxLivre].preco = cand.precoZona;
            g_pivos[idxLivre].precoSuperior = cand.candSup;
            g_pivos[idxLivre].precoInferior = cand.candInf;
            g_pivos[idxLivre].tempoInicio = time[evt.idx0];
            g_pivos[idxLivre].tempoMaisRecente = time[evt.idx0];
            g_pivos[idxLivre].volumeTotal = evt.volumeEventoCriacao;
            g_pivos[idxLivre].volumeBuy = (cand.tipo == LINE_BOTTOM) ? evt.volumeEventoCriacao : 0.0;
            g_pivos[idxLivre].volumeSell = (cand.tipo == LINE_TOP) ? evt.volumeEventoCriacao : 0.0;
            g_pivos[idxLivre].volumeDistribuicao = evt.volumeEventoCriacao;
            g_pivos[idxLivre].scoreOrigem = cand.scoreOrigem;
            g_pivos[idxLivre].espessuraZona = cand.espessuraOrigem;
            g_pivos[idxLivre].volumeMaximo = 0.0;
            g_pivos[idxLivre].percentualVolume = 0.0;
            g_pivos[idxLivre].percentualVolumeInterno = 0.0;
            g_pivos[idxLivre].quantidadeBarras = 1;
            g_pivos[idxLivre].quantidadeTopos = (cand.tipo == LINE_TOP) ? 1 : 0;
            g_pivos[idxLivre].quantidadeFundos = (cand.tipo == LINE_BOTTOM) ? 1 : 0;
            g_pivos[idxLivre].tipo = cand.tipo;
            g_pivos[idxLivre].tipoMajoritario = cand.tipo;
            g_pivos[idxLivre].estado = PIVO_ATIVO;
            g_pivos[idxLivre].corAtual = ObterCorZona(cand.tipo);
            g_pivos[idxLivre].atr = cand.atrAtual;
            g_pivos[idxLivre].barraInicio = evt.idx0;
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
            g_pivos[idxLivre].ultimoTempoToqueContabilizado = time[evt.idx0];
            DefinirAncoraPivo(idxLivre);

            idxZonaDestinoEvento = idxLivre;
            volumeAplicadoEvento = evt.volumeEventoCriacao;
            g_tempoUltimaCriacaoBarra = time[evt.idx0];
            g_pivosInicializados = true;
            houveCriacaoNova = true;
            deveRecalcular = true;
         } else {
            SDV4_TentarEnriquecimentoMinDistanciaCriacao(evt.idx0,
                                                         time,
                                                         cand.tipo,
                                                         evt.volumeEventoCriacao,
                                                         cand.candSup,
                                                         cand.candInf,
                                                         cand.idxZonaPreferencialEnriquecimento,
                                                         cand.distZonaPreferencial,
                                                         cand.limiarMinCriacao,
                                                         mergeExecutadoNestaCriacao,
                                                         idxZonaDestinoEvento,
                                                         volumeAplicadoEvento,
                                                         deveRecalcular);
         }
         g_tempoUltimaCriacaoBarra = time[evt.idx0];
      } else {
         bool organizouSemSlot = OrganizarZonasNoInicioDoDia(close[evt.idx0], time[evt.idx0]);
         if(organizouSemSlot) {
            deveRecalcular = true;
         }

         // Tenta novamente após organização.
         idxLivre = -1;
         for(int i = 0; i < g_numeroZonas; i++) {
            if(g_pivos[i].estado == PIVO_REMOVIDO) { idxLivre = i; break; }
         }

         if(idxLivre >= 0 && cand.menorDistFaixa > cand.limiarMinCriacao) {
            ENUM_VOLUME_INTENSIDADE intensidade = DeterminarIntensidadeVolume(evt.volumeAtualBarra, MathMax(MediaBuffer[evt.idx0], 1.0));
            if(cand.barraPicoVolumeDia) intensidade = VOLUME_EXTREMO;
            g_pivos[idxLivre].preco = cand.precoZona;
            g_pivos[idxLivre].precoSuperior = cand.candSup;
            g_pivos[idxLivre].precoInferior = cand.candInf;
            g_pivos[idxLivre].tempoInicio = time[evt.idx0];
            g_pivos[idxLivre].tempoMaisRecente = time[evt.idx0];
            g_pivos[idxLivre].volumeTotal = evt.volumeEventoCriacao;
            g_pivos[idxLivre].volumeBuy = (cand.tipo == LINE_BOTTOM) ? evt.volumeEventoCriacao : 0.0;
            g_pivos[idxLivre].volumeSell = (cand.tipo == LINE_TOP) ? evt.volumeEventoCriacao : 0.0;
            g_pivos[idxLivre].volumeDistribuicao = evt.volumeEventoCriacao;
            g_pivos[idxLivre].scoreOrigem = cand.scoreOrigem;
            g_pivos[idxLivre].espessuraZona = cand.espessuraOrigem;
            g_pivos[idxLivre].volumeMaximo = 0.0;
            g_pivos[idxLivre].percentualVolume = 0.0;
            g_pivos[idxLivre].percentualVolumeInterno = 0.0;
            g_pivos[idxLivre].quantidadeBarras = 1;
            g_pivos[idxLivre].quantidadeTopos = (cand.tipo == LINE_TOP) ? 1 : 0;
            g_pivos[idxLivre].quantidadeFundos = (cand.tipo == LINE_BOTTOM) ? 1 : 0;
            g_pivos[idxLivre].tipo = cand.tipo;
            g_pivos[idxLivre].tipoMajoritario = cand.tipo;
            g_pivos[idxLivre].estado = PIVO_ATIVO;
            g_pivos[idxLivre].corAtual = ObterCorZona(cand.tipo);
            g_pivos[idxLivre].atr = cand.atrAtual;
            g_pivos[idxLivre].barraInicio = evt.idx0;
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
            g_pivos[idxLivre].ultimoTempoToqueContabilizado = time[evt.idx0];
            DefinirAncoraPivo(idxLivre);

            idxZonaDestinoEvento = idxLivre;
            volumeAplicadoEvento = evt.volumeEventoCriacao;
            g_tempoUltimaCriacaoBarra = time[evt.idx0];
            g_pivosInicializados = true;
            houveCriacaoNova = true;
            deveRecalcular = true;
         }

         if(InpLogDetalhado) {
            if(idxLivre >= 0) {
               Print("ORGANIZACAO[sem-slot]: liberou capacidade para nova zona.");
            } else {
               Print("ORGANIZACAO[sem-slot][SKIP]: sem capacidade após organização.");
            }
         }
         g_tempoUltimaCriacaoBarra = time[evt.idx0];
      }
   } else {
      g_tempoUltimaCriacaoBarra = time[evt.idx0];
      g_pivosInicializados = true;
      deveRecalcular = true;
   }
}

#endif

#ifndef SUPDEMVOL_MODULE_CRIACAO_V5_MQH
#define SUPDEMVOL_MODULE_CRIACAO_V5_MQH

#include "SupDemVol_ModuleCriacaoGatilho_v5.mqh"
#include "SupDemVol_ModuleCriacaoCandidata_v5.mqh"
#include "SupDemVol_ModuleCriacaoAlocacao_v5.mqh"

void SDV4_ModuloCriacaoProcessar(const int rates_total,
                                 const bool barraNova,
                                 const datetime &time[],
                                 const double &open[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 const long &tick_volume[],
                                 bool &deveRecalcular,
                                 bool &houveCriacaoNova) {
   if(rates_total < 1) return;
   datetime tempoEvento = time[rates_total - 1];
   if(!SDV4_RegrasPermitirEntradaModulo(SDV4_EXEC_MOD_CRIACAO, tempoEvento, "MOD-CRIACAO")) return;

   // Criacao: barra 0 (aberta), com enriquecimento incremental em tempo real ate o fechamento.
   SDV4_CriacaoEventoContext evt;
   if(!SDV4_CriacaoPrepararEvento(rates_total,
                                  time,
                                  tick_volume,
                                  open,
                                  high,
                                  low,
                                  close,
                                  evt)) return;

   // Enriquecimento intrabar da barra criadora (se já existe destino na barra 0 atual).
   if(SDV4_TentarEnriquecimentoRealtimeDaCriacao(evt.idx0,
                                                 time,
                                                 open,
                                                 high,
                                                 low,
                                                 close,
                                                 evt.tipoAtualBarra,
                                                 evt.volumeEventoCriacao,
                                                 evt.modoMixSombra,
                                                 evt.fracaoCompraSombra,
                                                 evt.fracaoVendaSombra,
                                                 deveRecalcular)) return;

   if(!evt.gatilho) return;

   SDV4_CriacaoCandidataContext cand;
   SDV4_CriacaoMontarCandidata(evt, time, open, high, low, close, cand);
   SDV4_CriacaoMapearDestinos(evt, high, low, cand);

   bool mergeExecutadoNestaCriacao = false;
   int idxZonaDestinoEvento = -1;
   double volumeAplicadoEvento = 0.0;
   bool podeMergeEvento = PodeProcessarMergeDoEvento(time[evt.idx0]);

   SDV4_TentarEnriquecimentoLocalCriacaoBloqueada(evt.idx0,
                                                  time,
                                                  high,
                                                  low,
                                                  cand.tipo,
                                                  evt.modoMixSombra,
                                                  evt.fracaoCompraSombra,
                                                  evt.fracaoVendaSombra,
                                                  evt.volumeEventoCriacao,
                                                  cand.candSup,
                                                  cand.candInf,
                                                  cand.alturaZonaCand,
                                                  cand.limiarMinCriacao,
                                                  cand.idxZonaSobreposicao,
                                                  cand.idxZonaPreferencialEnriquecimento,
                                                  cand.idxZonaPreferencial,
                                                  cand.distZonaPreferencial,
                                                  mergeExecutadoNestaCriacao,
                                                  podeMergeEvento,
                                                  idxZonaDestinoEvento,
                                                  volumeAplicadoEvento);

   SDV4_TentarEnriquecimentoCriacaoProxima(evt.idx0,
                                           time,
                                           cand.tipo,
                                           evt.volumeEventoCriacao,
                                           cand.candSup,
                                           cand.candInf,
                                           cand.idxZonaPreferencial,
                                           cand.distZonaPreferencial,
                                           cand.limiarMergeProximo,
                                           mergeExecutadoNestaCriacao,
                                           podeMergeEvento,
                                           idxZonaDestinoEvento,
                                           volumeAplicadoEvento);

   SDV4_CriacaoExecutarAlocacaoPrincipal(evt,
                                         cand,
                                         time,
                                         deveRecalcular,
                                         houveCriacaoNova,
                                         mergeExecutadoNestaCriacao,
                                         idxZonaDestinoEvento,
                                         volumeAplicadoEvento);

   if(volumeAplicadoEvento > 1e-9 &&
      idxZonaDestinoEvento >= 0 &&
      idxZonaDestinoEvento < g_numeroZonas &&
      g_pivos[idxZonaDestinoEvento].estado != PIVO_REMOVIDO) {
      g_idxZonaDestinoCriacaoRealtime = idxZonaDestinoEvento;
      g_volumeCriacaoAplicadoBarra += volumeAplicadoEvento;
      if(g_volumeCriacaoAplicadoBarra > evt.volumeAtualBarra) g_volumeCriacaoAplicadoBarra = evt.volumeAtualBarra;
      g_tempoEventoVolumeConsumidoCriacao = time[evt.idx0];
   }
}

#endif
